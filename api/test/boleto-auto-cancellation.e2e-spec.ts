/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument */

/**
 * E2E tests for DS-63 Boleto Auto-Cancellation
 *
 * BDD feature: prodops/artifacts/bdd/boleto-auto-cancellation.feature
 * OBC:         prodops/artifacts/obcs/boleto-auto-cancellation.md
 */
import { createServer, IncomingMessage } from 'node:http';
import { INestApplication } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import request from 'supertest';
import { App } from 'supertest/types';
import { TokenRepository } from '../src/modules/auth/token.repository';
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

  describe('Evento e webhook de boleto cancelado (BS-006)', () => {
    interface Delivery {
      body: Record<string, any>;
      headers: IncomingMessage['headers'];
    }

    async function startConsumer(status = 200, delayMs = 0) {
      const deliveries: Delivery[] = [];
      const server = createServer((req, res) => {
        const chunks: Buffer[] = [];
        req.on('data', (c: Buffer) => chunks.push(c));
        req.on('end', () => {
          deliveries.push({
            body: JSON.parse(Buffer.concat(chunks).toString()),
            headers: req.headers,
          });
          setTimeout(() => {
            res.writeHead(status);
            res.end('{}');
          }, delayMs);
        });
      });
      await new Promise<void>((r) => server.listen(0, '127.0.0.1', r));
      const { port } = server.address() as { port: number };
      return {
        url: `http://127.0.0.1:${port}/hook`,
        deliveries,
        close: () => new Promise<void>((r) => server.close(() => r())),
      };
    }

    async function setup(events: string[], consumer: { url: string }) {
      const token = await app.get(TokenRepository).create('tenant-bs006');
      await request(app.getHttpServer())
        .post('/webhooks')
        .set('X-Api-Token', token.rawToken)
        .send({ url: consumer.url, events })
        .expect(201);
      const created = await request(app.getHttpServer())
        .post('/invoices')
        .set('X-Api-Token', token.rawToken)
        .set('Idempotency-Key', 'MS-BS006:create')
        .send(boletoPayload({ tenantId: 'tenant-bs006', orderId: 'MS-BS006' }))
        .expect(201);
      return created.body as { invoiceId: string; providerPaymentId: string };
    }

    it('publica payments.invoice.expired ao expirar o boleto', async () => {
      const created = await criarBoleto();
      const emitted: Array<Record<string, unknown>> = [];
      app
        .get(EventEmitter2)
        .on('payments.invoice.expired', (e: Record<string, unknown>) =>
          emitted.push(e),
        );

      await enviarWebhookPaymentOverdue(created.body.providerPaymentId);

      expect(emitted).toHaveLength(1);
      expect(emitted[0]).toMatchObject({
        invoiceId: created.body.invoiceId,
        orderId: 'MS-300063',
        tenantId: TENANT_ID,
        provider: 'ASAAS',
        providerPaymentId: created.body.providerPaymentId,
        billingType: 'BOLETO',
      });
      expect(typeof emitted[0].expiredAt).toBe('string');
      expect(typeof emitted[0].dueDate).toBe('string');
    });

    it('entrega invoice.cancelled (EXPIRED / BOLETO_OVERDUE) assinado ao consumidor inscrito, antes de responder ao PSP', async () => {
      const consumer = await startConsumer(200, 300);
      try {
        const { invoiceId, providerPaymentId } = await setup(
          ['invoice.cancelled'],
          consumer,
        );

        await enviarWebhookPaymentOverdue(providerPaymentId).then((r) =>
          expect(r.status).toBe(200),
        );

        // a entrega é aguardada: já concluída quando o PSP recebe a resposta
        expect(consumer.deliveries).toHaveLength(1);
        const [{ body, headers }] = consumer.deliveries;
        expect(body.event).toBe('invoice.cancelled');
        expect(body.payload).toMatchObject({
          invoiceId,
          orderId: 'MS-BS006',
          status: 'EXPIRED',
          reason: 'BOLETO_OVERDUE',
          billingType: 'BOLETO',
          currency: 'BRL',
        });
        expect(typeof body.payload.cancelledAt).toBe('string');
        expect(headers['x-payments-signature']).toMatch(
          /^sha256=[0-9a-f]{64}$/,
        );
        expect(headers['x-payments-delivery-id']).toBeDefined();
      } finally {
        await consumer.close();
      }
    });

    it('consumidor não inscrito em invoice.cancelled não recebe o webhook', async () => {
      const consumer = await startConsumer();
      try {
        const { invoiceId, providerPaymentId } = await setup(
          ['invoice.confirmed'],
          consumer,
        );
        await enviarWebhookPaymentOverdue(providerPaymentId);

        expect(
          (await repository.findInvoice('tenant-bs006', invoiceId))?.status,
        ).toBe('EXPIRED');
        expect(consumer.deliveries).toHaveLength(0);
      } finally {
        await consumer.close();
      }
    });

    it('falha na entrega não desfaz a expiração nem faz o PSP receber erro', async () => {
      const consumer = await startConsumer(500);
      try {
        const { invoiceId, providerPaymentId } = await setup(
          ['invoice.cancelled'],
          consumer,
        );
        const resp = await enviarWebhookPaymentOverdue(providerPaymentId);

        expect(resp.status).toBe(200);
        expect(consumer.deliveries).toHaveLength(1);
        expect(
          (await repository.findInvoice('tenant-bs006', invoiceId))?.status,
        ).toBe('EXPIRED');
      } finally {
        await consumer.close();
      }
    });

    it.each([
      ['duplicado', 'EXPIRED'],
      ['boleto confirmado', 'CONFIRMED'],
    ])(
      'PAYMENT_OVERDUE em invoice %s não publica evento nem entrega webhook',
      async (_label, status) => {
        const consumer = await startConsumer();
        try {
          const { invoiceId, providerPaymentId } = await setup(
            ['invoice.cancelled'],
            consumer,
          );
          const inv = await repository.findInvoice('tenant-bs006', invoiceId);
          await repository.updateInvoice(inv!, status as 'EXPIRED');
          const emitted: unknown[] = [];
          app
            .get(EventEmitter2)
            .on('payments.invoice.expired', (e: unknown) => emitted.push(e));

          await enviarWebhookPaymentOverdue(providerPaymentId);

          expect(emitted).toHaveLength(0);
          expect(consumer.deliveries).toHaveLength(0);
        } finally {
          await consumer.close();
        }
      },
    );

    it('PAYMENT_OVERDUE em invoice PIX não publica evento nem entrega webhook', async () => {
      const consumer = await startConsumer();
      try {
        await setup(['invoice.cancelled'], consumer);
        const token = await app.get(TokenRepository).create('tenant-bs006');
        const pix = await request(app.getHttpServer())
          .post('/invoices')
          .set('X-Api-Token', token.rawToken)
          .set('Idempotency-Key', 'MS-BS006:pix')
          .send(pixPayload({ tenantId: 'tenant-bs006' }))
          .expect(201);
        const emitted: unknown[] = [];
        app
          .get(EventEmitter2)
          .on('payments.invoice.expired', (e: unknown) => emitted.push(e));

        await enviarWebhookPaymentOverdue(pix.body.providerPaymentId);

        expect(emitted).toHaveLength(0);
        expect(consumer.deliveries).toHaveLength(0);
      } finally {
        await consumer.close();
      }
    });
  });
});
