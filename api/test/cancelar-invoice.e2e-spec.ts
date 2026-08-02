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
import { PIX_INVOICE_PAYLOAD } from './support/payloads';

describe('Cancelar Invoice', () => {
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

  async function criarInvoice(idempotencyKey = 'MS-100045:create') {
    return request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('Idempotency-Key', idempotencyKey)
      .send(PIX_INVOICE_PAYLOAD)
      .expect(201);
  }

  it('cancela invoice aberta com sucesso', async () => {
    const created = await criarInvoice();

    const response = await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('X-Tenant-Id', TENANT_ID)
      .set('Idempotency-Key', 'MS-100045:cancel')
      .expect(200);

    expect(response.body).toMatchObject({
      invoiceId: created.body.invoiceId,
      orderId: 'MS-100045',
      provider: 'ASAAS',
      providerPaymentId: created.body.providerPaymentId,
      status: 'CANCELLED',
    });
  });

  it('retorna o mesmo resultado em cancelamento repetido com mesma idempotencia', async () => {
    const created = await criarInvoice();

    const first = await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('X-Tenant-Id', TENANT_ID)
      .set('Idempotency-Key', 'MS-100045:cancel')
      .expect(200);

    const second = await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('X-Tenant-Id', TENANT_ID)
      .set('Idempotency-Key', 'MS-100045:cancel')
      .expect(200);

    expect(second.body).toEqual(first.body);
    expect(second.body.status).toBe('CANCELLED');
  });

  it('impede cancelamento apos pagamento confirmado', async () => {
    const created = await criarInvoice();

    const existing = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    await repository.updateInvoice(existing!, 'CONFIRMED');

    const response = await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('X-Tenant-Id', TENANT_ID)
      .set('Idempotency-Key', 'MS-100045:cancel')
      .expect(400);

    expect(response.body.message).toBe(
      'Invoice cancellation after confirmation requires refund flow',
    );
  });

  it('mantém invoice para investigação operacional quando provedor retorna 404', async () => {
    const created = await criarInvoice();

    const existing = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    await repository.updateInvoice(existing!, 'OPEN', {
      providerPaymentId: 'pay_mock_force404_test',
    });

    const response = await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('X-Api-Token', TEST_API_TOKEN)
      .set('X-Tenant-Id', TENANT_ID)
      .set('Idempotency-Key', 'MS-100045:cancel')
      .expect(409);

    expect(response.body.message).toBe(
      'Payment provider cancellation requires operational reconciliation',
    );

    const reconciled = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(reconciled?.status).toBe('CANCEL_RECONCILIATION_REQUIRED');
  });

  it('confirma cancelamento quando webhook PAYMENT_DELETED chega apos solicitacao', async () => {
    const created = await criarInvoice();

    const existing = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    await repository.updateInvoice(existing!, 'CANCEL_REQUESTED');

    await request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_DELETED',
        payment: {
          id: created.body.providerPaymentId,
          status: 'DELETED',
          value: 159.9,
          customer: 'cus_mock_customer-123',
        },
      })
      .expect(200);

    const cancelled = await repository.findInvoice(
      TENANT_ID,
      created.body.invoiceId,
    );
    expect(cancelled?.status).toBe('CANCELLED');

    expect(
      await repository.hasRawProviderEvent(
        `PAYMENT_DELETED:${created.body.providerPaymentId}`,
      ),
    ).toBe(true);
  });
});
