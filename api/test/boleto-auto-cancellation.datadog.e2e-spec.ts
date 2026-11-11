/* eslint-disable @typescript-eslint/no-unsafe-assignment */

/**
 * Integração real com o Datadog para o autocancelamento de boleto (BS-006).
 *
 * SEM spies e SEM mocks: a aplicação emite as métricas de verdade pelo agente local (DogStatsD)
 * e o teste confirma, consultando a API do Datadog, que cada métrica chegou com a contagem exata.
 * Cada execução usa um `env` único (e2e-<id>, ver support/datadog-env.ts), então a contagem
 * não se mistura com dados reais.
 *
 * Pré-requisitos: agente em localhost:8126/8125 (container datadog-agent-local) e DD_API_KEY/DD_APP_KEY.
 * Rodar: npm run test:e2e:datadog   (a ingestão leva alguns minutos; o teste espera até 6 min)
 */
import { createServer } from 'node:http';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { TokenRepository } from '../src/modules/auth/token.repository';
import { InvoiceRepository } from '../src/modules/invoices/services/invoice-repository.service';
import { flushMetrics } from '../src/observability/metrics';
import {
  buildTestFixture,
  teardownFixture,
  TENANT_ID,
  TEST_API_TOKEN,
  TestFixture,
  truncateAllTables,
  WEBHOOK_SECRET,
} from './support/app-fixture';
import {
  assertDatadogReachable,
  sumMetric,
  waitUntil,
} from './support/datadog-api';

const due = (): string => {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + 3);
  return d.toISOString().slice(0, 10);
};

const payload = (over: Record<string, unknown>) => ({
  tenantId: TENANT_ID,
  orderId: 'MS-DD',
  customer: {
    id: 'customer-dd',
    name: 'Ana Costa',
    document: '98765432100',
    email: 'ana@example.com',
    mobilePhone: '11911112222',
  },
  amount: 199.9,
  currency: 'BRL',
  dueDate: due(),
  billingType: 'BOLETO',
  provider: 'ASAAS',
  description: 'Pedido MS-DD',
  ...over,
});

describe('Autocancelamento de boleto — métricas no Datadog (real)', () => {
  let fixture: TestFixture;
  let app: INestApplication<App>;
  let repository: InvoiceRepository;
  const servers: Array<() => Promise<void>> = [];
  const env = process.env.DD_ENV as string;

  beforeAll(async () => {
    await assertDatadogReachable();
    fixture = await buildTestFixture();
    app = fixture.app;
    repository = fixture.repository;
    await truncateAllTables();
  });

  afterAll(async () => {
    for (const close of servers) await close();
    if (fixture) await teardownFixture(fixture);
  });

  async function consumer(status: number) {
    const server = createServer((req, res) => {
      req.on('data', () => undefined);
      req.on('end', () => {
        res.writeHead(status);
        res.end('{}');
      });
    });
    await new Promise<void>((r) => server.listen(0, '127.0.0.1', r));
    servers.push(() => new Promise<void>((r) => server.close(() => r())));
    return `http://127.0.0.1:${(server.address() as { port: number }).port}/hook`;
  }

  async function tenantComWebhook(tenantId: string, status: number) {
    const token = await app.get(TokenRepository).create(tenantId);
    await request(app.getHttpServer())
      .post('/webhooks')
      .set('X-Api-Token', token.rawToken)
      .send({ url: await consumer(status), events: ['invoice.cancelled'] })
      .expect(201);
    return token.rawToken;
  }

  async function criar(
    token: string,
    over: Record<string, unknown>,
    key: string,
  ) {
    const r = await request(app.getHttpServer())
      .post('/invoices')
      .set('X-Api-Token', token)
      .set('Idempotency-Key', key)
      .send(payload(over))
      .expect(201);
    return r.body as { invoiceId: string; providerPaymentId: string };
  }

  const overdue = (providerPaymentId: string, externalReference?: string) =>
    request(app.getHttpServer())
      .post('/webhook/payments')
      .set('asaas-access-token', WEBHOOK_SECRET)
      .send({
        event: 'PAYMENT_OVERDUE',
        payment: {
          id: providerPaymentId,
          status: 'OVERDUE',
          externalReference,
        },
      })
      .expect(200);

  it('emite os cenários e confirma cada métrica no Datadog com a contagem exata', async () => {
    // A — expira e a entrega ao consumidor funciona
    const tokenOk = await tenantComWebhook('tenant-dd-ok', 200);
    const a = await criar(
      tokenOk,
      { tenantId: 'tenant-dd-ok', orderId: 'MS-DD-A' },
      'dd-a',
    );
    await overdue(a.providerPaymentId);
    await overdue(a.providerPaymentId); // mesmo evento: não conta de novo

    // B — expira e a entrega falha (consumidor responde 500)
    const tokenFail = await tenantComWebhook('tenant-dd-fail', 500);
    const b = await criar(
      tokenFail,
      { tenantId: 'tenant-dd-fail', orderId: 'MS-DD-B' },
      'dd-b',
    );
    await overdue(b.providerPaymentId);

    // C — boleto já confirmado
    const c = await criar(TEST_API_TOKEN, { orderId: 'MS-DD-C' }, 'dd-c');
    await repository.updateInvoice(
      (await repository.findInvoice(TENANT_ID, c.invoiceId))!,
      'CONFIRMED',
    );
    await overdue(c.providerPaymentId);

    // D — boleto já expirado (evento diferente, para não cair na idempotência do PSP)
    const d = await criar(TEST_API_TOKEN, { orderId: 'MS-DD-D' }, 'dd-d');
    await repository.updateInvoice(
      (await repository.findInvoice(TENANT_ID, d.invoiceId))!,
      'EXPIRED',
    );
    await overdue(d.providerPaymentId, 'dd-retry');

    // E — invoice PIX
    const e = await criar(
      TEST_API_TOKEN,
      { orderId: 'MS-DD-E', billingType: 'PIX', dueDate: '2027-12-31' },
      'dd-e',
    );
    await overdue(e.providerPaymentId);

    // F — webhook não correlacionado
    await overdue('pay_dd_inexistente');

    flushMetrics();

    // contagens esperadas, todas filtradas pelo env único desta execução
    const expected: Array<[string, string[], number]> = [
      ['invoice.expired', [], 2],
      ['webhook.received', ['event_type:payment_overdue'], 6],
      ['webhook.delivery.sent', ['event:invoice.cancelled'], 1],
      ['webhook.delivery.failed', ['event:invoice.cancelled'], 1],
      ['invoice.expiration_ignored', ['reason:confirmado'], 1],
      ['invoice.expiration_ignored', ['reason:ja_expirado'], 1],
      ['invoice.expiration_ignored', ['reason:billing_type'], 1],
      ['webhook.failed', ['failure_type:uncorrelated'], 1],
    ];

    const faltando = await waitUntil(async () => {
      const out: string[] = [];
      for (const [metric, tags, n] of expected) {
        const got = await sumMetric(metric, [
          `env:${env}`,
          'service:payments-api',
          ...tags,
        ]);
        if (got !== n)
          out.push(
            `${metric}{${tags.join(',')}}: esperado ${n}, Datadog ${got}`,
          );
      }
      return out;
    });

    expect(faltando).toEqual([]);
  });
});
