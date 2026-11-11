# Business event catalog — Payments

> **Single source in the code:** [`api/src/events/payments-events.ts`](../../../api/src/events/payments-events.ts).
> This catalog documents what is there. If they diverge, **the code wins** and this document must be fixed.
> Updated on 2026-11-10.

## 1. Naming convention

```
payments.<aggregate>.<fact>
```

| Rule | Description | Example |
|---|---|---|
| N1 | The `payments.` prefix identifies the product and is mandatory on every business event | `payments.invoice.confirmed` |
| N2 | Lowercase, `snake_case`, English, ASCII only | `payments.split_payment.pix_confirmed` |
| N3 | The **aggregate** is the singular noun of the domain root: `invoice`, `split_payment`, `customer`, `security` | |
| N4 | The **fact** says what happened, in the past tense or as a state. Never imperative or intent | `created`, `confirmed`, `refund_requested`, `chargeback_reversal_pending` |
| N5 | A failure is `<noun>_failed` | `payments.invoice.creation_failed` |
| N6 | The **payment method goes in the payload** (`billingType`), not in the name, unless the fact only exists for it (in Split Payment: `pix_confirmed`, `boleto_expired`) | `payments.invoice.opened` with `billingType: BOLETO` |
| N7 | **One fact, one name.** The same fact is never emitted under two names | see section 4 |
| N8 | Fixed spelling: `cancelled` | `payments.invoice.cancelled` |
| N9 | The name is a contract. The payload format version is a field, not part of the name | |

**Out of this convention, on purpose:**

| What | Where | Why |
|---|---|---|
| `payments.observability` and the `event_key` keys (`pagamento.*`, `api.token.*`, `webhook.*`) | observability stream, listened to by `ObservabilityListener` | A different layer: feeds Datadog metrics and dashboards, not a domain fact |
| `payment.created`, `payment.failed`, `webhook.received`… | `api/src/observability/metrics.ts` | These are Datadog **metrics**, not events |
| `invoice.created`, `invoice.confirmed`, `invoice.cancelled` | event types delivered to the consumer by webhook (`WebhookEventType`) | **External contract**, without the prefix. `WebhookDeliveryService` translates `payments.invoice.confirmed` → `invoice.confirmed` and `payments.invoice.cancelled` → `invoice.cancelled` |

## 2. Events emitted today (20)

| Event | When | Payload fields | Listened to by |
|---|---|---|---|
| `payments.invoice.created` | Invoice persisted, before calling the provider | `invoiceId`, `orderId`, `provider`, `status`, `timestamp` | — |
| `payments.invoice.opened` | The provider registered the charge; the invoice is **payable** (any method) | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `status`, `billingType`, `dueDate`, `correlationId`, `timestamp` | — |
| `payments.invoice.creation_failed` | Failure creating the charge at the provider (any method) | `invoiceId`, `orderId`, `tenantId`, `provider`, `billingType`, `reason`, `correlationId`, `timestamp` | — |
| `payments.invoice.idempotency_hit` | Retry with the same idempotency key; the existing invoice is returned (today only for `BOLETO`) | `invoiceId`, `orderId`, `tenantId`, `correlationId` | — |
| `payments.invoice.confirmed` | Payment approved by the provider — releases the order | `invoiceId`, `orderId`, `tenantId`, `amount`, `currency`, `provider`, `providerPaymentId`, `confirmedAt`, `timestamp` | `WebhookDeliveryService` → external webhook `invoice.confirmed` |
| `payments.invoice.expired` | Overdue boleto cancelled automatically (`PAYMENT_OVERDUE`); the invoice becomes `EXPIRED` | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `amount`, `currency`, `dueDate`, `expiredAt`, `correlationId` | `WebhookDeliveryService` → external webhook `invoice.cancelled` (`status: EXPIRED`) |
| `payments.invoice.received` | Financial settlement (reconciliation); does not release the order again | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` | — |
| `payments.invoice.cancelled` | Cancellation confirmed | `invoiceId`, `orderId`, `tenantId`, `amount`, `currency`, `provider`, `providerPaymentId`, `cancelledAt`, `timestamp` | `WebhookDeliveryService` → external webhook `invoice.cancelled` |
| `payments.invoice.refund_requested` | Card refund requested | `invoiceId`, `orderId`, `tenantId`, `providerPaymentId`, `amount`, `reason`, `correlationId` | — |
| `payments.invoice.chargeback_requested` | Chargeback requested by the cardholder (`CREDIT_CARD` only) | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.invoice.chargeback_disputed` | Chargeback under dispute | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.invoice.chargeback_reversal_pending` | Waiting for the chargeback reversal | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.customer.provider_linked` | Customer linked to the provider (created or reused) | `tenantId`, `customerId`, `provider`, `providerCustomerId`, `timestamp` | — |
| `payments.security.webhook_rejected` | Provider webhook rejected for an invalid token | `provider`, `reason`, `timestamp` | — |
| `payments.split_payment.created` | Split Payment created | `splitPaymentId`, `orderId`, `pixAmount`, `boletoAmount`, `totalAmount`, `correlationId` | — |
| `payments.split_payment.creation_failed` | Failure creating the Split Payment | `orderId`, `reason`, `correlationId` | — |
| `payments.split_payment.pix_confirmed` | Pix part confirmed | `splitPaymentId`, `orderId`, `pixInvoiceId`, `confirmedAt`, `correlationId` | — |
| `payments.split_payment.boleto_confirmed` | Boleto part confirmed | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `confirmedAt`, `correlationId` | — |
| `payments.split_payment.completed` | Pix and Boleto confirmed | `splitPaymentId`, `orderId`, `completedAt`, `correlationId` | — |
| `payments.split_payment.boleto_expired` | The Split's boleto expired | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `expiredAt`, `pixStatus`, `correlationId` | — |

