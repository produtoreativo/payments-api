import { Injectable } from '@nestjs/common';
import { DynamoService } from '../../infra/dynamo.service';
import { SplitPaymentRecord, SplitPaymentStatus } from './split-payment.types';

const PAYMENTS_TABLE = process.env.PAYMENTS_TABLE ?? 'PaymentsTable';
const TRANSACTIONS_TABLE =
  process.env.TRANSACTIONS_TABLE ?? 'TransactionsTable';
const CUSTOMERS_TABLE = process.env.CUSTOMERS_TABLE ?? 'CustomersTable';

@Injectable()
export class SplitPaymentRepository {
  constructor(private readonly dynamo: DynamoService) {}

  async findByIdempotencyKey(
    tenantId: string,
    idempotencyKey: string,
  ): Promise<SplitPaymentRecord | undefined> {
    const item = await this.dynamo.getItem(
      PAYMENTS_TABLE,
      `TENANT#${tenantId}`,
      `SPLIT_IDEMPOTENCY#${idempotencyKey}`,
    );
    const splitPaymentId =
      typeof item?.splitPaymentId === 'string'
        ? item.splitPaymentId
        : undefined;

    if (!splitPaymentId) {
      return undefined;
    }

    return this.findById(tenantId, splitPaymentId);
  }

  async save(
    record: SplitPaymentRecord,
    idempotencyKey: string,
  ): Promise<void> {
    await this.dynamo.putItem(PAYMENTS_TABLE, {
      PK: `TENANT#${record.tenantId}`,
      SK: `SPLIT_PAYMENT#${record.splitPaymentId}`,
      record,
      splitPaymentId: record.splitPaymentId,
      orderId: record.orderId,
      status: record.status,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });

    await this.dynamo.putItem(PAYMENTS_TABLE, {
      PK: `TENANT#${record.tenantId}`,
      SK: `SPLIT_IDEMPOTENCY#${idempotencyKey}`,
      splitPaymentId: record.splitPaymentId,
      createdAt: record.createdAt,
    });
  }

  async update(
    record: SplitPaymentRecord,
    status: SplitPaymentStatus,
    attrs: Partial<SplitPaymentRecord> = {},
  ): Promise<SplitPaymentRecord> {
    const updated: SplitPaymentRecord = {
      ...record,
      ...attrs,
      status,
      updatedAt: new Date().toISOString(),
    };

    await this.dynamo.putItem(PAYMENTS_TABLE, {
      PK: `TENANT#${updated.tenantId}`,
      SK: `SPLIT_PAYMENT#${updated.splitPaymentId}`,
      record: updated,
      splitPaymentId: updated.splitPaymentId,
      orderId: updated.orderId,
      status: updated.status,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    });

    return updated;
  }

  async findById(
    tenantId: string,
    splitPaymentId: string,
  ): Promise<SplitPaymentRecord | undefined> {
    const item = await this.dynamo.getItem(
      PAYMENTS_TABLE,
      `TENANT#${tenantId}`,
      `SPLIT_PAYMENT#${splitPaymentId}`,
    );

    return item?.record as SplitPaymentRecord | undefined;
  }

  async hasWebhookBeenProcessed(webhookKey: string): Promise<boolean> {
    const item = await this.dynamo.getItem(
      TRANSACTIONS_TABLE,
      `SPLIT_WEBHOOK#${webhookKey}`,
      'PROCESSED',
    );

    return Boolean(item);
  }

  async markWebhookProcessed(webhookKey: string): Promise<void> {
    await this.dynamo.putItem(TRANSACTIONS_TABLE, {
      PK: `SPLIT_WEBHOOK#${webhookKey}`,
      SK: 'PROCESSED',
      processedAt: new Date().toISOString(),
    });
  }

  async findCustomerLink(
    tenantId: string,
    customerId: string,
  ): Promise<{ providerCustomerId: string } | undefined> {
    const item = await this.dynamo.getItem(
      CUSTOMERS_TABLE,
      `TENANT#${tenantId}`,
      `CUSTOMER#${customerId}#PROVIDER#ASAAS`,
    );

    if (!item?.link) {
      return undefined;
    }

    return item.link as { providerCustomerId: string };
  }

  async saveCustomerLink(
    tenantId: string,
    customerId: string,
    providerCustomerId: string,
  ): Promise<void> {
    const now = new Date().toISOString();

    await this.dynamo.putItem(CUSTOMERS_TABLE, {
      PK: `TENANT#${tenantId}`,
      SK: `CUSTOMER#${customerId}#PROVIDER#ASAAS`,
      link: {
        tenantId,
        customerId,
        provider: 'ASAAS',
        providerCustomerId,
        createdAt: now,
        updatedAt: now,
      },
      providerCustomerId,
      createdAt: now,
      updatedAt: now,
    });
  }
}
