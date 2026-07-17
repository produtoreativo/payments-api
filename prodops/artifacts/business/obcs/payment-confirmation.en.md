# OBC - Payment Confirmation via Webhook

## Status

Downstream. Status `In` in `prodops/artifacts/governance/plans/iteration-plan.md` (section "Recommended Iteration Plan").

## Business Outcome

Magazine Siará ecommerce receives reliable payment confirmation and releases the order exactly once, even when the provider webhook arrives duplicated, delayed, or before the internal invoice consolidation. The canonical event `payment.confirmed` is published only after authentication token validation and correlation with the correct invoice. Raw provider events are always persisted for audit, regardless of processing outcome.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `payment.confirmed` | Payment approved — order can be released by ecommerce. Published exactly once. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.received` | Financial settlement confirmed — for reconciliation. Does not release order a second time. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` |
| `webhook.received` | Raw provider event persisted before any processing. | `tenantId`, `provider`, `eventType`, `providerPaymentId`, `correlationId` |
| `webhook.rejected` | Webhook received with invalid token — rejected without state change. | `tenantId`, `provider`, `reason`, `correlationId` |
| `webhook.deduplicated` | Duplicate webhook recognized — technical success returned without reprocessing. | `invoiceId`, `tenantId`, `provider`, `eventType`, `correlationId` |
| `webhook.correlated_by_reference` | Event correlated by `externalReference` in the absence of internal `providerPaymentId`. | `invoiceId`, `orderId`, `tenantId`, `externalReference`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| `payment.confirmed` events published exactly once per approved payment. | 100% |
| Webhooks with invalid token rejected without invoice state change. | 100% |
| Duplicate webhooks return technical success without republishing `payment.confirmed`. | 100% |
| `payment.received` event does not trigger a second order release. | 100% |
| Asaas authentication token not exposed in logs or error responses. | 100% |
| Raw events persisted before any processing. | 99.9% |

## Reliability Rules

- The `payment.confirmed` event is published exactly once per `providerPaymentId`. Deduplication is mandatory: a second call recognizes the duplicate and returns technical success to the provider without republishing the canonical event.
- Every webhook request must carry a valid `asaas-access-token` header before any state read or change. An invalid request is rejected; no payload data is processed.
- Authentication token is never logged — neither on success nor on rejection. Log records only the validation result.
- A webhook received before internal invoice consolidation is correlated by `externalReference`. The gateway finds the correct invoice and completes confirmation without creating duplicates.
- `PAYMENT_RECEIVED` updates the invoice to `RECEIVED` and records for financial reconciliation, but does not publish a second `payment.confirmed` — the order was already released by `PAYMENT_CONFIRMED`.
- Events that do not release orders in the MVP (e.g.: `PAYMENT_OVERDUE`) are recorded and update operational state when applicable, but do not publish `payment.confirmed`.
- Raw provider event is persisted regardless of processing outcome — audit guarantee even in case of failure.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/payment-confirmation.feature`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-002
- Related OBCs: `prodops/artifacts/business/obcs/create-invoice.en.md`, `prodops/artifacts/business/obcs/webhook-configuration.en.md`
