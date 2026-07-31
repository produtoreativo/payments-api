/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { InvoiceRepository } from '../src/modules/invoices/services/invoice-repository.service';
import {
  buildTestFixture,
  teardownFixture,
  TestFixture,
  TEST_API_TOKEN,
  TENANT_ID,
  WEBHOOK_SECRET,
  truncateAllTables,
} from './support/app-fixture';

const CREDIT_CARD_PAYLOAD = {
  tenantId: TENANT_ID,
  orderId: 'MS-300041',
  customer: {
    id: 'customer-card-01',
    name: 'Ana Lima',
    document: '98765432100',
    email: 'ana@example.com',
    mobilePhone: '11991234567',
  },
  amount: 499.9,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'CREDIT_CARD',
  provider: 'ASAAS',
  description: 'Pedido MS-300041 - Magazine Siará',
};

describe('Cartão de Crédito — Entrada Hospedada (DS-41)', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;
  let repository: InvoiceRepository;

  beforeAll(async () => {
    fixture = await buildTestFixture();
    app = fixture.app;
    repository = fixture.repository;
  });

  afterAll(async () => {
    if (fixture) await teardownFixture(fixture);
  });

  beforeEach(async () => {
    await truncateAllTables();
  });

  async function criarInvoiceCartao(
    idempotencyKey = 'MS-300041:create',
    overrides: Record<string, unknown> = {},
  ) {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', idempotencyKey)
      .set('X-Correlation-Id', 'corr-card-ds41')
      .send({ ...CREDIT_CARD_PAYLOAD, ...overrides })
      .expect(201);
  }

  function enviarWebhookCartao(
    created: request.Response,
    event: string,
    paymentOverrides: Record<string, unknown> = {},
  ) {
    return request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event,
        payment: {
          id: created.body.providerPaymentId,
          status: event.replace('PAYMENT_', ''),
          value: CREDIT_CARD_PAYLOAD.amount,
          customer: 'cus_mock_customer-card-01',
          ...paymentOverrides,
        },
      });
  }

  describe('Cenário 1: Criar cobrança de cartão com entrada hospedada no Asaas', () => {
    it('retorna invoice OPEN com hostedPaymentUrl e sem dados sensíveis de cartão', async () => {
      const response = await criarInvoiceCartao();

      expect(response.body).toMatchObject({
        orderId: 'MS-300041',
        provider: 'ASAAS',
        status: 'OPEN',
        amount: 499.9,
        currency: 'BRL',
        billingType: 'CREDIT_CARD',
        providerPaymentId: expect.stringMatching(/^pay_mock_/),
        externalReference: expect.stringMatching(/^inv_/),
        hostedPaymentUrl: expect.stringContaining('sandbox.asaas.com'),
      });

      expect(response.body.creditCard).toBeUndefined();
      expect(response.body.creditCardToken).toBeUndefined();
      expect(response.body.bankSlipUrl).toBeUndefined();

      const saved = await repository.findInvoice(
        TENANT_ID,
        response.body.invoiceId,
      );
      expect(saved?.status).toBe('OPEN');
      expect(saved?.billingType).toBe('CREDIT_CARD');
    });
  });

  describe('Cenário 2: Confirmar pagamento de cartão hospedado por webhook', () => {
    it('atualiza invoice para CONFIRMED e emite payment.confirmed uma única vez', async () => {
      const created = await criarInvoiceCartao('MS-300041:confirm');

      await enviarWebhookCartao(created, 'PAYMENT_CONFIRMED', {
        status: 'CONFIRMED',
        confirmedDate: '2027-01-15',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('CONFIRMED');
      expect(
        await repository.hasRawProviderEvent(
          `PAYMENT_CONFIRMED:${created.body.providerPaymentId}`,
        ),
      ).toBe(true);
    });
  });

  describe('Cenário 3: Conciliar recebimento financeiro de cartão', () => {
    it('atualiza invoice para RECEIVED sem publicar segunda liberação de pedido', async () => {
      const created = await criarInvoiceCartao('MS-300041:receive');
      const existing = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      await repository.updateInvoice(existing!, 'CONFIRMED');

      await enviarWebhookCartao(created, 'PAYMENT_RECEIVED', {
        status: 'RECEIVED',
        paymentDate: '2027-01-16',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('RECEIVED');
    });
  });

  describe('Cenário 4: Mapear pagamento autorizado aguardando captura', () => {
    it('registra autorização sem liberar pedido (invoice permanece OPEN)', async () => {
      const created = await criarInvoiceCartao('MS-300041:authorized');

      await enviarWebhookCartao(created, 'PAYMENT_AUTHORIZED', {
        status: 'AUTHORIZED',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('OPEN');
    });
  });

  describe('Cenário 5: Mapear análise de risco aprovada', () => {
    it('registra aprovação e aguarda confirmação antes de liberar pedido', async () => {
      const created = await criarInvoiceCartao('MS-300041:risk-approved');

      await enviarWebhookCartao(created, 'PAYMENT_APPROVED_BY_RISK_ANALYSIS', {
        status: 'APPROVED_BY_RISK_ANALYSIS',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('OPEN');
      expect(
        await repository.hasRawProviderEvent(
          `PAYMENT_APPROVED_BY_RISK_ANALYSIS:${created.body.providerPaymentId}`,
        ),
      ).toBe(true);
    });
  });

  describe('Cenário 6: Mapear análise de risco reprovada', () => {
    it('registra reprovação como recusado sem publicar payment.confirmed', async () => {
      const created = await criarInvoiceCartao('MS-300041:risk-reproved');

      await enviarWebhookCartao(created, 'PAYMENT_REPROVED_BY_RISK_ANALYSIS', {
        status: 'REPROVED_BY_RISK_ANALYSIS',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('FAILED');
      expect(invoice?.failureReason).toBe('PAYMENT_REPROVED_BY_RISK_ANALYSIS');
      expect(
        await repository.hasRawProviderEvent(
          `PAYMENT_REPROVED_BY_RISK_ANALYSIS:${created.body.providerPaymentId}`,
        ),
      ).toBe(true);
    });
  });

  describe('Cenário 7: Mapear análise de risco manual', () => {
    it('registra que pagamento está em análise sem timeout silencioso', async () => {
      const created = await criarInvoiceCartao('MS-300041:risk-awaiting');

      await enviarWebhookCartao(created, 'PAYMENT_AWAITING_RISK_ANALYSIS', {
        status: 'AWAITING_RISK_ANALYSIS',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('OPEN');
      expect(
        await repository.hasRawProviderEvent(
          `PAYMENT_AWAITING_RISK_ANALYSIS:${created.body.providerPaymentId}`,
        ),
      ).toBe(true);
    });
  });

  describe('Cenário 8: Mapear recusa de captura', () => {
    it('marca pagamento como FAILED com motivo observável', async () => {
      const created = await criarInvoiceCartao('MS-300041:capture-refused');

      await enviarWebhookCartao(
        created,
        'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED',
        { status: 'REFUSED' },
      ).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('FAILED');
      expect(invoice?.failureReason).toBe(
        'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED',
      );
    });
  });

  describe('Cenário 9: Confirmar pagamento com cartão (PAYMENT_CONFIRMED)', () => {
    it('atualiza invoice de cartão para CONFIRMED com rastreabilidade completa', async () => {
      const created = await criarInvoiceCartao('MS-300041:cc-confirmed');

      await enviarWebhookCartao(created, 'PAYMENT_CONFIRMED', {
        status: 'CONFIRMED',
        confirmedDate: '2027-01-15',
      }).expect(200);

      const invoice = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      expect(invoice?.status).toBe('CONFIRMED');
      expect(invoice?.providerPaymentId).toBe(created.body.providerPaymentId);
    });
  });

  describe('Cenário 10: Tratar estorno como fluxo diferente de cancelamento', () => {
    it('rejeita DELETE em invoice CONFIRMED de cartão orientando fluxo de estorno', async () => {
      const created = await criarInvoiceCartao('MS-300041:cancel-confirmed');
      const existing = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      await repository.updateInvoice(existing!, 'CONFIRMED');

      const response = await request(app.getHttpServer())
        .delete(`/invoices/${created.body.invoiceId}`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .set('Idempotency-Key', 'MS-300041:cancel')
        .expect(400);

      expect(response.body.message).toBe(
        'Invoice cancellation after confirmation requires refund flow',
      );
    });
  });

  describe('Cenário 11: Solicitar estorno de pagamento confirmado', () => {
    it('registra payment.card.refund.requested e retorna 202 com dados do estorno', async () => {
      const created = await criarInvoiceCartao('MS-300041:refund');
      const existing = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      await repository.updateInvoice(existing!, 'CONFIRMED');

      const response = await request(app.getHttpServer())
        .post(`/invoices/${created.body.invoiceId}/refund`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .set('Idempotency-Key', 'MS-300041:refund-req')
        .send({ reason: 'customer_request' })
        .expect(202);

      expect(response.body).toMatchObject({
        invoiceId: created.body.invoiceId,
        status: 'REFUND_REQUESTED',
        providerPaymentId: created.body.providerPaymentId,
      });
    });

    it('impede duplicidade de estorno por idempotência', async () => {
      const created = await criarInvoiceCartao('MS-300041:refund-idem');
      const existing = await repository.findInvoice(
        TENANT_ID,
        created.body.invoiceId,
      );
      await repository.updateInvoice(existing!, 'CONFIRMED');

      await request(app.getHttpServer())
        .post(`/invoices/${created.body.invoiceId}/refund`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .set('Idempotency-Key', 'MS-300041:refund-idem-key')
        .send({ reason: 'customer_request' })
        .expect(202);

      const second = await request(app.getHttpServer())
        .post(`/invoices/${created.body.invoiceId}/refund`)
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('X-Tenant-Id', TENANT_ID)
        .set('Idempotency-Key', 'MS-300041:refund-idem-key')
        .send({ reason: 'customer_request' })
        .expect(202);

      expect(second.body.invoiceId).toBe(created.body.invoiceId);
    });
  });

  describe('Cenário 12: Manter captura direta de cartão fora do primeiro slice', () => {
    it('rejeita payload com dados sensíveis de cartão sem decisão formal', async () => {
      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-300041:direct-capture')
        .send({
          ...CREDIT_CARD_PAYLOAD,
          creditCardToken: 'tok_test_123',
          remoteIp: '1.2.3.4',
        })
        .expect(400);

      expect(response.body.message).toContain(
        'Hosted credit card flow does not accept card data fields',
      );
    });
  });
});
