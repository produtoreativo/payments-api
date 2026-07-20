import { Injectable } from '@nestjs/common';
import { DynamoService } from '../../../infra/dynamo.service';
import type { WebhookEventType } from '../dto/create-webhook.dto';

const TABLE = process.env.WEBHOOKS_TABLE ?? 'WebhooksTable';
const TENANT_INDEX = 'TenantWebhooksIndex';

export interface WebhookRecord {
  PK: string;
  SK: string;
  GSI1PK: string;
  GSI1SK: string;
  webhookId: string;
  tokenId: string;
  tenantId: string;
  url: string;
  events: WebhookEventType[];
  secret: string;
  description?: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

@Injectable()
export class WebhookRepository {
  constructor(private readonly dynamo: DynamoService) {}

  async save(record: WebhookRecord): Promise<void> {
    await this.dynamo.putItem(
      TABLE,
      record as unknown as Parameters<DynamoService['putItem']>[1],
    );
  }

  async findByTokenId(tokenId: string): Promise<WebhookRecord[]> {
    const items = await this.dynamo.queryItems(
      TABLE,
      `TOKEN#${tokenId}`,
      'WEBHOOK#',
    );
    return items.filter(
      (i) => (i as unknown as WebhookRecord).active,
    ) as unknown as WebhookRecord[];
  }

  async findOne(
    tokenId: string,
    webhookId: string,
  ): Promise<WebhookRecord | undefined> {
    const item = await this.dynamo.getItem(
      TABLE,
      `TOKEN#${tokenId}`,
      `WEBHOOK#${webhookId}`,
    );
    return item as unknown as WebhookRecord | undefined;
  }

  async findActiveByTenantId(tenantId: string): Promise<WebhookRecord[]> {
    const items = await this.dynamo.queryByIndex(
      TABLE,
      TENANT_INDEX,
      'GSI1PK',
      `TENANT#${tenantId}`,
    );
    return (items as unknown as WebhookRecord[]).filter((i) => i.active);
  }

  async countByTokenId(tokenId: string): Promise<number> {
    const items = await this.findByTokenId(tokenId);
    return items.length;
  }

  async deactivate(tokenId: string, webhookId: string): Promise<void> {
    await this.dynamo.updateItem(
      TABLE,
      `TOKEN#${tokenId}`,
      `WEBHOOK#${webhookId}`,
      {
        active: false,
        updatedAt: new Date().toISOString(),
      },
    );
  }
}
