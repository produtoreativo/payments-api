# OBC - Cancel Invoice via Gateway

## Status

Committed. Deferred to next iteration — see `prodops/artifacts/plans/iteration-plan.md` (decision: "Deferred"). OBC committed; available for Bootstrap + Hack in the following iteration.

## Business Outcome

Magazine Siará ecommerce can cancel a pending invoice via the Payments gateway without direct coupling to the Asaas provider. The cancellation guarantees idempotency by order key, prevents cancellation after payment confirmation, and publishes the canonical event `payment.cancelled` only when cancellation is effectively confirmed. Provider divergences (404, timeout) are handled with an explicit operational decision — no event published without confirmation.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `payment.cancelled` | Invoice cancelled with confirmation — charge removed from provider. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `cancelledAt`, `correlationId` |
| `invoice.cancel_requested` | Cancellation initiated — invoice in `CANCEL_REQUESTED`, provider call pending. | `invoiceId`, `orderId`, `tenantId`, `provider`, `correlationId` |
| `invoice.cancel_rejected` | Cancellation rejected by business rule — invoice in non-cancellable state (e.g.: `CONFIRMED`). | `invoiceId`, `tenantId`, `currentStatus`, `correlationId` |
| `invoice.cancel_idempotency_hit` | Cancellation retry with same key — already cancelled invoice returned without new call. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.cancel_provider_not_found` | Provider returned 404 — invoice awaiting operational reconciliation decision. | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |
| `webhook.payment_deleted` | Provider `PAYMENT_DELETED` webhook confirms cancellation for `CANCEL_REQUESTED`. | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Invoices with `CONFIRMED` status rejected at cancellation without provider call. | 100% |
| Retries with the same `Idempotency-Key` return `CANCELLED` without a new provider call. | 100% |
| `payment.cancelled` not published without confirmed removal or explicit reconciliation decision. | 100% |
| `payment.cancelled` not duplicated when `PAYMENT_DELETED` webhook arrives after command publication. | 100% |
| Invoice in `CANCEL_REQUESTED` transitioned to `CANCELLED` upon receiving `PAYMENT_DELETED` webhook. | 99.9% |

## Reliability Rules

- Invoice with `CONFIRMED` status cannot be cancelled. Post-confirmation cancellation requires a separate refund flow. The gateway rejects the operation with a clear business error without calling the provider.
- Idempotency by `Idempotency-Key`: a second cancellation call with the same key returns the current status without a new Asaas call.
- `payment.cancelled` is published exactly once. If the event was published in the cancellation command, the `PAYMENT_DELETED` webhook confirms the state but does not republish the canonical event.
- Provider returning 404 upon cancellation is not treated as confirmed cancellation. The invoice enters an operational investigation state; `payment.cancelled` is not published without an explicit decision.
- The cancellation command updates the invoice to `CANCEL_REQUESTED` before calling the provider — auditable intermediate state, safe for retry.
- Invoice with final `CANCELLED` status confirmed only when: (a) provider confirms removal in the command response, or (b) `PAYMENT_DELETED` webhook is received.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/cancel-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` (decision: Deferred)
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-003
- Related OBCs: `prodops/artifacts/obcs/create-invoice.en.md`, `prodops/artifacts/obcs/payment-confirmation.en.md`
