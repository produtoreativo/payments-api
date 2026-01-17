import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import serverlessExpress from '@codegenie/serverless-express';
import type { Express } from 'express';
import type { APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda';

let cachedServer: Awaited<ReturnType<typeof bootstrap>> | undefined;

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.init();
  console.log('NestJS AppContext ready');
  const expressApp: Express = app.getHttpAdapter().getInstance() as Express;
  return serverlessExpress({ app: expressApp });
}

export const handler: APIGatewayProxyHandler = async (event, context) => {
  cachedServer = cachedServer ?? (await bootstrap());
  const result: APIGatewayProxyResult = (await cachedServer(
    event,
    context,
    () => {},
  )) as APIGatewayProxyResult;
  return result;
};
