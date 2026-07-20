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
  truncateAllTables,
} from './support/app-fixture';
import { PIX_INVOICE_PAYLOAD } from './support/payloads';

describe('Criar Invoice', () => {
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
    process.env.ENABLED_PAYMENT_PROVIDERS = 'ASAAS';
    process.env.DEFAULT_PAYMENT_PROVIDER = 'ASAAS';
    process.env.ASAAS_MOCK = 'true';
    delete process.env.ASAAS_URL;
  });

  describe('Criação bem-sucedida', () => {
    it('cria invoice PIX com cliente ja vinculado ao Asaas', async () => {
      await repository.saveCustomerLink({
        tenantId: TENANT_ID,
        customerId: 'customer-123',
        provider: 'ASAAS',
        providerCustomerId: 'cus_asaas_123',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:create')
        .set('X-Correlation-Id', 'corr-create-linked')
        .send(PIX_INVOICE_PAYLOAD)
        .expect(201);

      expect(response.body).toMatchObject({
        orderId: 'MS-100045',
        provider: 'ASAAS',
        status: 'OPEN',
        amount: 159.9,
        currency: 'BRL',
        externalReference: expect.stringMatching(/^inv_/),
        providerPaymentId: expect.stringMatching(/^pay_mock_inv_/),
        paymentUrl: expect.stringMatching(
          /^https:\/\/sandbox\.asaas\.com\/i\/pay_mock_inv_/,
        ),
      });
      expect(response.body.invoiceId).toMatch(/^inv_/);
    });

    it('cria invoice de cartao hospedado', async () => {
      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:credit-card-hosted')
        .send({ ...PIX_INVOICE_PAYLOAD, billingType: 'CREDIT_CARD' })
        .expect(201);

      expect(response.body).toMatchObject({
        orderId: 'MS-100045',
        status: 'OPEN',
        providerPaymentId: expect.stringMatching(/^pay_mock_inv_/),
      });
    });

    it('cria cliente Asaas automaticamente quando nao ha vinculo previo', async () => {
      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:create')
        .send(PIX_INVOICE_PAYLOAD)
        .expect(201);

      expect(response.body).toMatchObject({
        status: 'OPEN',
        orderId: 'MS-100045',
        providerPaymentId: expect.stringMatching(/^pay_mock_inv_/),
      });

      const saved = await repository.findInvoice(
        TENANT_ID,
        response.body.invoiceId,
      );
      expect(saved?.status).toBe('OPEN');
      expect(saved?.providerPaymentId).toMatch(/^pay_mock_inv_/);
    });

    it('retorna a mesma invoice em retentativa com mesma chave de idempotencia', async () => {
      const first = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:create')
        .send(PIX_INVOICE_PAYLOAD)
        .expect(201);

      const second = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:create')
        .send(PIX_INVOICE_PAYLOAD)
        .expect(201);

      expect(second.body).toEqual(first.body);
    });
  });

  describe('Validação de payload', () => {
    it('rejeita payload de cartao tokenizado enquanto o fluxo e hospedado', async () => {
      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:tokenized')
        .send({
          ...PIX_INVOICE_PAYLOAD,
          billingType: 'CREDIT_CARD',
          creditCardToken: 'tok_xyz',
          remoteIp: '127.0.0.1',
        })
        .expect(400);

      expect(response.body.message).toContain(
        'Hosted credit card flow does not accept card data fields',
      );
    });

    it('rejeita provedor nao habilitado no ambiente', async () => {
      process.env.ENABLED_PAYMENT_PROVIDERS = 'ITAU';

      const response = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', TEST_API_TOKEN)
        .set('Idempotency-Key', 'MS-100045:create')
        .send(PIX_INVOICE_PAYLOAD)
        .expect(400);

      expect(response.body.message).toBe('Provider ASAAS is not enabled');
    });
  });
});
