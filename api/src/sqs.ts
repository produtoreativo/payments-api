import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { AppService as PaymentsService } from './app.service';
import { SQSEvent } from 'aws-lambda';
import { INestApplicationContext } from '@nestjs/common';

let app: INestApplicationContext | undefined;

async function bootstrap(): Promise<INestApplicationContext> {
  if (!app) {
    app = await NestFactory.createApplicationContext(AppModule);
  }
  return app;
}

export const handler = async (event: SQSEvent): Promise<void> => {
  const app = await bootstrap();
  const paymentsService = app.get(PaymentsService);
  console.log('Event received:', event);
  for (const record of event.Records) {
    await paymentsService.processTransaction({ body: record.body });
  }
};
