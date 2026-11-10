# OBC - Chargeback Handling

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-62 |
| Iteração | v0.15.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-62 (#173) — v0.15.0, PR #176. Registro anterior: `Status: committed`, última atualização 2026-08-11.
**Pendência:** iteração concluída (PR #176); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-005](../business-signals/BS-005.md) |
| Business Intent | [PI-016](../business-intents/PI-016.md) |
| Product Tracking Item | issue #173 (DS-62), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

O sistema rastreia e publica os eventos de chargeback recebidos do PSP Asaas, transitando o estado da invoice sem executar nenhuma ação financeira autônoma.

## Escopo

**Dentro do escopo**

- Receber, via webhook `POST /webhook/payments`, os eventos do PSP `PAYMENT_CHARGEBACK_REQUESTED`, `PAYMENT_CHARGEBACK_DISPUTE` e `PAYMENT_AWAITING_CHARGEBACK_REVERSAL`.
- Transitar o status da invoice e publicar o evento de domínio correspondente.

**Fora de escopo**

- Qualquer ação financeira autônoma: o sistema não executa reembolso, estorno nem congelamento (freeze) — apenas rastreia e publica o evento.

## Regras de Negócio

**Pré-condições**

- A invoice com o `paymentId` correspondente deve existir.
- O `billingType` da invoice deve ser `CREDIT_CARD`.

**Mapeamento PSP → Status → Evento**

| Evento do PSP (`event`) | InvoiceStatus | Evento de domínio emitido |
|---|---|---|
| `PAYMENT_CHARGEBACK_REQUESTED` | `CHARGEBACK_REQUESTED` | `payments.invoice.chargeback_requested` |
| `PAYMENT_CHARGEBACK_DISPUTE` | `CHARGEBACK_DISPUTE` | `payments.invoice.chargeback_disputed` |
| `PAYMENT_AWAITING_CHARGEBACK_REVERSAL` | `CHARGEBACK_REVERSAL_PENDING` | `payments.invoice.chargeback_reversal_pending` |

**Regras**

1. **Apenas CREDIT_CARD**: webhooks de chargeback para outros `billingType` são ignorados sem erro (no-op idempotente).
2. **Idempotência**: receber o mesmo evento duas vezes resulta em no-op se o `status` já é o esperado.
3. **Out-of-order aceito**: `CHARGEBACK_DISPUTE` pode chegar sem `CHARGEBACK_REQUESTED` anterior.
4. **Sem ação financeira**: o sistema apenas rastreia e publica o evento; nenhum reembolso, estorno ou freeze é executado automaticamente.

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/chargeback-handling.feature`; marcar após verificação.

- [ ] Chargeback solicitado pelo portador
- [ ] Chargeback entra em fase de disputa
- [ ] Aguardando reversão de chargeback
- [ ] Webhook de chargeback duplicado é tratado de forma idempotente
- [ ] Chargeback para billingType incorreto é ignorado
- [ ] CHARGEBACK_DISPUTE sem CHARGEBACK_REQUESTED anterior é aceito (out-of-order)

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Sem Service Deck — pendente. Candidato: [compra-com-cartao-de-credito](../product/context/service-decks/compra-com-cartao-de-credito.md) (a regra restringe a `CREDIT_CARD`) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.chargeback_requested` | Emitido | Transição para `CHARGEBACK_REQUESTED` bem-sucedida. — *substitui `payment.chargeback_requested`* | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` |
| `payments.invoice.chargeback_disputed` | Emitido | Transição para `CHARGEBACK_DISPUTE` bem-sucedida. — *substitui `payment.chargeback_dispute`* | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` |
| `payments.invoice.chargeback_reversal_pending` | Emitido | Transição para `CHARGEBACK_REVERSAL_PENDING` bem-sucedida. — *substitui `payment.chargeback_reversal_pending`* | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` |

> As dimensões acima são as que o código emite (`invoice.service.ts`, `handleChargebackEvent`). O template exige `correlationId` em todo evento e o payload atual **não o inclui** — pendência de decisão do dono do OBC (adicionar ao evento ou aceitar a exceção).

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Eventos publicados dentro de 5s após o webhook recebido | 99,9% | [apurar] |
| Idempotência mantida em webhooks duplicados | 100% | [apurar] |

## Reliability Rules

- Idempotência: receber o mesmo evento de chargeback mais de uma vez não altera o estado nem publica evento duplicado quando o `status` já é o esperado.
- Falha transiente: [apurar]
- Isolamento: webhooks de chargeback para `billingType` diferente de `CREDIT_CARD` são ignorados sem erro, antes de qualquer alteração de estado.
- Auditoria: o sistema não executa nenhuma ação financeira; o log de aviso registra apenas `invoiceId`, status e `billingType`, sem segredos nem dados pessoais (verificado no trail da DS-62).

## APIs

| Método | Caminho | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/webhook/payments` | header `asaas-access-token` | Recebe os eventos do PSP, entre eles os três de chargeback |

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| RISK-CB-001 — Eventos de chargeback fora de ordem do PSP | [apurar] | `prodops/artifacts/risks/risks.md` |
| RISK-CB-002 — Ação manual de operação em chargebacks | [apurar] | `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço externo | Asaas (PSP) | Origem dos webhooks de chargeback; crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: estrutura reorganizada nas seções do template (conteúdo preservado), Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/chargeback-handling.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-CB-001, RISK-CB-002)
- GitHub Issue: #173
