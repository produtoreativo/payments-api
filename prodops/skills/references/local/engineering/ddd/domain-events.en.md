# Domain Events

## Events in the Payments context

| Event | Trigger | Downstream consumers |
|-------|---------|---------------------|
| `payments.invoice.created` | Invoice saved after creation | Observability, Order Management |
| `payments.invoice.opened` | Charge created with provider | Observability |
| `payments.invoice.confirmed` | `PAYMENT_CONFIRMED` webhook processed | Notification, Order fulfillment |
| `payments.invoice.cancelled` | Cancellation applied | Notification, Order reversal |
| `payments.invoice.provider_failed` | Provider creation failure | Alerts, retry |
| `payments.customer.provider_linked` | Customer linked to Asaas | Observability |

Events named as `domain.context.action` with verb in past tense.

## Naming convention

Format: `payments.<entity>.<past-verb>`

- `payments.invoice.created` — not `invoice_created` nor `InvoiceCreated`
- `payments.invoice.confirmed` — not `payment.approved`

`EventEmitter2` is configured with `wildcard: true` and `delimiter: '.'` in
`AppModule` — allows `payments.**` to listen to all payment events.

## Emitting events with EventEmitter2

```typescript
// application/invoice.service.ts — confirmation via webhook
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
```

## Consuming events with @OnEvent

```typescript
// application/handlers/invoice-confirmed.handler.ts
@Injectable()
export class InvoiceConfirmedHandler {
  @OnEvent('payments.invoice.confirmed')
  async handle(payload: InvoiceConfirmedPayload): Promise<void> {
    // e.g.: publish to SQS queue for downstream processing
    await this.sqsPublisher.publish('invoice-events', payload);
  }
}
```

## Event type

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
```

**Include:** `invoiceId`, `tenantId`, `orderId`, `timestamp`.
**Exclude:** sensitive data (card number, CVV), raw provider payloads.

## Relation to Event Storming

- **Command** → **Event**: `ConfirmInvoice` (webhook) → `payments.invoice.confirmed`
- **Trigger**: Asaas webhook fires the command
- **Reaction**: handler forwards to SQS; Notification context consumes

Each event must correspond to an entry in the observability plan (`plan.json`).
