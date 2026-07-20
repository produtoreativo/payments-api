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

const BASE_PAYLOAD = {
  tenantId: TENANT_ID,
  orderId: 'MS-200045',
  customer: {
    id: 'customer-200',
    name: 'Joao Silva',
    document: '12345678909',
    email: 'joao@example.com',
    mobilePhone: '11987654321',
  },
  amount: 219.9,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'PIX',
  provider: 'ASAAS',
  description: 'Pedido MS-200045',
};

describe('Confirmar Pagamento via Webhook', () => {
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

  async function criarInvoice(
    idempotencyKey = 'MS-200045:create',
    payload = BASE_PAYLOAD,
  ) {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', idempotencyKey)
      .send(payload)
      .expect(201);
  }

  async function enviarWebhook(
    event: string,
    paymentOverrides: Record<string, unknown> = {},
  ) {
    const created = await criarInvoice();
    const payment = {
      id: created.body.providerPaymentId,
      status: 'CONFIRMED',
      value: 219.9,
      customer: 'cus_mock_customer-200',
      ...paymentOverrides,
    };
    return {
      created,
      webhookResponse: await request(app.getHttpServer())
        .post('/webhook/payments')
        .set('asaas-access-token', WEBHOOK_SECRET)
        .send({ event, payment }),
    };
  }

  it('confirma pagamento ao receber PAYMENT_CONFIRMED autenticado', async () => {
    const { created } = await enviarWebhook('PAYMENT_CONFIRMED');

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

  it('registra PAYMENT_RECEIVED sem liberar pedido novamente apos ja confirmado', async () => {
    const created = await criarInvoice();
    const existing = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    await repository.updateInvoice(existing!, 'CONFIRMED');

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_RECEIVED',
        payment: {
          id: created.body.providerPaymentId,
          status: 'RECEIVED',
          value: 219.9,
          customer: 'cus_mock_customer-200',
          paymentDate: '2027-01-02',
        },
      })
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('RECEIVED');
  });

  it('rejeita webhook com token invalido sem alterar estado da invoice', async () => {
    const created = await criarInvoice();

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', 'token-errado')
      .send({
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: created.body.providerPaymentId,
          status: 'CONFIRMED',
          value: 219.9,
          customer: 'cus_mock_customer-200',
        },
      })
      .expect(401);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('OPEN');
    expect(
      await repository.hasRawProviderEvent(
        `PAYMENT_CONFIRMED:${created.body.providerPaymentId}`,
      ),
    ).toBe(false);
  });

  it('processa PAYMENT_CONFIRMED duplicado de forma idempotente', async () => {
    const created = await criarInvoice();
    const webhook = {
      event: 'PAYMENT_CONFIRMED',
      payment: {
        id: created.body.providerPaymentId,
        status: 'CONFIRMED',
        value: 219.9,
        customer: 'cus_mock_customer-200',
      },
    };

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send(webhook)
      .expect(200);
    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send(webhook)
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('CONFIRMED');
  });

  it('correlaciona confirmacao por externalReference quando providerPaymentId ainda nao foi consolidado', async () => {
    const created = await criarInvoice();
    const existing = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    await repository.updateInvoice(existing!, 'OPEN', {
      providerPaymentId: undefined,
    });

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: 'pay_asaas_early_correlation',
          status: 'CONFIRMED',
          value: 219.9,
          customer: 'cus_mock_customer-200',
          externalReference: created.body.invoiceId,
        },
      })
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('CONFIRMED');
    expect(invoice?.providerPaymentId).toBe('pay_asaas_early_correlation');
  });

  it('registra PAYMENT_OVERDUE sem alterar status da invoice', async () => {
    const created = await criarInvoice();

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_OVERDUE',
        payment: {
          id: created.body.providerPaymentId,
          status: 'OVERDUE',
          value: 219.9,
          customer: 'cus_mock_customer-200',
        },
      })
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('OPEN');
    expect(
      await repository.hasRawProviderEvent(
        `PAYMENT_OVERDUE:${created.body.providerPaymentId}`,
      ),
    ).toBe(true);
  });

  it('registra PAYMENT_AUTHORIZED de cartao sem liberar pedido', async () => {
    const created = await criarInvoice('MS-200045:credit-card', {
      ...BASE_PAYLOAD,
      billingType: 'CREDIT_CARD',
    });

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_AUTHORIZED',
        payment: {
          id: created.body.providerPaymentId,
          status: 'AUTHORIZED',
          value: 219.9,
          customer: 'cus_mock_customer-200',
        },
      })
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('OPEN');
  });

  it('marca invoice como FAILED quando captura de cartao e recusada', async () => {
    const created = await criarInvoice('MS-200045:credit-card-refused', {
      ...BASE_PAYLOAD,
      billingType: 'CREDIT_CARD',
    });

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED',
        payment: {
          id: created.body.providerPaymentId,
          status: 'REFUSED',
          value: 219.9,
          customer: 'cus_mock_customer-200',
        },
      })
      .expect(200);

    const invoice = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(invoice?.status).toBe('FAILED');
    expect(invoice?.failureReason).toBe('PAYMENT_CREDIT_CARD_CAPTURE_REFUSED');
  });

  it('aceita webhook de pagamento nao correlacionado sem erros', async () => {
    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: 'pay_desconhecido',
          status: 'CONFIRMED',
          value: 219.9,
          customer: 'cus_desconhecido',
        },
      })
      .expect(200);
  });
});
