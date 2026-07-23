# Application Services

## What is an application service

Orchestrates domain objects, repositories, and external services to complete a use case.
Does not contain business rules — calls domain objects that contain them.

## InvoiceService as an example

`InvoiceService` is the primary application service. Its use cases:

- `createInvoice()` — creates invoice, registers with provider, emits events
- `getInvoice()` — retrieves invoice by tenant + invoiceId
- `cancelInvoice()` — cancels invoice with provider, updates status
- `processProviderWebhook()` — processes Asaas webhook and applies status transition

## Rules

1. **Does not contain domain logic** — status transition logic lives in the aggregate
2. **Does not return domain objects** — returns `InvoiceResponseDto` or simple types
3. **Has infrastructure dependencies** — injects `InvoiceRepository`, `AsaasService`, `EventEmitter2`
4. **Coordinates the sequence** — fetch → validate → persist → call provider → emit event

## createInvoice() — step by step

```typescript
async createInvoice(
  dto: CreateInvoiceDto,
  idempotencyKey: string,
  correlationId?: string,
): Promise<InvoiceResponseDto> {
  // 1. Validate input (required fields, BRL currency, valid billingType)
  this.validateCreateInvoice(dto, idempotencyKey);

  // 2. Check idempotency — return existing invoice if key was already used
  const existing = await this.repository.findByIdempotencyKey(dto.tenantId, idempotencyKey);
  if (existing) return this.toResponse(existing);

  // 3. Resolve provider (ASAAS or ITAU)
  const provider = this.providerRouter.resolve(dto.provider);

  // 4. Create InvoiceRecord with CREATED status and save (+ idempotency key)
  const invoiceId = `inv_${ulid()}`;
  const invoice: InvoiceRecord = { invoiceId, ...dto, status: 'CREATED', externalReference: invoiceId };
  await this.repository.saveInvoice(invoice, idempotencyKey);
  this.eventEmitter.emit('payments.invoice.created', { invoiceId, orderId: dto.orderId, ... });

  // 5. Update to PROVIDER_PENDING before calling the provider
  const pendingInvoice = await this.repository.updateInvoice(invoice, 'PROVIDER_PENDING');

  // 6. Ensure customer exists in Asaas (CustomerProviderLink)
  const customerLink = await this.ensureProviderCustomer(pendingInvoice, provider, correlationId);

  // 7. Create charge in Asaas (AsaasService = anti-corruption layer)
  const charge = await this.asaas.createCharge({ customer: customerLink.providerCustomerId, ... });

  // 8. Update to OPEN with providerPaymentId and paymentUrl
  const openInvoice = await this.repository.updateInvoice(pendingInvoice, 'OPEN', {
    providerPaymentId: charge.id,
    paymentUrl: charge.invoiceUrl ?? charge.bankSlipUrl,
  });
  this.eventEmitter.emit('payments.invoice.opened', { invoiceId: openInvoice.invoiceId, ... });

  // 9. Return DTO — never the domain object directly
  return this.toResponse(openInvoice);
}
```

## What the application service does NOT do

- Does not contain inline `if (status === 'OPEN')` — that belongs in the aggregate
- Does not call DynamoDB directly — always via `InvoiceRepository`
- Does not know about HTTP (`Request`, `Response`, Express/Fastify objects)
- Does not import modules from Checkout or Order Management

## Difference from domain service

| Application service | Domain service |
|--------------------|----------------|
| Has infrastructure dependencies | No infrastructure |
| Orchestrates — no business rules | Contains business rules |
| `InvoiceService` | `FeeCalculationService` |

See [domain-services.md](./domain-services.md) for details.
