import { Logger, Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DynamoService } from './infra/dynamo.service';
import { SqsService } from './infra/sqs.service';
import { AsaasService } from './infra/asaas.service';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import awsConfig from './config/aws.config';

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
          service: {
            name: 'payments-api',
            version: process.env.npm_package_version || '0.0.1',
          },
          environment: process.env.NODE_ENV || 'development',
        },
        transport:
          process.env.NODE_ENV !== 'production'
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
  ],
  controllers: [AppController],
  providers: [Logger, DynamoService, SqsService, AsaasService, AppService],
})
export class AppModule {}
