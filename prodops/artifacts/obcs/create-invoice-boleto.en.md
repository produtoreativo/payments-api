# OBC - Create Invoice via Boleto

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-40 |
| Iteration | v0.2.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-40 (#40) — v0.2.0, PR #87. Previous record: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan").
**Pending:** iteration completed (PR #87); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-004](../business-intents/PI-004.md) |
| Product Tracking Item | issue #40 (DS-40), see `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

Magazine Siará can issue charges via Boleto Bancário for orders where the customer opts for offline payment with a defined due date. Checkout now offers Boleto as a payment method via the Payments gateway, without direct coupling to the provider. The customer receives the boleto PDF link and the typed line for bank payment. The gateway guarantees idempotency and does not issue duplicate charges on Checkout retries.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/create-invoice-boleto.feature`; tick after verification.

- [ ] Criar boleto com sucesso para cliente já vinculado
- [ ] Criar cliente Asaas antes do boleto quando não houver vínculo
- [ ] Rejeitar boleto com data de vencimento no passado
- [ ] Rejeitar boleto sem data de vencimento
- [ ] Evitar duplicidade em retentativa do ecommerce
- [ ] Rejeitar provedor não habilitado
- [ ] Falha transiente ao criar boleto no provedor
- [ ] Falha de validação retornada pelo provedor

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-boleto](../product/context/service-decks/compra-com-boleto.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `payment.boleto.created` | Emitted | Boleto Invoice successfully created at the provider — bankSlipUrl available. | `invoiceId`, `orderId`, `tenantId`, `providerPaymentId`, `billingType`, `dueDate`, `correlationId` |
| `payment.boleto.creation_failed` | Emitted | Failed to create boleto at the provider — invoice remains in PROVIDER_PENDING or FAILED. | `invoiceId`, `orderId`, `tenantId`, `reason`, `correlationId` |
| `payment.boleto.idempotency_hit` | Emitted | Retry with the same idempotency key — existing invoice returned without a new charge. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Boleto Invoices created with `bankSlipUrl` present in the response. | 99.9% | [to be determined] |
| `dueDate` in the past rejected before calling the provider. | 100% | [to be determined] |
| Retries with the same `Idempotency-Key` return the existing invoice without a new charge. | 100% | [to be determined] |
| `bankSlipUrl` and `identificationField` do not appear in logs, traces or error responses. | 100% | [to be determined] |
| Invoice with status `OPEN` returned to Checkout after successful creation. | 100% | [to be determined] |

## Reliability Rules

- `dueDate` is mandatory and must be a future date (minimum D+1 relative to the time of the request). Requests with `dueDate` in the past or absent are rejected with `400` before calling the provider.
- The response to Checkout must include `bankSlipUrl` (boleto PDF link) and `identificationField` (typed line). If the provider does not return `bankSlipUrl`, the invoice is marked as `FAILED` and the error is observable.
- `bankSlipUrl` and `identificationField` must not be logged — they contain traceable billing data. Log only `invoiceId` and `providerPaymentId`.
- The invoice status remains `OPEN` after successful creation. Payment confirmation is asynchronous (provider webhook) and may occur days after issuance.
- Expired boleto (past due date without payment) must not be treated as an operational error — it is a natural state of the cycle. The `payment.boleto.expired` event must be observable when the provider webhook communicates the expiry.
- Idempotency: the same `Idempotency-Key` must return the existing invoice without a new provider call. Identical behavior to Pix.
- Transient provider failure (timeout, 5xx) does not alter idempotency behavior — the retry with the same key can be safely resent by Checkout.
- `billingType=BOLETO` in the creation payload is mandatory. The gateway must not infer the charge type.

## Response Contract

The gateway must return to Checkout:

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 250.00,
  "currency": "BRL",
  "billingType": "BOLETO",
  "dueDate": "2026-07-10",
  "bankSlipUrl": "https://sandbox.asaas.com/b/pdf/...",
  "identificationField": "34191.75402...",
  "externalReference": "MS-200010"
}
```

`bankSlipUrl` and `identificationField` are additional fields to the generic invoice contract — they need to be added to `InvoiceResponseDto` and `InvoiceRecord`.

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

- BDD: `prodops/artifacts/bdd/create-invoice-boleto.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBC: `prodops/artifacts/obcs/api-token-validation.md`
- Risks: `prodops/artifacts/risks/risks.md` — Boleto Risks section
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-boleto.md`
