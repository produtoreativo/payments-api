/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { createServer } from 'node:http';
import type {
  IncomingHttpHeaders,
  IncomingMessage,
  ServerResponse,
} from 'node:http';
import { createHmac } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { TokenRepository } from '../src/modules/auth/token.repository';
import { InvoiceRepository } from '../src/modules/invoices/services/invoice-repository.service';
import {
  buildTestFixture,
  teardownFixture,
  TestFixture,
  truncateAllTables,
  TEST_API_TOKEN,
  WEBHOOK_SECRET,
  TENANT_ID,
} from './support/app-fixture';

// ── Delivery test helpers (module scope to satisfy nesting/scope lint rules) ──

interface CapturedRequest {
  body: string;
  headers: IncomingHttpHeaders;
}

interface CapturingServer {
  port: number;
  requests: CapturedRequest[];
  close: () => Promise<void>;
}

function buildRequestHandler(
  requests: CapturedRequest[],
  responseStatus: number,
) {
  return (req: IncomingMessage, res: ServerResponse) => {
    const chunks: Buffer[] = [];
    req.on('data', (chunk: Buffer) => chunks.push(chunk));
    req.on('end', () => {
      const body = Buffer.concat(chunks).toString();
      requests.push({ body, headers: req.headers });
      res.writeHead(responseStatus, { 'Content-Type': 'application/json' });
      res.end('{}');
    });
  };
}

type HttpServer = ReturnType<typeof createServer>;

function makeCloser(server: HttpServer): () => Promise<void> {
  return () => new Promise<void>((r) => server.close(r));
}

function startCapturingServer(
  responseStatus: number,
): Promise<CapturingServer> {
  const requests: CapturedRequest[] = [];
  const handler = buildRequestHandler(requests, responseStatus);

  return new Promise((resolve) => {
    const server = createServer(handler);
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address() as { port: number };
      resolve({ port: addr.port, requests, close: makeCloser(server) });
    });
  });
}

async function waitForRequests(
  requests: CapturedRequest[],
  count = 1,
  timeoutMs = 6000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (requests.length >= count) return;
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error(
    `Expected ${count} delivery request(s) within ${timeoutMs}ms but got ${requests.length}`,
  );
}

// app is populated by beforeAll — accessible from module-scope helpers
let _app: INestApplication<App>;

async function createInvoiceAndConfirm(
  orderId: string,
  customerId: string,
): Promise<Record<string, unknown>> {
  const invoiceRes = await request(_app.getHttpServer())
    .post('/invoices')
    .set('X-Api-Token', TEST_API_TOKEN)
    .set('Idempotency-Key', `${orderId}:create`)
    .send({
      tenantId: TENANT_ID,
      orderId,
      customer: {
        id: customerId,
        name: 'Test Customer',
        document: '12345678909',
        email: 'test@test.com',
        mobilePhone: '11987654321',
      },
      amount: 100,
      currency: 'BRL',
      dueDate: '2027-12-31',
      billingType: 'PIX',
      provider: 'ASAAS',
      description: `Delivery test: ${orderId}`,
    })
    .expect(201);

  await request(_app.getHttpServer())
    .post('/webhook/payments')
    .set('asaas-access-token', WEBHOOK_SECRET)
    .send({
      event: 'PAYMENT_CONFIRMED',
      payment: {
        id: invoiceRes.body.providerPaymentId,
        status: 'CONFIRMED',
        value: 100,
        customer: `cus_mock_${customerId}`,
      },
    })
    .expect(200);

  return invoiceRes.body as Record<string, unknown>;
}

// ── Test suite ────────────────────────────────────────────────────────────────

