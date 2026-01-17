/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

export class SqsService {
  private client = new SQSClient({
    region: process.env.AWS_REGION,
    endpoint: process.env.AWS_SQS_ENDPOINT,
  });
  private queueUrl = process.env.AWS_SQS_ENDPOINT!;

  sendMessage(payload: any) {
    return this.client.send(
      new SendMessageCommand({
        QueueUrl: this.queueUrl,
        MessageBody: JSON.stringify(payload),
      }),
    );
  }
}
