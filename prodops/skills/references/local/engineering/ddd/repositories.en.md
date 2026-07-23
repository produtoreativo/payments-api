# Repositories — Port/Adapter Pattern

## InvoiceRepository as port

The repository interface lives in the domain layer. It expresses what the domain needs
from persistence — without knowing how persistence works.

The DynamoDB implementation lives in the infrastructure layer and implements the port.

```
Domain layer          InvoiceRepository (interface / port)
                              ↑ implements
Infrastructure layer  DynamoInvoiceRepository (adapter)
```

## Interface (port)

```typescript
// domain/invoice-repository.interface.ts
export interface InvoiceRepository {
  save(invoice: Invoice): Promise<void>;
  findById(invoiceId: string, tenantId: TenantId): Promise<Invoice | null>;
  findByOrderId(orderId: string, tenantId: TenantId): Promise<Invoice[]>;
  findByExternalReference(ref: string): Promise<Invoice | undefined>;
}

export const INVOICE_REPOSITORY = Symbol('InvoiceRepository');
```

The interface does **not contain**:
- DynamoDB methods (`scan`, `query` with raw expressions)
- Table or index names (`PaymentsTable`, `ProviderPaymentIndex`)
- Any infrastructure-specific types (`AttributeValue`, `DynamoService`)

## Adapter (DynamoDB implementation)

The current `InvoiceRepository` in `invoice-repository.service.ts` is the concrete
implementation with DynamoDB via `DynamoService`. It uses:
- `PAYMENTS_TABLE` for invoice and idempotency records
- `TRANSACTIONS_TABLE` for provider event deduplication
- `CUSTOMERS_TABLE` for customer-provider links

```typescript
// infrastructure/dynamo-invoice-repository.ts
@Injectable()
export class DynamoInvoiceRepository implements InvoiceRepository {
  constructor(private readonly dynamo: DynamoService) {}

  async save(invoice: Invoice): Promise<void> {
    await this.dynamo.putItem(PAYMENTS_TABLE, this.toRecord(invoice));
  }

  async findById(invoiceId: string, tenantId: TenantId): Promise<Invoice | null> {
    const item = await this.dynamo.getItem(
      PAYMENTS_TABLE,
      `TENANT#${tenantId.value}`,
      `INVOICE#${invoiceId}`,
    );
    return item?.invoice ? this.toDomain(item.invoice) : null;
  }

  private toDomain(record: InvoiceRecord): Invoice { /* mapping */ }
  private toRecord(invoice: Invoice): Record<string, unknown> { /* mapping */ }
}
```

## NestJS injection

```typescript
// invoices.module.ts
@Module({
  providers: [
    { provide: INVOICE_REPOSITORY, useClass: DynamoInvoiceRepository },
    InvoiceService,
  ],
})
export class InvoicesModule {}

// invoice.service.ts
@Injectable()
export class InvoiceService {
  constructor(
    @Inject(INVOICE_REPOSITORY) private readonly repo: InvoiceRepository,
  ) {}
}
```

## Repository returns domain objects, not DTOs

The adapter is responsible for mapping between DynamoDB records and domain objects.
`InvoiceService` never receives `AttributeValue` or raw database records.
