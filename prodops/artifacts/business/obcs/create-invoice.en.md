# OBC - Create Invoice via Gateway

## Status

Downstream. Status `In` in `prodops/artifacts/governance/plans/iteration-plan.md` (section "Recommended Iteration Plan") — Pix journey as the first enabled billing type.

## Business Outcome

Magazine Siará can create payment charges via the Payments gateway without direct coupling to the Asaas provider. The Checkout sends a single invoice contract; the gateway resolves the provider, creates or reuses the Asaas customer, guarantees idempotency by order key, and returns traceable identifiers. The invoice reaches `OPEN` status only when the `providerPaymentId` is consolidated — never before. Validation errors are auditable without exposing secrets or sensitive payloads.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `invoice.created` | Invoice successfully created at the provider — status `OPEN`, `providerPaymentId` present. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `correlationId` |
| `invoice.creation_failed` | Failed to create invoice at the provider — invoice in `FAILED` or `PROVIDER_PENDING`. | `invoiceId`, `orderId`, `tenantId`, `reason`, `provider`, `correlationId` |
| `invoice.idempotency_hit` | Retry with same idempotency key — existing invoice returned without a new charge. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.provider_rejected` | Provider rejected creation due to invalid data — invoice marked as `FAILED`. | `invoiceId`, `orderId`, `tenantId`, `providerErrorCode`, `correlationId` |
| `invoice.customer_created` | Asaas customer created before invoice due to missing binding. | `tenantId`, `customerId`, `providerCustomerId`, `correlationId` |
| `invoice.access_rejected` | Attempt to create invoice with a provider disabled for the tenant. | `tenantId`, `provider`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Invoices created with `providerPaymentId` present in the response to Checkout. | 99.9% |
| Retries with the same `Idempotency-Key` return the existing invoice without a new provider call. | 100% |
| `OPEN` invoice never returned to Checkout without consolidated `providerPaymentId`. | 100% |
| Provider validation errors returned without exposed secrets or sensitive payload. | 100% |
| Requests with a provider disabled for the tenant rejected before calling the provider API. | 100% |

## Reliability Rules

- The gateway does not return `OPEN` status to Checkout without a confirmed `providerPaymentId`. Transient failure (timeout, 5xx) produces `PROVIDER_PENDING` state — retry with the same idempotency key is safe.
- Idempotency by `Idempotency-Key`: a second call with the same key returns the existing invoice without a new provider call. Mandatory behavior for Checkout retries.
- Before creating an invoice in Asaas, check if a reusable Asaas customer already exists by document or `externalReference`. Create only if not found. Persist the Asaas identifier for reuse.
- The provider must be enabled for the tenant before any API call. Reject with a business error and record audit of the attempt.
- Provider errors are returned to Checkout without exposing internal secrets or raw Asaas API payload.
- `externalReference` must contain the order identifier (`orderId`) — bidirectional traceability between Payments and ecommerce.
- Asaas validation failure (invalid data) marks the invoice as `FAILED`. Internal audit information preserved; external error is clean.

## Response Contract

The gateway must return to Checkout:

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 159.90,
  "currency": "BRL",
  "billingType": "PIX",
  "externalReference": "MS-100045"
}
```

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/create-invoice.feature`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-001
- Related OBCs: `prodops/artifacts/business/obcs/payment-confirmation.md`, `prodops/artifacts/business/obcs/cancel-invoice.md`
