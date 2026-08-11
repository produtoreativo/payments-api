/* eslint-disable @typescript-eslint/no-unsafe-assignment */

/**
 * E2E tests for DS-63 Boleto Auto-Cancellation
 *
 * BDD feature: prodops/artifacts/bdd/boleto-auto-cancellation.feature
 * OBC:         prodops/artifacts/obcs/boleto-auto-cancellation.md
 */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { InvoiceRepository } from '../src/modules/invoices/services/invoice-repository.service';
import {
  buildTestFixture,
  teardownFixture,
  TEST_API_TOKEN,
  TENANT_ID,
  WEBHOOK_SECRET,
  truncateAllTables,
  TestFixture,
} from './support/app-fixture';

const futureDate = (daysAhead = 3): string => {
  const date = new Date();
  date.setUTCHours(0, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() + daysAhead);
  return date.toISOString().slice(0, 10);
};

const boletoPayload = (overrides: Record<string, unknown> = {}) => ({
  tenantId: TENANT_ID,
  orderId: 'MS-300063',
  customer: {
    id: 'customer-boleto-63',
    name: 'Ana Costa',
    document: '98765432100',
    email: 'ana@example.com',
    mobilePhone: '11911112222',
  },
  amount: 199.9,
  currency: 'BRL',
  dueDate: futureDate(3),
  billingType: 'BOLETO',
  provider: 'ASAAS',
  description: 'Pedido MS-300063',
  ...overrides,
});

const pixPayload = (overrides: Record<string, unknown> = {}) => ({
  tenantId: TENANT_ID,
  orderId: 'MS-300064',
  customer: {
    id: 'customer-pix-64',
    name: 'Carlos Rocha',
    document: '11122233344',
    email: 'carlos@example.com',
    mobilePhone: '11933334444',
  },
  amount: 89.9,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'PIX',
  provider: 'ASAAS',
  description: 'Pedido MS-300064',
  ...overrides,
});

describe('Boleto Auto-Cancellation (DS-63)', () => {
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

  afterEach(() => {
    jest.restoreAllMocks();
  });

  async function criarBoleto(
    idempotencyKey = 'MS-300063:create-boleto',
    payload = boletoPayload(),
  ) {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', idempotencyKey)
      .send(payload)
      .expect(201);
  }

  async function criarPix(
    idempotencyKey = 'MS-300064:create-pix',
    payload = pixPayload(),
  ) {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', idempotencyKey)
      .send(payload)
      .expect(201);
  }

  async function enviarWebhookPaymentOverdue(providerPaymentId: string) {
    return request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_OVERDUE',
        payment: {
          id: providerPaymentId,
          status: 'OVERDUE',
        },
      });
  }

  describe('Cenário 1: Boleto vencido é automaticamente expirado', () => {
    it('transiciona boleto OPEN para EXPIRED ao receber PAYMENT_OVERDUE', async () => {
      const created = await criarBoleto();
      const { invoiceId, providerPaymentId } = created.body;

      const webhookResp = await enviarWebhookPaymentOverdue(providerPaymentId);
      expect(webhookResp.status).toBe(200);

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(invoice?.status).toBe('EXPIRED');
      expect(
        await repository.hasRawProviderEvent(
          `PAYMENT_OVERDUE:${providerPaymentId}`,
        ),
      ).toBe(true);
    });
  });

  describe('Cenário 2: Boleto criado com configuração de cancelamento automático', () => {
    it('inclui daysAfterDueDateToRegistrationCancellation=1 no payload persistido do PSP', async () => {
      const created = await criarBoleto();
      const { invoiceId } = created.body;

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      const providerPayload = invoice?.providerPayload as
        | Record<string, unknown>
        | undefined;

      expect(providerPayload?.daysAfterDueDateToRegistrationCancellation).toBe(
        1,
      );
      expect(providerPayload?.billingType).toBe('BOLETO');
    });
  });

  describe('Cenário 3: PAYMENT_OVERDUE duplicado é tratado de forma idempotente', () => {
    it('receber PAYMENT_OVERDUE duas vezes mantém status EXPIRED sem duplicação', async () => {
      const created = await criarBoleto();
      const { invoiceId, providerPaymentId } = created.body;

      await enviarWebhookPaymentOverdue(providerPaymentId);

      const afterFirst = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(afterFirst?.status).toBe('EXPIRED');

      // Mesmo evento (mesmo eventKey) — será no-op por idempotência de raw event
      await enviarWebhookPaymentOverdue(providerPaymentId);

      const afterSecond = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(afterSecond?.status).toBe('EXPIRED');
      expect(afterSecond?.updatedAt).toEqual(afterFirst?.updatedAt);
    });

    it('boleto já EXPIRED recebe novo PAYMENT_OVERDUE e permanece EXPIRED', async () => {
      const created = await criarBoleto('MS-300063:create-idempotent');
      const { invoiceId, providerPaymentId } = created.body;

      const existingInvoice = await repository.findInvoice(
        TENANT_ID,
        invoiceId,
      );
      await repository.updateInvoice(existingInvoice!, 'EXPIRED');

      // Novo event key (diferente do primeiro)
      await request(app.getHttpServer())
        .post('/webhook/payments')
        .set('asaas-access-token', WEBHOOK_SECRET)
        .send({
          event: 'PAYMENT_OVERDUE',
          payment: {
            id: providerPaymentId,
            status: 'OVERDUE',
            externalReference: 'retry-overdue-event',
          },
        })
        .expect(200);

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(invoice?.status).toBe('EXPIRED');
    });
  });

  describe('Cenário 4: Boleto confirmado não é expirado', () => {
    it('PAYMENT_OVERDUE em boleto CONFIRMED é ignorado', async () => {
      const created = await criarBoleto('MS-300063:create-confirmed');
      const { invoiceId, providerPaymentId } = created.body;

      const existingInvoice = await repository.findInvoice(
        TENANT_ID,
        invoiceId,
      );
      await repository.updateInvoice(existingInvoice!, 'CONFIRMED');

      const webhookResp = await enviarWebhookPaymentOverdue(providerPaymentId);
      expect(webhookResp.status).toBe(200);

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(invoice?.status).toBe('CONFIRMED');
    });
  });

  describe('Cenário 5: PAYMENT_OVERDUE para billingType incorreto é ignorado', () => {
    it('PAYMENT_OVERDUE para invoice PIX não altera status', async () => {
      const created = await criarPix();
      const { invoiceId, providerPaymentId } = created.body;

      const webhookResp = await enviarWebhookPaymentOverdue(providerPaymentId);
      expect(webhookResp.status).toBe(200);

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      expect(invoice?.status).toBe('OPEN');
    });
  });

  describe('Cenário 6: Valor padrão de daysAfterDueDateToRegistrationCancellation', () => {
    it('boleto sem configuração explícita usa valor padrão de 1 dia', async () => {
      const created = await criarBoleto();
      const { invoiceId } = created.body;

      const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
      const providerPayload = invoice?.providerPayload as
        | Record<string, unknown>
        | undefined;

      expect(providerPayload?.daysAfterDueDateToRegistrationCancellation).toBe(
        1,
      );
    });
  });
});
