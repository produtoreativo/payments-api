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

describe('Webhook Configuration', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;
  let tokenRepository: TokenRepository;
  let apiToken: string;
  let tokenId: string;

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
    const created = await tokenRepository.create('tenant-webhook-tests');
    apiToken = created.rawToken;
    tokenId = created.tokenId;
  });

  const WEBHOOK_URL = 'https://example.com/payments/webhook';
  const WEBHOOK_EVENTS = ['invoice.created', 'invoice.confirmed'];

  describe('POST /webhooks — registro', () => {
    it('registra webhook e retorna secret apenas na criacao', async () => {
      const res = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(201);

      expect(res.body).toMatchObject({
        webhookId: expect.stringMatching(/^wh_/),
        tokenId,
        url: WEBHOOK_URL,
        events: WEBHOOK_EVENTS,
        active: true,
        secret: expect.any(String),
      });
      expect((res.body.secret as string).length).toBe(64);
    });

    it('rejeita URL sem HTTPS fora de localhost', async () => {
      const res = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: 'http://external.com/hook', events: WEBHOOK_EVENTS })
        .expect(422);

      expect(res.body.message).toContain('HTTPS');
    });

    it('rejeita URL invalida', async () => {
      await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: 'not-a-url', events: WEBHOOK_EVENTS })
        .expect(422);
    });

    it('rejeita events vazio', async () => {
      const res = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: [] })
        .expect(422);

      expect(res.body.message).toContain('events');
    });

    it('aceita URL localhost com HTTP', async () => {
      await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({
          url: 'http://localhost:3000/hook',
          events: ['invoice.created'],
        })
        .expect(201);
    });

    it('rejeita sem autenticacao', async () => {
      await request(app.getHttpServer())
        .post('/webhooks')
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(401);
    });
  });

  describe('GET /webhooks — listagem', () => {
    it('lista webhooks do token sem expor secret', async () => {
      await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(201);

      const res = await request(app.getHttpServer())
        .get('/webhooks')
        .set('x-api-token', apiToken)
        .expect(200);

      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toMatchObject({ url: WEBHOOK_URL, active: true });
      expect(res.body[0]).not.toHaveProperty('secret');
    });

    it('token diferente nao ve webhooks de outro token', async () => {
      await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(201);

      const other = await tokenRepository.create('tenant-webhook-tests');

      const res = await request(app.getHttpServer())
        .get('/webhooks')
        .set('x-api-token', other.rawToken)
        .expect(200);

      expect(res.body).toHaveLength(0);
    });
  });

  describe('DELETE /webhooks/:id — remocao', () => {
    it('remove webhook com sucesso', async () => {
      const created = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(201);

      const res = await request(app.getHttpServer())
        .delete(`/webhooks/${created.body.webhookId}`)
        .set('x-api-token', apiToken)
        .expect(200);

      expect(res.body).toEqual({
        removed: true,
        webhookId: created.body.webhookId,
      });
    });

    it('retorna 404 para webhook de outro token', async () => {
      const created = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({ url: WEBHOOK_URL, events: WEBHOOK_EVENTS })
        .expect(201);

      const other = await tokenRepository.create('tenant-webhook-tests');

      await request(app.getHttpServer())
        .delete(`/webhooks/${created.body.webhookId}`)
        .set('x-api-token', other.rawToken)
        .expect(404);
    });

    it('retorna 404 para id inexistente', async () => {
      await request(app.getHttpServer())
        .delete('/webhooks/wh_nonexistent')
        .set('x-api-token', apiToken)
        .expect(404);
    });
  });
});
