/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import {
  buildTestFixture,
  teardownFixture,
  TestFixture,
  TEST_API_TOKEN,
  TENANT_ID,
  truncateAllTables,
} from './support/app-fixture';

const SPLIT_CUSTOMER = {
  id: 'customer-split-01',
  name: 'Ana Costa',
  document: '98765432100',
  email: 'ana@example.com',
  mobilePhone: '11999998888',
};

const BOLETO_DUE_DATE = '2027-12-31';

function buildSplitPaymentPayload(overrides: Record<string, unknown> = {}) {
  return {
    tenantId: TENANT_ID,
    orderId: 'MS-200001',
    totalAmount: 500.0,
    currency: 'BRL',
    pixAmount: 200.0,
    boletoAmount: 300.0,
    boletoDueDate: BOLETO_DUE_DATE,
    customer: SPLIT_CUSTOMER,
    ...overrides,
  };
}

describe('Split Payment — Pix + Boleto', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;

  beforeAll(async () => {
    fixture = await buildTestFixture();
    app = fixture.app;
  });

  afterAll(async () => {
    if (fixture) await teardownFixture(fixture);
  });

  beforeEach(async () => {
    await truncateAllTables();
  });

  // ---------------------------------------------------------------------------
  // CAMINHO FELIZ
  // ---------------------------------------------------------------------------

  describe('Criar Split Payment com sucesso', () => {
    it('cria split payment e retorna status PENDING_BOTH com invoiceIds válidos', async () => {
      const response = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split')
        .set('X-Correlation-Id', 'corr-split-create-01')
        .send(buildSplitPaymentPayload())
        .expect(201);

      expect(response.body).toMatchObject({
        splitPaymentId: expect.stringMatching(/^spl_/),
        orderId: 'MS-200001',
        status: 'PENDING_BOTH',
        totalAmount: 500.0,
        pix: {
          invoiceId: expect.stringMatching(/^pay_mock_/),
          amount: 200.0,
          status: 'PENDING',
        },
        boleto: {
          invoiceId: expect.stringMatching(/^pay_mock_/),
          amount: 300.0,
          dueDate: BOLETO_DUE_DATE,
          status: 'PENDING',
        },
        createdAt: expect.any(String),
      });

      expect(response.body.pix.invoiceId).not.toEqual(
        response.body.boleto.invoiceId,
      );
    });
  });

  describe('Pedido liberado após confirmação dos dois meios (Pix primeiro)', () => {
    it('confirma Pix → PIX_CONFIRMED, confirma Boleto → COMPLETED', async () => {
      const created = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:happy-pix-first')
        .send(buildSplitPaymentPayload())
        .expect(201);

      const { splitPaymentId } = created.body;

      // Confirmar Pix
      const pixConfirmed = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/pix/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(pixConfirmed.body.status).toBe('PIX_CONFIRMED');
      expect(pixConfirmed.body.pix.status).toBe('CONFIRMED');

      // GET para verificar estado intermediário
      const getAfterPix = await request(app.getHttpServer())
        .get(`/split-payments/${splitPaymentId}`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .expect(200);

      expect(getAfterPix.body.status).toBe('PIX_CONFIRMED');

      // Confirmar Boleto
      const boletoConfirmed = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/boleto/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(boletoConfirmed.body.status).toBe('COMPLETED');
      expect(boletoConfirmed.body.boleto.status).toBe('CONFIRMED');
      expect(boletoConfirmed.body.completedAt).not.toBeNull();
    });
  });

  describe('Confirmação na ordem inversa — Boleto antes do Pix', () => {
    it('confirma Boleto → BOLETO_CONFIRMED, confirma Pix → COMPLETED', async () => {
      const created = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:happy-boleto-first')
        .send(buildSplitPaymentPayload({ orderId: 'MS-200002' }))
        .expect(201);

      const { splitPaymentId } = created.body;

      // Confirmar Boleto primeiro
      const boletoConfirmed = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/boleto/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(boletoConfirmed.body.status).toBe('BOLETO_CONFIRMED');
      expect(boletoConfirmed.body.boleto.status).toBe('CONFIRMED');

      // Pedido não deve ser liberado ainda
      const getAfterBoleto = await request(app.getHttpServer())
        .get(`/split-payments/${splitPaymentId}`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .expect(200);

      expect(getAfterBoleto.body.status).toBe('BOLETO_CONFIRMED');

      // Confirmar Pix
      const pixConfirmed = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/pix/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(pixConfirmed.body.status).toBe('COMPLETED');
      expect(pixConfirmed.body.completedAt).not.toBeNull();
    });
  });

  // ---------------------------------------------------------------------------
  // IDEMPOTÊNCIA
  // ---------------------------------------------------------------------------

  describe('Idempotência na criação', () => {
    it('retorna o mesmo splitPaymentId em retentativa com mesma chave', async () => {
      const first = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:idem')
        .send(buildSplitPaymentPayload())
        .expect(201);

      const second = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:idem')
        .send(buildSplitPaymentPayload())
        .expect(201);

      expect(second.body.splitPaymentId).toBe(first.body.splitPaymentId);
      expect(second.body.pix.invoiceId).toBe(first.body.pix.invoiceId);
      expect(second.body.boleto.invoiceId).toBe(first.body.boleto.invoiceId);
    });
  });

  describe('Webhook duplicado de confirmação do Pix', () => {
    it('segunda chamada do webhook de Pix não altera o status', async () => {
      const created = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:dup-pix')
        .send(buildSplitPaymentPayload({ orderId: 'MS-200003' }))
        .expect(201);

      const { splitPaymentId } = created.body;

      await request(app.getHttpServer())
        .post(`/webhooks/split-payment/pix/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      // Segunda chamada — não deve alterar status
      const secondPix = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/pix/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(secondPix.body.status).toBe('PIX_CONFIRMED');
    });
  });

  // ---------------------------------------------------------------------------
  // BOLETO VENCIDO
  // ---------------------------------------------------------------------------

  describe('Boleto vence com Pix já confirmado', () => {
    it('emite boleto.expired com pixStatus confirmed e muda para PENDING_INVESTIGATION', async () => {
      const created = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:expire-pix-confirmed')
        .send(buildSplitPaymentPayload({ orderId: 'MS-200004' }))
        .expect(201);

      const { splitPaymentId } = created.body;

      // Confirmar Pix
      await request(app.getHttpServer())
        .post(`/webhooks/split-payment/pix/${splitPaymentId}`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      // Expirar Boleto
      const expired = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/boleto/${splitPaymentId}/expire`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(expired.body.status).toBe('PENDING_INVESTIGATION');
      expect(expired.body.boleto.status).toBe('EXPIRED');
      // Pix permanece confirmado — não foi estornado
      expect(expired.body.pix.status).toBe('CONFIRMED');
      // completedAt não foi setado (pedido não foi liberado)
      expect(expired.body.completedAt).toBeNull();
    });
  });

  describe('Boleto vence sem nenhum pagamento realizado', () => {
    it('muda para PENDING_INVESTIGATION com pixStatus pending', async () => {
      const created = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200001:split:expire-no-payment')
        .send(buildSplitPaymentPayload({ orderId: 'MS-200005' }))
        .expect(201);

      const { splitPaymentId } = created.body;

      // Expirar Boleto sem nenhuma confirmação prévia
      const expired = await request(app.getHttpServer())
        .post(`/webhooks/split-payment/boleto/${splitPaymentId}/expire`)
        .set('X-Tenant-Id', TENANT_ID)
        .send({})
        .expect(200);

      expect(expired.body.status).toBe('PENDING_INVESTIGATION');
      expect(expired.body.boleto.status).toBe('EXPIRED');
      expect(expired.body.pix.status).toBe('PENDING');
    });
  });

  // ---------------------------------------------------------------------------
  // VALIDAÇÕES E FALHAS
  // ---------------------------------------------------------------------------

  describe('Rejeitar Split Payment com soma de valores incorreta', () => {
    it('retorna 400 quando pixAmount + boletoAmount != totalAmount', async () => {
      const response = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200002:split:invalid-sum')
        .send(
          buildSplitPaymentPayload({
            orderId: 'MS-200002',
            pixAmount: 200.0,
            boletoAmount: 200.0, // soma 400, mas totalAmount é 500
          }),
        )
        .expect(400);

      expect(response.body.message).toContain('pixAmount + boletoAmount');
    });
  });

  describe('Nenhum dado financeiro exposto em resposta de erro', () => {
    it('resposta de erro não contém valores de pagamento nem dados internos', async () => {
      const response = await request(app.getHttpServer())
        .post('/split-payments')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-200002:split:error-safe')
        .send(
          buildSplitPaymentPayload({
            orderId: 'MS-200002',
            pixAmount: 200.0,
            boletoAmount: 200.0,
          }),
        )
        .expect(400);

      // Resposta de erro deve conter apenas código de erro e mensagem genérica
      expect(response.body).not.toHaveProperty('pixAmount');
      expect(response.body).not.toHaveProperty('boletoAmount');
      expect(response.body).not.toHaveProperty('providerCustomerId');
      expect(response.body.statusCode).toBe(400);
      expect(response.body.message).toBeDefined();
    });
  });
});
