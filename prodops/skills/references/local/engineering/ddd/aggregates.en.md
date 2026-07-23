# Aggregates — Invoice

## What is an aggregate root

A unit of transactional consistency. All access to `Invoice` state must pass
through the aggregate root — no external code modifies fields directly.

## Invoice as aggregate root

`Invoice` has:
- **Identity**: `invoiceId` (format `inv_<ULID>`)
- **State**: `status` — defines what can happen next
- **Context**: `tenantId`, `orderId`, `amount`, `billingType`, `provider`
- **Traceability**: `externalReference`, `providerPaymentId`, `createdAt`, `updatedAt`

## Invariants — valid status transitions

| From | To | Allowed? |
|------|----|---------|
| CREATED | PROVIDER_PENDING | yes |
| PROVIDER_PENDING | OPEN | yes |
| PROVIDER_PENDING | FAILED | yes |
| OPEN | CONFIRMED | yes (via webhook) |
| OPEN | RECEIVED | yes (via webhook) |
| OPEN | CANCEL_REQUESTED | yes |
| CANCEL_REQUESTED | CANCELLED | yes |
| CONFIRMED | CANCELLED | no — requires refund flow |
| CANCELLED | CONFIRMED | no — terminal |

Violations throw an exception — never silently ignored.

## Aggregate size

Small aggregates are preferred. `Invoice` does not include:
- Webhook history (stored separately as `ProviderEvent`)
- `CustomerProviderLink` (its own aggregate, managed separately)

## TypeScript example

```typescript
export class Invoice {
  private constructor(
    readonly invoiceId: string,
    readonly tenantId: string,
    readonly orderId: string,
    readonly amount: number,
    private status: InvoiceStatus,
  ) {}

  static create(tenantId: string, orderId: string, amount: number): Invoice {
    return new Invoice(`inv_${ulid()}`, tenantId, orderId, amount, 'CREATED');
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

  getStatus(): InvoiceStatus {
    return this.status;
  }
}
```

## What the aggregate does NOT do

- Does not call `AsaasService` — that is the application service's responsibility
- Does not emit events to SQS — that is the application service's responsibility
- Does not know about HTTP, DTOs, or NestJS decorators
- Does not know about DynamoDB or any persistence technology
