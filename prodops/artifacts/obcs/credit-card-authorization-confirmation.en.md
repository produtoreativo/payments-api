# OBC - Credit Card Authorization And Confirmation

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-41 |
| Iteration | v0.5.0 (retrabalho em v0.6.0) |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-41 (#41) — v0.5.0 (retrabalho em v0.6.0), PR #104. Previous record: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan"). Approved 2026-07-07 — EXP-003 + EXP-001 validated the hosted slice approach. Ready for Bootstrap + Hack.
**Pending:** iteration completed (PR #104); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [#56](https://github.com/produtoreativa/payments-api/issues/56) |
| Business Intent | [PI-009](../business-intents/PI-009.md) |
| Product Tracking Item | issue #41 (DS-41), see `prodops/artifacts/plans/iteration-plan.md` |
| Experiment | [EXP-001](../experiments/001-credit-card-lifecycle/experiment.md) · [EXP-003](../experiments/003-hosted-vs-tokenized/experiment.md) |
| Related | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) |

## Business Outcome

Magazine Siará can accept credit card payments through Payments API with clear
customer feedback, no direct dependency on Asaas contracts in Checkout, and
observable states for authorization, risk analysis, refusal, confirmation,
receipt and refund boundary.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/credit-card-authorization-confirmation.feature`; tick after verification.

- [ ] Criar cobranca de cartao com entrada hospedada no Asaas
- [ ] Confirmar pagamento de cartao hospedado por webhook
- [ ] Conciliar recebimento financeiro de cartao
- [ ] Criar cobranca de cartao tokenizado
- [ ] Listar cartoes cadastrados para o carrinho
- [ ] Impedir acesso a cartao salvo de outro usuario ou tenant
- [ ] Cadastrar novo cartao preservando fronteira PCI
- [ ] Pagar com cartao cadastrado
- [ ] Pagar com novo cartao sem armazenar dados sensiveis
- [ ] Mapear pagamento autorizado aguardando captura
- [ ] Mapear analise de risco aprovada
- [ ] Mapear analise de risco reprovada
- [ ] Mapear analise de risco manual
- [ ] Mapear recusa de captura
- [ ] Confirmar pagamento com cartao
- [ ] Simular pagamento aprovado na sandbox Asaas
- [ ] Simular pagamento recusado na sandbox ou no Validation Workbench
- [ ] Tratar estorno como fluxo diferente de cancelamento
- [ ] Solicitar estorno de pagamento confirmado
- [ ] Manter captura direta de cartao fora do primeiro slice

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-cartao-de-credito](../product/context/service-decks/compra-com-cartao-de-credito.md) |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.opened` | Emitted | Hosted Asaas invoice/card entry was created. — *duplicate eliminated (`payment.card.hosted_invoice.created`); now `payments.invoice.opened`, with `billingType` etc. in the payload* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `provider`, `correlationId` |
| `payments.card.saved_listed` | Planned | Saved card metadata was listed for Checkout. — *replaces `payment.card.saved.listed`* | `tenantId`, `userId`, `provider`, `cardsCount`, `correlationId` |
| `payments.card.saved_selected` | Planned | Checkout selected a saved card for payment. — *replaces `payment.card.saved.selected`* | `tenantId`, `userId`, `orderId`, `invoiceId`, `cardId`, `brand`, `last4` |
| `payments.card.token_registration_requested` | Planned | New card tokenization was requested. — *replaces `payment.card.token.registration_requested`* | `tenantId`, `userId`, `provider`, `correlationId`, `hasRemoteIp` |
| `payments.card.token_registered` | Planned | Provider token was created and safe metadata was stored. — *replaces `payment.card.token.registered`* | `tenantId`, `userId`, `cardId`, `provider`, `brand`, `last4`, `expiryMonth`, `expiryYear` |
| `payments.invoice.card_authorization_requested` | Planned | Tokenized card payment was submitted to provider. — *replaces `payment.card.authorization.requested`* | `tenantId`, `orderId`, `invoiceId`, `provider`, `correlationId`, `hasToken` |
| `payments.invoice.card_authorized` | Planned | Provider authorized card payment before final confirmation. — *replaces `payment.card.authorized`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `providerStatus` |
| `payments.invoice.card_risk_analysis_awaiting` | Planned | Provider placed card payment under risk analysis. — *replaces `payment.card.risk_analysis.awaiting`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |
| `payments.invoice.card_refused` | Planned | Card authorization or capture was refused. — *replaces `payment.card.refused`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `reasonCode` |
| `payments.invoice.confirmed` | Emitted | Payment was confirmed and can release the order. — *replaces `payment.confirmed`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `confirmedAt` |
| `payments.invoice.refund_requested` | Emitted | Refund/reversal was requested for confirmed card payment. — *replaces `payment.card.refund.requested`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `amount`, `reason` |
| `payments.invoice.refund_required` | Planned | A confirmed card payment cannot be cancelled by delete and needs refund/reversal flow. — *replaces `payment.card.refund.required`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Card attempts with terminal known outcome: confirmed, refused, risk-analysis or provider error. | 99% in 5 minutes | [to be determined] |
| Card confirmations published once to consumers after provider confirmation. | 99% in 30 seconds | [to be determined] |
| Card capture refusals with known reason code or provider error code. | 99% | [to be determined] |
| Webhook card events correlated by `providerPaymentId` or `externalReference`. | 99.5% | [to be determined] |
| Saved-card operations rejected when tenant/user/card ownership does not match. | 100% | [to be determined] |
| Card token, full number and CVV absent from application logs, traces and error payloads. | 100% | [to be determined] |

## Reliability Rules

- Hosted card entry is the safest first Downstream slice because Payments API
  does not handle sensitive card data.
- Tokenized card payment can move Downstream only after `creditCardToken`,
  `remoteIp`, timeout, refusal and risk-analysis contracts are explicit.
- Cart/Checkout should use a Payments-owned `cardId` for saved cards. Provider
  tokens remain internal to Payments and must be resolved server-side.
- New-card registration can move Downstream only after Security approves raw
  card transit, token storage, log redaction and save-card consent.
- Direct raw card capture is out of scope for the first Downstream slice unless
  the product accepts PCI/security obligations.
- Confirmed card payment cancellation must be treated as refund or reversal, not
  as `DELETE /v3/payments`.

## Downstream Scope (First Slice)

Hosted card entry only. Tokenized card, saved-card reuse and new-card
registration remain Upstream until token storage, PCI boundary, consent and
refund decisions are recorded.

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

- BDD: `prodops/artifacts/bdd/credit-card-authorization-confirmation.feature`
- Upstream experiments: EXP-001, EXP-003
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-cartao-de-credito.md`
