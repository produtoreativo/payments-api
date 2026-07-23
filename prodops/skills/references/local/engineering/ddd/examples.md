# Examples — Payments Domain em TypeScript

Exemplos baseados no código real do projeto.

---

## Exemplo 1: Invoice como aggregate

```typescript
// domain/invoice.ts
export class Invoice {
  private constructor(
    readonly invoiceId: string,
    readonly tenantId: string,
    readonly orderId: string,
    readonly amount: number,
    private status: InvoiceStatus,
    readonly externalReference: string,
  ) {}

  static create(tenantId: string, orderId: string, amount: number): Invoice {
    const invoiceId = `inv_${ulid()}`;
    return new Invoice(invoiceId, tenantId, orderId, amount, 'CREATED', invoiceId);
  }

  confirm(): void {
    if (this.status !== 'OPEN') {
      throw new Error(`Cannot confirm invoice with status ${this.status}`);
    }
    this.status = 'CONFIRMED';
  }

  cancel(): void {
    if (this.status === 'CONFIRMED' || this.status === 'RECEIVED') {
      throw new Error('Invoice cancellation after confirmation requires refund flow');
    }
    this.status = 'CANCELLED';
  }

  getStatus(): InvoiceStatus { return this.status; }
}
```

---

## Exemplo 2: InvoiceRepository como port

```typescript
// domain/invoice-repository.interface.ts
export const INVOICE_REPOSITORY = Symbol('InvoiceRepository');

export interface InvoiceRepository {
  save(invoice: Invoice): Promise<void>;
  findById(invoiceId: string, tenantId: string): Promise<Invoice | null>;
  findByExternalReference(ref: string): Promise<Invoice | undefined>;
}

// A interface NÃO conhece DynamoDB, SQL, tabelas ou índices.
// O adapter DynamoInvoiceRepository implementa esta interface na camada de infraestrutura.
```

---

## Exemplo 3: InvoiceService como application service

```typescript
// application/invoice.service.ts — createInvoice orquestrando tudo
@Injectable()
export class InvoiceService {
  constructor(
    private readonly repository: InvoiceRepository,
    private readonly asaas: AsaasService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async createInvoice(
    dto: CreateInvoiceDto,
    idempotencyKey: string,
  ): Promise<InvoiceResponseDto> {
    // 1. Idempotência
    const existing = await this.repository.findByIdempotencyKey(dto.tenantId, idempotencyKey);
    if (existing) return this.toResponse(existing);

    // 2. Criar aggregate e persistir
    const invoice = Invoice.create(dto.tenantId, dto.orderId, dto.amount);
    await this.repository.save(invoice);

    // 3. Emitir evento de criação
    this.eventEmitter.emit('payments.invoice.created', {
      invoiceId: invoice.invoiceId,
      orderId: invoice.orderId,
      tenantId: invoice.tenantId,
    });

    // 4. Criar cobrança no Asaas (ACL)
    const charge = await this.asaas.createCharge({
      value: invoice.amount,
      externalReference: invoice.externalReference,
      billingType: dto.billingType,
      dueDate: dto.dueDate,
    });

    // 5. Atualizar aggregate com dados do provedor e emitir evento
    invoice.open(charge.id, charge.invoiceUrl);
    await this.repository.save(invoice);
    this.eventEmitter.emit('payments.invoice.opened', {
      invoiceId: invoice.invoiceId,
      providerPaymentId: charge.id,
    });

    // 6. Retornar DTO — nunca o domain object diretamente
    return this.toResponse(invoice);
  }
}
```

---

## Exemplo 4: InvoiceConfirmed domain event — emissão e handler

```typescript
// types/invoice-events.types.ts
export interface InvoiceConfirmedPayload {
  invoiceId: string;
  orderId: string;
  tenantId: string;
  amount: number;
  currency: string;
  provider: string;
  providerPaymentId: string;
  confirmedAt: string;
  timestamp: string;
}

// application/invoice.service.ts — emissão após webhook PAYMENT_CONFIRMED
this.eventEmitter.emit('payments.invoice.confirmed', {
  invoiceId: confirmedInvoice.invoiceId,
  orderId: confirmedInvoice.orderId,
  tenantId: confirmedInvoice.tenantId,
  amount: confirmedInvoice.amount,
  currency: confirmedInvoice.currency,
  provider: confirmedInvoice.provider,
  providerPaymentId: confirmedInvoice.providerPaymentId,
  confirmedAt: payload.payment?.confirmedDate ?? confirmedInvoice.updatedAt,
  timestamp: confirmedInvoice.updatedAt,
});

// application/handlers/invoice-confirmed.handler.ts
@Injectable()
export class InvoiceConfirmedHandler {
  constructor(private readonly sqsPublisher: SqsPublisher) {}

  @OnEvent('payments.invoice.confirmed')
  async handle(payload: InvoiceConfirmedPayload): Promise<void> {
    await this.sqsPublisher.publish('invoice-events', payload);
  }
}
```
