# OBC - Cancel Invoice via Gateway

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-51 |
| Iteration | v0.10.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-51 (#47) — v0.10.0, PR #125. Previous record: Committed. Deferred to next iteration — see `prodops/artifacts/plans/iteration-plan.md` (decision: "Deferred"). OBC committed; available for Bootstrap + Hack in the following iteration.
**Pending:** iteration completed (PR #125); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-006](../business-intents/PI-006.md) |
| Product Tracking Item | issue #47 (DS-51), see `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-003 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |

## Business Outcome

Magazine Siará ecommerce can cancel a pending invoice via the Payments gateway without direct coupling to the Asaas provider. The cancellation guarantees idempotency by order key, prevents cancellation after payment confirmation, and publishes the canonical event `payments.invoice.cancelled` only when cancellation is effectively confirmed. Provider divergences (404, timeout) are handled with an explicit operational decision — no event published without confirmation.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/cancel-invoice.feature`; tick after verification.

- [ ] Cancelar invoice aberta com sucesso no Asaas
- [ ] Cancelamento idempotente
- [ ] Impedir cancelamento apos pagamento confirmado
- [ ] Provedor informa que cobranca nao existe
- [ ] Webhook de remocao confirma cancelamento

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [cancelamento-de-invoice](../product/context/service-decks/cancelamento-de-invoice.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.cancelled` | Emitted | Invoice cancelled with confirmation — charge removed from provider. — *replaces `payment.cancelled`* | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `cancelledAt`, `correlationId` |
| `payments.invoice.cancel_requested` | Planned | Cancellation initiated — invoice in `CANCEL_REQUESTED`, provider call pending. — *replaces `invoice.cancel_requested`* | `invoiceId`, `orderId`, `tenantId`, `provider`, `correlationId` |
| `payments.invoice.cancel_rejected` | Planned | Cancellation rejected by business rule — invoice in non-cancellable state (e.g.: `CONFIRMED`). — *replaces `invoice.cancel_rejected`* | `invoiceId`, `tenantId`, `currentStatus`, `correlationId` |
| `payments.invoice.cancel_idempotency_hit` | Planned | Cancellation retry with same key — already cancelled invoice returned without new call. — *replaces `invoice.cancel_idempotency_hit`* | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `payments.invoice.cancel_provider_not_found` | Planned | Provider returned 404 — invoice awaiting operational reconciliation decision. — *replaces `invoice.cancel_provider_not_found`* | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |
| `payments.webhook.payment_deleted` | Planned | Provider `PAYMENT_DELETED` webhook confirms cancellation for `CANCEL_REQUESTED`. — *replaces `webhook.payment_deleted`* | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Invoices with `CONFIRMED` status rejected at cancellation without provider call. | 100% | [to be determined] |
| Retries with the same `Idempotency-Key` return `CANCELLED` without a new provider call. | 100% | [to be determined] |
| `payments.invoice.cancelled` not published without confirmed removal or explicit reconciliation decision. | 100% | [to be determined] |
| `payments.invoice.cancelled` not duplicated when `PAYMENT_DELETED` webhook arrives after command publication. | 100% | [to be determined] |
| Invoice in `CANCEL_REQUESTED` transitioned to `CANCELLED` upon receiving `PAYMENT_DELETED` webhook. | 99.9% | [to be determined] |

## Reliability Rules

- Invoice with `CONFIRMED` status cannot be cancelled. Post-confirmation cancellation requires a separate refund flow. The gateway rejects the operation with a clear business error without calling the provider.
- Idempotency by `Idempotency-Key`: a second cancellation call with the same key returns the current status without a new Asaas call.
- `payments.invoice.cancelled` is published exactly once. If the event was published in the cancellation command, the `PAYMENT_DELETED` webhook confirms the state but does not republish the canonical event.
- Provider returning 404 upon cancellation is not treated as confirmed cancellation. The invoice enters an operational investigation state; `payments.invoice.cancelled` is not published without an explicit decision.
- The cancellation command updates the invoice to `CANCEL_REQUESTED` before calling the provider — auditable intermediate state, safe for retry.
- Invoice with final `CANCELLED` status confirmed only when: (a) provider confirms removal in the command response, or (b) `PAYMENT_DELETED` webhook is received.

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

- BDD: `prodops/artifacts/bdd/cancel-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` (decision: Deferred)
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-003
- Related OBCs: `prodops/artifacts/obcs/create-invoice.en.md`, `prodops/artifacts/obcs/payment-confirmation.en.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/cancelamento-de-invoice.md`