describe('Webhook Configuration', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;
  let tokenRepository: TokenRepository;
  let apiToken: string;
  let tokenId: string;

  beforeAll(async () => {
    fixture = await buildTestFixture();
    app = fixture.app;
    _app = app;
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

  // BDD Scenario 7: Rejeitar registro quando token já possui 10 webhooks
  describe('Limite de webhooks por token', () => {
    it('rejeita registro quando token ja possui 10 webhooks ativos', async () => {
      for (let i = 0; i < 10; i++) {
        await request(app.getHttpServer())
          .post('/webhooks')
          .set('x-api-token', apiToken)
          .send({
            url: `https://example.com/hook/${i}`,
            events: WEBHOOK_EVENTS,
          })
          .expect(201);
      }

      const res = await request(app.getHttpServer())
        .post('/webhooks')
        .set('x-api-token', apiToken)
        .send({
          url: 'https://example.com/hook/overflow',
          events: WEBHOOK_EVENTS,
        })
        .expect(422);

      expect(res.body.message).toContain('10');
    });
  });

  // BDD Scenarios 8, 9, 10: Entrega de eventos (fire-and-forget)
  describe('Entrega de eventos (Webhook Delivery)', () => {
    let siararToken: string;
    let invoiceRepository: InvoiceRepository;

    beforeEach(async () => {
      const created = await tokenRepository.create(TENANT_ID);
      siararToken = created.rawToken;
      invoiceRepository = app.get(InvoiceRepository);
    });

    // BDD Scenario 8: Deliver event when payment is confirmed
    it('entrega evento ao webhook quando pagamento e confirmado', async () => {
      const server = await startCapturingServer(200);

      try {
        const regRes = await request(app.getHttpServer())
          .post('/webhooks')
          .set('x-api-token', siararToken)
          .send({
            url: `http://127.0.0.1:${server.port}/delivery`,
            events: ['invoice.confirmed'],
          })
          .expect(201);

        const webhookSecret = regRes.body.secret as string;

        const invoice = await createInvoiceAndConfirm(
          'MS-delivery-008',
          'cust-delivery-008',
        );

        await waitForRequests(server.requests, 1);

        const received = server.requests[0];
        const body = JSON.parse(received.body) as Record<string, unknown>;

        expect(body).toMatchObject({
          event: 'invoice.confirmed',
          tenantId: TENANT_ID,
          webhookId: regRes.body.webhookId,
        });
        expect(body).toHaveProperty('deliveryId');
        expect(body).toHaveProperty('payload');

        const expectedSig = `sha256=${createHmac('sha256', webhookSecret)
          .update(received.body)
          .digest('hex')}`;
        expect(received.headers['x-payments-signature']).toBe(expectedSig);
        expect(received.headers['x-payments-delivery-id']).toBe(
          body.deliveryId,
        );

        expect(invoice.invoiceId).toBeDefined();
      } finally {
        await server.close();
      }
    });

    // BDD Scenario 9: Record delivery failure without blocking payment flow
    it('registra falha de entrega sem bloquear fluxo de pagamento', async () => {
      const server = await startCapturingServer(500);

      try {
        await request(app.getHttpServer())
          .post('/webhooks')
          .set('x-api-token', siararToken)
          .send({
            url: `http://127.0.0.1:${server.port}/delivery`,
            events: ['invoice.confirmed'],
          })
          .expect(201);

        const invoice = await createInvoiceAndConfirm(
          'MS-delivery-009',
          'cust-delivery-009',
        );

        // Wait for the delivery attempt (server responds 500 but invoice flow must be unblocked)
        await waitForRequests(server.requests, 1);

        // Invoice must still be CONFIRMED despite the failed webhook delivery
        const persisted = await invoiceRepository.findInvoice(
          TENANT_ID,
          invoice.invoiceId as string,
        );
        expect(persisted?.status).toBe('CONFIRMED');
      } finally {
        await server.close();
      }
    });

    // BDD Scenario 10: Do not deliver event to inactive (removed) webhook
    it('nao entrega evento para webhook inativo (removido)', async () => {
      const server = await startCapturingServer(200);

      try {
        const regRes = await request(app.getHttpServer())
          .post('/webhooks')
          .set('x-api-token', siararToken)
          .send({
            url: `http://127.0.0.1:${server.port}/delivery`,
            events: ['invoice.confirmed'],
          })
          .expect(201);

        await request(app.getHttpServer())
          .delete(`/webhooks/${regRes.body.webhookId}`)
          .set('x-api-token', siararToken)
          .expect(200);

        await createInvoiceAndConfirm('MS-delivery-010', 'cust-delivery-010');

        // Wait long enough for any spurious delivery to have arrived
        await new Promise((r) => setTimeout(r, 2000));

        expect(server.requests).toHaveLength(0);
      } finally {
        await server.close();
      }
    });
  });
});
