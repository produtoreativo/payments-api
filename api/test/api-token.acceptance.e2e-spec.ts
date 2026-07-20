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
  truncateAllTables,
} from './support/app-fixture';

const ADMIN_SECRET = 'test-admin-secret';
const TENANT_ID = 'tenant-token-tests';

describe('API Token Management (acceptance)', () => {
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

  describe('Admin token endpoints', () => {
    it('POST /admin/tokens — cria token com secret valido', async () => {
      const res = await request(app.getHttpServer())
        .post('/admin/tokens')
        .set('x-admin-secret', ADMIN_SECRET)
        .send({ tenantId: TENANT_ID })
        .expect(201);

      expect(res.body).toMatchObject({
        tokenId: expect.any(String),
        tenantId: TENANT_ID,
        rawToken: expect.any(String),
        createdAt: expect.any(String),
      });
      expect(res.body.rawToken).toHaveLength(64);
    });

    it('POST /admin/tokens — rejeita sem secret', async () => {
      await request(app.getHttpServer())
        .post('/admin/tokens')
        .send({ tenantId: TENANT_ID })
        .expect(403);
    });

    it('POST /admin/tokens — rejeita com secret errado', async () => {
      await request(app.getHttpServer())
        .post('/admin/tokens')
        .set('x-admin-secret', 'wrong-secret')
        .send({ tenantId: TENANT_ID })
        .expect(403);
    });

    it('GET /admin/tokens/:tenantId — lista tokens do tenant', async () => {
      await tokenRepository.create(TENANT_ID);
      await tokenRepository.create(TENANT_ID);

      const res = await request(app.getHttpServer())
        .get(`/admin/tokens/${TENANT_ID}`)
        .set('x-admin-secret', ADMIN_SECRET)
        .expect(200);

      expect(res.body).toMatchObject({
        tenantId: TENANT_ID,
        tokens: expect.arrayContaining([
          expect.objectContaining({ tenantId: TENANT_ID, revoked: false }),
        ]),
      });
      expect(res.body.tokens).toHaveLength(2);
    });

    it('DELETE /admin/tokens/:tenantId/:tokenId — revoga token', async () => {
      const { tokenId } = await tokenRepository.create(TENANT_ID);

      await request(app.getHttpServer())
        .delete(`/admin/tokens/${TENANT_ID}/${tokenId}`)
        .set('x-admin-secret', ADMIN_SECRET)
        .expect(204);

      const list = await tokenRepository.listByTenant(TENANT_ID);
      expect(list[0].revoked).toBe(true);
    });

    it('DELETE /admin/tokens/:tenantId/:tokenId — retorna 404 se nao existe', async () => {
      await request(app.getHttpServer())
        .delete(`/admin/tokens/${TENANT_ID}/nonexistent-id`)
        .set('x-admin-secret', ADMIN_SECRET)
        .expect(404);
    });
  });

  describe('Autenticacao via token DB', () => {
    const invoicePayload = {
      tenantId: TENANT_ID,
      orderId: 'ORDER-TOKEN-001',
      customer: {
        id: 'customer-token-test',
        name: 'João Token',
        document: '98765432100',
        email: 'joao@example.com',
        mobilePhone: '11912345678',
      },
      amount: 99.9,
      currency: 'BRL',
      dueDate: '2027-01-31',
      billingType: 'PIX',
      provider: 'ASAAS',
      description: 'Pedido TOKEN-001',
    };

    it('sem token retorna 401', async () => {
      await request(app.getHttpServer())
        .post('/invoices')
        .send(invoicePayload)
        .expect(401);
    });

    it('token invalido retorna 401', async () => {
      await request(app.getHttpServer())
        .post('/invoices')
        .set('x-api-token', 'not-a-real-token')
        .send(invoicePayload)
        .expect(401);
    });

    it('token valido retorna 201', async () => {
      const { rawToken } = await tokenRepository.create(TENANT_ID);

      await request(app.getHttpServer())
        .post('/invoices')
        .set('x-api-token', rawToken)
        .set('Idempotency-Key', 'token-valid-001')
        .send(invoicePayload)
        .expect(201);
    });

    it('token revogado retorna 401', async () => {
      const { rawToken, tokenId } = await tokenRepository.create(TENANT_ID);
      await tokenRepository.revoke(TENANT_ID, tokenId);

      await request(app.getHttpServer())
        .post('/invoices')
        .set('x-api-token', rawToken)
        .set('Idempotency-Key', 'token-revoked-001')
        .send(invoicePayload)
        .expect(401);
    });

    it('API_TOKEN_LOCAL aceito como escape hatch de dev', async () => {
      process.env.API_TOKEN_LOCAL = 'local-dev-escape-hatch';

      await request(app.getHttpServer())
        .post('/invoices')
        .set('x-api-token', 'local-dev-escape-hatch')
        .set('Idempotency-Key', 'local-dev-001')
        .send({
          ...invoicePayload,
          tenantId: 'local',
          orderId: 'LOCAL-DEV-001',
        })
        .expect(201);

      delete process.env.API_TOKEN_LOCAL;
    });
  });
});
