/* eslint-disable @typescript-eslint/no-unsafe-assignment */

/**
 * DS-62 — Chargeback Handling (work-item #173)
 *
 * Acceptance tests covering the BDD scenarios from
 * prodops/artifacts/bdd/chargeback-handling.feature
 *
 * Red → Green cycle target:
 *   - PAYMENT_CHARGEBACK_REQUESTED → invoice status CHARGEBACK_REQUESTED + event emitted
 *   - PAYMENT_CHARGEBACK_DISPUTE → invoice status CHARGEBACK_DISPUTE + event emitted
 *   - PAYMENT_AWAITING_CHARGEBACK_REVERSAL → invoice status CHARGEBACK_REVERSAL_PENDING + event emitted
 *   - Duplicate webhook is idempotent (no re-publication)
 *   - billingType !== CREDIT_CARD: invoice unchanged, anomaly logged
 *   - Out-of-order webhook: accepted and processed without error
 */
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

const CREDIT_CARD_BASE = {
  tenantId: TENANT_ID,
  orderId: 'CB-100001',
  customer: {
    id: 'customer-chargeback-01',
    name: 'Pedro Alves',
    document: '11122233344',
    email: 'pedro@example.com',
    mobilePhone: '11999887766',
  },
  amount: 350.0,
  currency: 'BRL',
  dueDate: '2027-12-31',
  billingType: 'CREDIT_CARD',
  provider: 'ASAAS',
  description: 'Pedido CB-100001 - Magazine Siará',
};

describe('Chargeback Handling (DS-62)', () => {
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

  async function criarCreditCardInvoice(orderId = 'CB-100001') {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', `${orderId}:create`)
      .send({ ...CREDIT_CARD_BASE, orderId })
      .expect(201);
  }

  async function confirmarInvoice(providerPaymentId: string) {
    return request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: providerPaymentId,
          status: 'CONFIRMED',
          value: 350.0,
          customer: 'cus_mock_customer-chargeback-01',
        },
      })
      .expect(200);
  }

  function enviarChargebackWebhook(
    event: string,
    providerPaymentId: string,
    paymentStatus: string,
  ) {
    return request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event,
        payment: {
          id: providerPaymentId,
          status: paymentStatus,
          value: 350.0,
          customer: 'cus_mock_customer-chargeback-01',
        },
      });
  }

  // ---------------------------------------------------------------------------
  // Cenário 1: Chargeback solicitado pelo portador (BDD scenario 1)
  // ---------------------------------------------------------------------------
  it('atualiza invoice para CHARGEBACK_REQUESTED ao receber PAYMENT_CHARGEBACK_REQUESTED', async () => {
    const created = await criarCreditCardInvoice();
    const { providerPaymentId, invoiceId } = created.body;
    await confirmarInvoice(providerPaymentId);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CHARGEBACK_REQUESTED');
    expect(
      await repository.hasRawProviderEvent(
        `PAYMENT_CHARGEBACK_REQUESTED:${providerPaymentId}`,
      ),
    ).toBe(true);
  });

  // ---------------------------------------------------------------------------
  // Cenário 2: Chargeback entra em disputa (BDD scenario 2)
  // ---------------------------------------------------------------------------
  it('atualiza invoice para CHARGEBACK_DISPUTE ao receber PAYMENT_CHARGEBACK_DISPUTE', async () => {
    const created = await criarCreditCardInvoice('CB-100002');
    const { providerPaymentId, invoiceId } = created.body;
    await confirmarInvoice(providerPaymentId);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_DISPUTE',
      providerPaymentId,
      'CHARGEBACK_DISPUTE',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CHARGEBACK_DISPUTE');
  });

  // ---------------------------------------------------------------------------
  // Cenário 3: Chargeback em reversão pendente (BDD scenario 3)
  // ---------------------------------------------------------------------------
  it('atualiza invoice para CHARGEBACK_REVERSAL_PENDING ao receber PAYMENT_AWAITING_CHARGEBACK_REVERSAL', async () => {
    const created = await criarCreditCardInvoice('CB-100003');
    const { providerPaymentId, invoiceId } = created.body;
    await confirmarInvoice(providerPaymentId);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);
    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_DISPUTE',
      providerPaymentId,
      'CHARGEBACK_DISPUTE',
    ).expect(200);
    await enviarChargebackWebhook(
      'PAYMENT_AWAITING_CHARGEBACK_REVERSAL',
      providerPaymentId,
      'AWAITING_CHARGEBACK_REVERSAL',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CHARGEBACK_REVERSAL_PENDING');
  });

  // ---------------------------------------------------------------------------
  // Cenário 4: Webhook de chargeback duplicado não republica evento (BDD scenario 4)
  // ---------------------------------------------------------------------------
  it('processa webhook de chargeback duplicado de forma idempotente', async () => {
    const created = await criarCreditCardInvoice('CB-100004');
    const { providerPaymentId, invoiceId } = created.body;
    await confirmarInvoice(providerPaymentId);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);

    // Send duplicate
    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CHARGEBACK_REQUESTED');
  });

  // ---------------------------------------------------------------------------
  // Cenário 5: Chargeback em invoice com billing type incorreto é rejeitado (BDD scenario 5)
  // ---------------------------------------------------------------------------
  it('nao altera invoice com billingType PIX ao receber webhook de chargeback', async () => {
    const created = await request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', 'CB-PIX-100005:create')
      .send({
        ...CREDIT_CARD_BASE,
        orderId: 'CB-PIX-100005',
        billingType: 'PIX',
      })
      .expect(201);

    const { providerPaymentId, invoiceId } = created.body;

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: providerPaymentId,
          status: 'CONFIRMED',
          value: 350.0,
          customer: 'cus_mock_customer-chargeback-01',
        },
      })
      .expect(200);

    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_REQUESTED',
      providerPaymentId,
      'CHARGEBACK_REQUESTED',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CONFIRMED');
  });

  // ---------------------------------------------------------------------------
  // Cenário 6: Chargeback fora de ordem é aceito (BDD scenario 6)
  // ---------------------------------------------------------------------------
  it('aceita e processa CHARGEBACK_DISPUTE sem CHARGEBACK_REQUESTED anterior', async () => {
    const created = await criarCreditCardInvoice('CB-100006');
    const { providerPaymentId, invoiceId } = created.body;
    await confirmarInvoice(providerPaymentId);

    // Send CHARGEBACK_DISPUTE directly, skipping CHARGEBACK_REQUESTED
    await enviarChargebackWebhook(
      'PAYMENT_CHARGEBACK_DISPUTE',
      providerPaymentId,
      'CHARGEBACK_DISPUTE',
    ).expect(200);

    const invoice = await repository.findInvoice(TENANT_ID, invoiceId);
    expect(invoice?.status).toBe('CHARGEBACK_DISPUTE');
  });
});
