/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { TokenRepository } from '../src/modules/auth/token.repository';
import {
  buildTestFixture,
  teardownFixture,
  TestFixture,
  TEST_API_TOKEN,
  TENANT_ID,
  truncateAllTables,
} from './support/app-fixture';
import { PIX_INVOICE_PAYLOAD } from './support/payloads';

describe('Tenant Isolation', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;
  let tokenRepository: TokenRepository;

  beforeAll(async () => {
    fixture = await buildTestFixture();
    app = fixture.app;
    tokenRepository = app.get(TokenRepository);
  });

  afterAll(async () => {
    if (fixture) await teardownFixture(fixture);
  });

  beforeEach(async () => {
    await truncateAllTables();
  });

  it('tenant B nao consegue cancelar invoice do tenant A', async () => {
    const created = await request(app.getHttpServer())
      .post('/invoices')
      .set('x-api-token', TEST_API_TOKEN)
      .set('Idempotency-Key', 'isolation-create-001')
      .send(PIX_INVOICE_PAYLOAD)
      .expect(201);

    const tenantB = await tokenRepository.create('tenant-b-isolation');

    await request(app.getHttpServer())
      .delete(`/invoices/${created.body.invoiceId}`)
      .set('x-api-token', tenantB.rawToken)
      .set('X-Tenant-Id', 'tenant-b-isolation')
      .set('Idempotency-Key', 'isolation-cancel-001')
      .expect(404);
  });

  it('token de tenant B nao lista webhooks do tenant A', async () => {
    const tokenA = await tokenRepository.create(TENANT_ID);
    const tokenB = await tokenRepository.create('tenant-b-isolation');

    await request(app.getHttpServer())
      .post('/webhooks')
      .set('x-api-token', tokenA.rawToken)
      .send({ url: 'https://a.example.com/hook', events: ['invoice.created'] })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/webhooks')
      .set('x-api-token', tokenB.rawToken)
      .expect(200);

    expect(res.body).toHaveLength(0);
  });
});
