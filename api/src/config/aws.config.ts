/* eslint-disable @typescript-eslint/no-unsafe-call */
import { registerAs } from '@nestjs/config';

export default registerAs('aws', () => ({
  dynamoDbUrl: process.env.AWS_DYNAMODB_ENDPOINT || 'http://localhost:4566',
  region: process.env.AWS_REGION || 'us-east-1',
}));

// ASAAS_TOKEN=$aact_hmlg_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OmNkNmQ2YTU0LTNiZDEtNGRiYi1iMGIxLWUzODIzOTQ1YzQ2Nzo6JGFhY2hfNGFkNTQxNDEtNzhjMC00MDc3LWIzOTMtMGZmNzAyZjAzNjhi
// ASAAS_URL=https://api-sandbox.asaas.com

// #PAYMENTS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/payments-queue-sandbox

// AWS_REGION=us-east-1
// AWS_ACCESS_KEY_ID=test
// AWS_SECRET_ACCESS_KEY=test
// AWS_DYNAMODB_ENDPOINT=http://localhost.localstack.cloud:4566
// AWS_SQS_ENDPOINT=http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/transactions-queue