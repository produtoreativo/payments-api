/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
} from '@aws-sdk/lib-dynamodb';

export class DynamoService {
  private client: DynamoDBDocumentClient;

  constructor() {
    const isLocal = process.env.AWS_DYNAMODB_ENDPOINT !== undefined;

    const dynamoClient = new DynamoDBClient({
      region: process.env.AWS_REGION || 'us-east-1',
      endpoint: process.env.AWS_DYNAMODB_ENDPOINT,
      credentials: isLocal
        ? {
            accessKeyId: 'test',
            secretAccessKey: 'test',
          }
        : undefined,
    });

    this.client = DynamoDBDocumentClient.from(dynamoClient, {
      marshallOptions: {
        removeUndefinedValues: true,
      },
    });
  }

  // private client = DynamoDBDocumentClient.from(
  //   new DynamoDBClient({
  //     region: process.env.AWS_REGION,
  //     endpoint: process.env.AWS_DYNAMODB_ENDPOINT,
  //     credentials: {
  //       accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? '',
  //       secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? '',
  //     },
  //   }),
  // );

  async getItem(table: string, pk: string, sk: string) {
    return this.client
      .send(
        new GetCommand({
          TableName: table,
          Key: { PK: pk, SK: sk },
        }),
      )
      .then((r) => r.Item)
      .catch((error) => {
        console.error('DynamoDB getItem error:', error);
        throw error;
      });
  }

  async putItem(table: string, item: any) {
    return await this.client.send(
      new PutCommand({
        TableName: table,
        Item: item,
      }),
    );
  }

  async updateItem(table: string, pk: string, sk: string, attrs: any) {
    const updates = Object.keys(attrs)
      .map((k) => `#${k} = :${k}`)
      .join(', ');

    return await this.client.send(
      new UpdateCommand({
        TableName: table,
        Key: { PK: pk, SK: sk },
        UpdateExpression: `SET ${updates}`,
        ExpressionAttributeNames: Object.fromEntries(
          Object.keys(attrs).map((k) => [`#${k}`, k]),
        ),
        ExpressionAttributeValues: Object.fromEntries(
          Object.keys(attrs).map((k) => [`:${k}`, attrs[k]]),
        ),
      }),
    );
  }
}
