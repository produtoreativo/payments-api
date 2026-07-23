# Bounded Context — Payments

## What belongs to this context

- Invoice lifecycle: creation, opening with provider, confirmation, cancellation
- Provider integration: sending charges to Asaas via `AsaasService`
- Webhook processing: receiving and applying provider status updates
- Idempotency: operation deduplication by `Idempotency-Key`
- Customer-provider link: `CustomerProviderLink` — link between internal customer and Asaas

## What does NOT belong

| Context | Responsibility | Integration point |
|---------|---------------|-------------------|
| Checkout | Creates orders, initiates payment requests | Sends `orderId` + `tenantId` as input |
| Notification | Sends email/push to end customer | Receives `payments.invoice.confirmed` events |
| Order Management | Fulfillment rules, order state | Payments stores `orderId` as opaque reference |
| Identity / IAM | Tenant authentication | `tenantId` arrives as a validated claim |

**Rule:** `InvoiceService` does not import modules from Checkout, Order Management, or
Notification. Communication is via events or explicit calls with typed DTOs.

## Boundaries in code

```typescript
// CORRECT — orderId is an opaque reference, no order business validation
const invoice: InvoiceRecord = {
  invoiceId,
  tenantId: createInvoiceDto.tenantId,
  orderId: createInvoiceDto.orderId,  // just stored
  // ...
};

// WRONG — crossing the boundary by querying order context rules
if (order.fulfillmentType === 'digital') { /* not our responsibility */ }
```

## Anti-corruption layer (ACL)

`AsaasService` is the ACL between Payments and the Asaas provider.

**What it does:**
- Translates domain concepts (`InvoiceRecord`, `amount`) into Asaas requests
- Translates Asaas responses into internal domain types
- Isolates Asaas-specific terminology from the domain layer

```typescript
// WRONG — Asaas field leaking into the domain
invoice.nossoNumero = response.nossoNumero;

// CORRECT — ACL maps to domain concepts
invoice.externalReference = invoiceId;  // internal invoice, not the Asaas ID
```

`externalReference` is the internal `invoiceId` (prefix `inv_`) sent to Asaas as
a reference. Asaas returns this same value in the webhook — Payments uses it to
correlate without exposing the internal Asaas model.

Asaas concepts (`boleto`, `pix`, `nossoNumero`, `cobrança`, `vencimento`)
never appear outside `AsaasService`.