## 3. Mapping of the old names

| Old name | Current name |
|---|---|
| `payments.invoice.provider_failed`, `payment.boleto.creation_failed` | `payments.invoice.creation_failed` |
| `payment.boleto.created`, `payment.card.hosted_invoice.created` | `payments.invoice.opened` |
| `payment.confirmed` + `payments.invoice.confirmed` | `payments.invoice.confirmed` |
| `payment.cancelled` + `payments.invoice.cancelled` | `payments.invoice.cancelled` |
| `payment.boleto.idempotency_hit` | `payments.invoice.idempotency_hit` |
| `payment.received` | `payments.invoice.received` |
| `payment.card.refund.requested` | `payments.invoice.refund_requested` |
| `payment.chargeback_requested`, `payment.chargeback_dispute`, `payment.chargeback_reversal_pending` | `payments.invoice.chargeback_requested`, `payments.invoice.chargeback_disputed`, `payments.invoice.chargeback_reversal_pending` |
| `split_payment.created` / `.creation_failed` / `.completed` | `payments.split_payment.created` / `.creation_failed` / `.completed` |
| `split_payment.pix.confirmed` / `.boleto.confirmed` / `.boleto.expired` | `payments.split_payment.pix_confirmed` / `.boleto_confirmed` / `.boleto_expired` |

## 4. Duplicates eliminated

There were 24 names emitted; **5 were duplicates** of another event and were eliminated. 19 remained; today there are 20, with `payments.invoice.expired`.

| # | Eliminated | Survivor | Why it was a duplicate |
|---|---|---|---|
| 1 | `payment.confirmed` | `payments.invoice.confirmed` | Same fact, emitted on the same line, with the same payload (the second only added `timestamp`) |
| 2 | `payment.cancelled` | `payments.invoice.cancelled` | Same |
| 3 | `payment.boleto.creation_failed` | `payments.invoice.creation_failed` | It was the same creation failure as `payments.invoice.provider_failed`, emitted in sequence (boleto only, with `reason` instead of `message`) |
| 4 | `payment.boleto.created` | `payments.invoice.opened` | A per-method echo of the same moment: the invoice became payable. `dueDate` moved to the survivor's payload |
| 5 | `payment.card.hosted_invoice.created` | `payments.invoice.opened` | Same, for card. The payment method now comes in `billingType` |

Consequences:
- The consumers (`WebhookDeliveryService`) listen to `payments.invoice.confirmed` and `payments.invoice.cancelled`; the webhook delivered to the customer did not change.
- No event is emitted twice anymore: a test guarantees a single emission and that no old name reappears in the code (`api/src/events/payments-events.spec.ts` and the confirmation spec).

## 5. Planned events

None at the moment. An event promised in an OBC and not yet emitted is listed here as `Planned`. The last one to leave this list was `payments.invoice.expired` (OBC [`boleto-auto-cancellation`](../obcs/boleto-auto-cancellation.md)); the fact is the boleto expiring and the payment method goes in `billingType` (rule N6).

## 6. From the internal event to the webhook delivered to the consumer

The webhook the consumer receives has an **external**, stable type without the `payments.` prefix. More than one internal event may feed the same external type:

| Internal event | External type delivered | Status |
|---|---|---|
| `payments.invoice.confirmed` | `invoice.confirmed` | Emitted |
| `payments.invoice.cancelled` | `invoice.cancelled` (`status: CANCELLED`) | Emitted |
| `payments.invoice.expired` | `invoice.cancelled` (`status: EXPIRED`, `reason: BOLETO_OVERDUE`) | Emitted |

`invoice.created` is accepted on subscription (`WebhookEventType`), but no internal event delivers it today.

Decision recorded in [`boleto-auto-cancellation`](../obcs/boleto-auto-cancellation.md): reuse `invoice.cancelled` instead of creating `invoice.expired`, to be confirmed with the consumer (risk `RISK-BC-003`).

## 7. Known pending items (not handled in this change)

- **Time field with 5 names:** `timestamp`, `occurredAt`, `receivedAt`, `confirmedAt`, `expiredAt`/`cancelledAt`/`completedAt`. The payload convention (envelope) is not defined yet.
- **`tenantId` and `correlationId` missing** in some events (for example `payments.invoice.created` and the chargeback ones).
- **`payments.invoice.idempotency_hit`** is only emitted for `BOLETO`, although the name is generic.
- **Events promised in the OBCs and not emitted yet** appear as `Planned`; their names already follow this convention.

## 8. How to add an event

1. Pick the name from the convention (section 1) and check the fact does not already exist (N7).
2. Add the constant in `api/src/events/payments-events.ts` — the single source of names.
3. Emit with `this.eventEmitter.emit(PaymentsEvent.<Name>, payload)`; never with a literal.
4. Write the test that verifies the emission (with the literal name, to lock the contract).
5. Record the event in the capability's OBC (`Observable Events`, Status `Emitted`) and in this catalog.
