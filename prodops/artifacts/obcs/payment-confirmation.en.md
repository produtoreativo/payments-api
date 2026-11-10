# OBC - Payment Confirmation via Webhook

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-39 |
| Iteration | v0.5.0 (retrabalho em v0.6.0) |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-39 (#39) — v0.5.0 (retrabalho em v0.6.0), PR #100. Previous record: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan").
**Pending:** iteration completed (PR #100); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-005](../business-intents/PI-005.md) |
| Product Tracking Item | issue #39 (DS-39), see `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-002 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |
| Related | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) |

## Business Outcome

Magazine Siará ecommerce receives reliable payment confirmation and releases the order exactly once, even when the provider webhook arrives duplicated, delayed, or before the internal invoice consolidation. The canonical event `payment.confirmed` is published only after authentication token validation and correlation with the correct invoice. Raw provider events are always persisted for audit, regardless of processing outcome.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/payment-confirmation.feature`; tick after verification.

- [ ] Confirmar pagamento com evento PAYMENT_CONFIRMED
- [ ] Conciliar recebimento financeiro com evento PAYMENT_RECEIVED
- [ ] Rejeitar webhook com token invalido
- [ ] Processar webhook duplicado sem efeito colateral
- [ ] Receber webhook antes da resposta da criacao da invoice
- [ ] Ignorar evento que nao libera pedido no MVP

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-pix](../product/context/service-decks/compra-com-pix.md), [compra-com-boleto](../product/context/service-decks/compra-com-boleto.md), [compra-com-cartao-de-credito](../product/context/service-decks/compra-com-cartao-de-credito.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `payment.confirmed` | Emitted | Payment approved — order can be released by ecommerce. Published exactly once. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.received` | Emitted | Financial settlement confirmed — for reconciliation. Does not release order a second time. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` |
| `webhook.received` | Planned | Raw provider event persisted before any processing. | `tenantId`, `provider`, `eventType`, `providerPaymentId`, `correlationId` |
| `webhook.rejected` | Planned | Webhook received with invalid token — rejected without state change. | `tenantId`, `provider`, `reason`, `correlationId` |
| `webhook.deduplicated` | Planned | Duplicate webhook recognized — technical success returned without reprocessing. | `invoiceId`, `tenantId`, `provider`, `eventType`, `correlationId` |
| `webhook.correlated_by_reference` | Planned | Event correlated by `externalReference` in the absence of internal `providerPaymentId`. | `invoiceId`, `orderId`, `tenantId`, `externalReference`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| `payment.confirmed` events published exactly once per approved payment. | 100% | [to be determined] |
| Webhooks with invalid token rejected without invoice state change. | 100% | [to be determined] |
| Duplicate webhooks return technical success without republishing `payment.confirmed`. | 100% | [to be determined] |
| `payment.received` event does not trigger a second order release. | 100% | [to be determined] |
| Asaas authentication token not exposed in logs or error responses. | 100% | [to be determined] |
| Raw events persisted before any processing. | 99.9% | [to be determined] |

## Reliability Rules

- The `payment.confirmed` event is published exactly once per `providerPaymentId`. Deduplication is mandatory: a second call recognizes the duplicate and returns technical success to the provider without republishing the canonical event.
- Every webhook request must carry a valid `asaas-access-token` header before any state read or change. An invalid request is rejected; no payload data is processed.
- Authentication token is never logged — neither on success nor on rejection. Log records only the validation result.
- A webhook received before internal invoice consolidation is correlated by `externalReference`. The gateway finds the correct invoice and completes confirmation without creating duplicates.
- `PAYMENT_RECEIVED` updates the invoice to `RECEIVED` and records for financial reconciliation, but does not publish a second `payment.confirmed` — the order was already released by `PAYMENT_CONFIRMED`.
- Events that do not release orders in the MVP (e.g.: `PAYMENT_OVERDUE`) are recorded and update operational state when applicable, but do not publish `payment.confirmed`.
- Raw provider event is persisted regardless of processing outcome — audit guarantee even in case of failure.

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

- BDD: `prodops/artifacts/bdd/payment-confirmation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-002
- Related OBCs: `prodops/artifacts/obcs/create-invoice.en.md`, `prodops/artifacts/obcs/webhook-configuration.en.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
