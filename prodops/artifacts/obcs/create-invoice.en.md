# OBC - Create Invoice via Gateway

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-38 |
| Iteration | v0.4.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-38 (#38) — v0.4.0, PR #89. Previous record: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan") — Pix journey as the first enabled billing type.
**Pending:** iteration completed (PR #89); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-003](../business-intents/PI-003.md) |
| Product Tracking Item | issue #38 (DS-38), see `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-001 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |
| Related | [PI-PILOT-001](../business-intents/PI-PILOT-001.md) |

## Business Outcome

Magazine Siará can create payment charges via the Payments gateway without direct coupling to the Asaas provider. The Checkout sends a single invoice contract; the gateway resolves the provider, creates or reuses the Asaas customer, guarantees idempotency by order key, and returns traceable identifiers. The invoice reaches `OPEN` status only when the `providerPaymentId` is consolidated — never before. Validation errors are auditable without exposing secrets or sensitive payloads.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/create-invoice.feature`; tick after verification.

- [ ] Criar invoice com sucesso no Asaas usando cliente ja vinculado
- [ ] Criar cliente Asaas antes da invoice quando nao houver vinculo
- [ ] Evitar duplicidade em retentativa do ecommerce
- [ ] Rejeitar provedor nao habilitado
- [ ] Falha transiente ao criar cobranca no provedor
- [ ] Falha de validacao retornada pelo provedor

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-pix](../product/context/service-decks/compra-com-pix.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.created` | Emitted | Invoice successfully created at the provider — status `OPEN`, `providerPaymentId` present. — *replaces `invoice.created`* | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `correlationId` |
| `payments.invoice.creation_failed` | Emitted | Failed to create invoice at the provider — invoice in `FAILED` or `PROVIDER_PENDING`. — *replaces `invoice.creation_failed`* | `invoiceId`, `orderId`, `tenantId`, `reason`, `provider`, `correlationId` |
| `payments.invoice.idempotency_hit` | Emitted | Retry with same idempotency key — existing invoice returned without a new charge. — *replaces `invoice.idempotency_hit`* | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `payments.invoice.provider_rejected` | Planned | Provider rejected creation due to invalid data — invoice marked as `FAILED`. — *replaces `invoice.provider_rejected`* | `invoiceId`, `orderId`, `tenantId`, `providerErrorCode`, `correlationId` |
| `payments.customer.provider_linked` | Emitted | Asaas customer created before invoice due to missing binding. — *replaces `invoice.customer_created`* | `tenantId`, `customerId`, `providerCustomerId`, `correlationId` |
| `payments.invoice.access_rejected` | Planned | Attempt to create invoice with a provider disabled for the tenant. — *replaces `invoice.access_rejected`* | `tenantId`, `provider`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Invoices created with `providerPaymentId` present in the response to Checkout. | 99.9% | [to be determined] |
| Retries with the same `Idempotency-Key` return the existing invoice without a new provider call. | 100% | [to be determined] |
| `OPEN` invoice never returned to Checkout without consolidated `providerPaymentId`. | 100% | [to be determined] |
| Provider validation errors returned without exposed secrets or sensitive payload. | 100% | [to be determined] |
| Requests with a provider disabled for the tenant rejected before calling the provider API. | 100% | [to be determined] |

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

## Risks

| Risk | Severity | Handling |
|---|---|---|
| [to be determined] | [to be determined] | see `prodops/artifacts/risks/risks.md` |

## Dependencies

| Type | Dependency | Note |
|---|---|---|
| Internal service | DynamoDB | Critical (Product Deck, section 4) |
| External service | Asaas (PSP) | Critical (Product Deck, section 4) |

## Decisions

| Date | Decision | Rationale | Source |
|---|---|---|---|
| 2026-11-10 | Migration to the `local-obc.en.md` template: sections added, Status normalized, events classified by Status and SLIs with Source. | Template adherence and the rule that the event name is the one emitted in the code. Fields without a source marked `[to be determined]`. | `obc` skill (`fix` mode); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/create-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-001
- Related OBCs: `prodops/artifacts/obcs/payment-confirmation.md`, `prodops/artifacts/obcs/cancel-invoice.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
