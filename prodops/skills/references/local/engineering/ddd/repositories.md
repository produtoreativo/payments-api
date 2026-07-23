# Repositories — Port/Adapter Pattern

## InvoiceRepository como port

A interface do repositório vive na camada de domínio. Expressa o que o domínio precisa
de persistência — sem saber como a persistência funciona.

A implementação DynamoDB vive na camada de infraestrutura e implementa o port.

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

A interface **não contém**:
- Métodos DynamoDB (`scan`, `query` com expressões raw)
- Nomes de tabela ou índice (`PaymentsTable`, `ProviderPaymentIndex`)
- Qualquer tipo específico de infraestrutura (`AttributeValue`, `DynamoService`)

## Adapter (implementação DynamoDB)

O `InvoiceRepository` atual em `invoice-repository.service.ts` é a implementação
concreta com DynamoDB via `DynamoService`. Ele usa:
- `PAYMENTS_TABLE` para registros de fatura e idempotência
- `TRANSACTIONS_TABLE` para deduplicação de eventos do provedor
- `CUSTOMERS_TABLE` para vínculos cliente-provedor

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

## Injeção no NestJS

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

## Repository retorna domain objects, não DTOs

O adapter é responsável pelo mapeamento entre registro DynamoDB e domain object.
`InvoiceService` nunca recebe `AttributeValue` ou registros brutos de banco.
