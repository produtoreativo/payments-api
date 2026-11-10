# OBC - Credit Card Authorization And Confirmation

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-41 |
| Iteração | v0.5.0 (retrabalho em v0.6.0) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-41 (#41) — v0.5.0 (retrabalho em v0.6.0), PR #104. Registro anterior: Downstream. Status `In` in `prodops/artifacts/plans/iteration-plan.md` (section "Recommended Iteration Plan"). Approved 2026-07-07 — EXP-003 + EXP-001 validated the hosted slice approach. Ready for Bootstrap + Hack.
**Pendência:** iteração concluída (PR #104); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [#56](https://github.com/produtoreativa/payments-api/issues/56) |
| Business Intent | [PI-009](../business-intents/PI-009.md) |
| Product Tracking Item | issue #41 (DS-41), ver `prodops/artifacts/plans/iteration-plan.md` |
| Experimento | [EXP-001](../experiments/001-credit-card-lifecycle/experiment.md) · [EXP-003](../experiments/003-hosted-vs-tokenized/experiment.md) |
| Relacionado | [PI-PILOT-002](../business-intents/PI-PILOT-002.md) |

## Business Outcome

Magazine Siará can accept credit card payments through Payments API with clear
customer feedback, no direct dependency on Asaas contracts in Checkout, and
observable states for authorization, risk analysis, refusal, confirmation,
receipt and refund boundary.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/credit-card-authorization-confirmation.feature`; marcar após verificação.

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

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-cartao-de-credito](../product/context/service-decks/compra-com-cartao-de-credito.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payment.card.hosted_invoice.created` | Emitido | Hosted Asaas invoice/card entry was created. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `provider`, `correlationId` |
| `payment.card.saved.listed` | Planejado | Saved card metadata was listed for Checkout. | `tenantId`, `userId`, `provider`, `cardsCount`, `correlationId` |
| `payment.card.saved.selected` | Planejado | Checkout selected a saved card for payment. | `tenantId`, `userId`, `orderId`, `invoiceId`, `cardId`, `brand`, `last4` |
| `payment.card.token.registration_requested` | Planejado | New card tokenization was requested. | `tenantId`, `userId`, `provider`, `correlationId`, `hasRemoteIp` |
| `payment.card.token.registered` | Planejado | Provider token was created and safe metadata was stored. | `tenantId`, `userId`, `cardId`, `provider`, `brand`, `last4`, `expiryMonth`, `expiryYear` |
| `payment.card.authorization.requested` | Planejado | Tokenized card payment was submitted to provider. | `tenantId`, `orderId`, `invoiceId`, `provider`, `correlationId`, `hasToken` |
| `payment.card.authorized` | Planejado | Provider authorized card payment before final confirmation. — *equivalente provável no código (a confirmar): `pagamento.cartao.webhook.pagamento.autorizado`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `providerStatus` |
| `payment.card.risk_analysis.awaiting` | Planejado | Provider placed card payment under risk analysis. — *equivalente provável no código (a confirmar): `pagamento.cartao.webhook.analise_risco.aguardando`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |
| `payment.card.refused` | Planejado | Card authorization or capture was refused. — *equivalente provável no código (a confirmar): `pagamento.cartao.webhook.captura_recusada`* | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `reasonCode` |
| `payment.confirmed` | Emitido | Payment was confirmed and can release the order. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `confirmedAt` |
| `payment.card.refund.requested` | Emitido | Refund/reversal was requested for confirmed card payment. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `amount`, `reason` |
| `payment.card.refund.required` | Planejado | A confirmed card payment cannot be cancelled by delete and needs refund/reversal flow. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Card attempts with terminal known outcome: confirmed, refused, risk-analysis or provider error. | 99% in 5 minutes | [apurar] |
| Card confirmations published once to consumers after provider confirmation. | 99% in 30 seconds | [apurar] |
| Card capture refusals with known reason code or provider error code. | 99% | [apurar] |
| Webhook card events correlated by `providerPaymentId` or `externalReference`. | 99.5% | [apurar] |
| Saved-card operations rejected when tenant/user/card ownership does not match. | 100% | [apurar] |
| Card token, full number and CVV absent from application logs, traces and error payloads. | 100% | [apurar] |

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

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço externo | Asaas (PSP) | Crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/credit-card-authorization-confirmation.feature`
- Upstream experiments: EXP-001, EXP-003
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-cartao-de-credito.md`
