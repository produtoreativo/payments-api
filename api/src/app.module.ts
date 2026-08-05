import { Logger, Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import type { IncomingMessage } from 'http';
import awsConfig from './config/aws.config';
import { InvoicesModule } from './modules/invoices/invoices.module';
import { WebhooksModule } from './modules/webhooks/webhooks.module';
import { ObservabilityModule } from './observability/observability.module';
import { SplitPaymentsModule } from './modules/split-payments/split-payments.module';
import { ddTraceMixin } from './observability/datadog.tracer';

// pino-pretty reformats JSON to text, stripping dd.trace_id / dd.span_id.
// Disable when DD log injection is active.
const usePinoTransport =
  process.env.NODE_ENV === 'development' &&
  process.env.DD_LOGS_INJECTION !== 'true';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [awsConfig],
    }),
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL || 'info',
        base: {
          service: process.env.DD_SERVICE ?? 'payments-api',
          version:
            process.env.DD_VERSION ??
            process.env.npm_package_version ??
            '0.0.1',
          env: process.env.DD_ENV ?? process.env.NODE_ENV ?? 'development',
        },

        mixin: ddTraceMixin,
        genReqId: (req: IncomingMessage) =>
          (req.headers['x-correlation-id'] as string | undefined) ??
          `req_${Date.now().toString(36)}`,
        customLogLevel: (
          _req: IncomingMessage,
          res: { statusCode: number },
          err?: Error,
        ) => {
          if (res.statusCode >= 500 || err) return 'error';
          if (res.statusCode >= 400) return 'warn';
          return 'info';
        },
        redact: {
          paths: [
            'req.headers.authorization',
            'req.headers["asaas-access-token"]',
            'req.headers["x-api-token"]',
            'req.body.cardNumber',
            'req.body.cvv',
            'req.body.cardToken',
          ],
          censor: '[REDACTED]',
        },
        transport: usePinoTransport
          ? {
              target: 'pino-pretty',
              options: {
                singleLine: true,
                colorize: true,
                translateTime: 'SYS:standard',
              },
            }
          : undefined,
      },
    }),
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
    }),
    InvoicesModule,
    WebhooksModule,
    ObservabilityModule,
    SplitPaymentsModule,
  ],
  controllers: [],
  providers: [Logger],
})
export class AppModule {}
