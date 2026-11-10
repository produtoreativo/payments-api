# OBC - Boleto Auto-Cancellation

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-63 |
| Iteração | v0.15.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-63 (#174) — v0.15.0, PR #177. Registro anterior: `Status: committed`, última atualização 2026-08-11.
**Pendência:** iteração concluída (PR #177); candidato a `Operational` — confirmar implantação em produção antes de promover. **Há uma divergência de contrato aberta:** o evento `payments.invoice.expired` não é emitido pelo código (ver Observable Events). Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-005](../business-signals/BS-005.md) |
| Business Intent | [PI-017](../business-intents/PI-017.md) |
| Product Tracking Item | issue #174 (DS-63), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

O sistema cancela automaticamente boletos vencidos após 1 dia da data de vencimento, publicando o evento de expiração correspondente.

Quando uma invoice BOLETO recebe o evento `PAYMENT_OVERDUE`:

1. O status é transitado para `EXPIRED`.
2. O evento de domínio `payments.invoice.expired` é publicado para os consumidores.

## Escopo

**Dentro do escopo**

- Tratar o webhook `POST /webhook/payments` com `event = PAYMENT_OVERDUE` para invoice com `billingType = BOLETO`.
- Transitar a invoice para `EXPIRED` e publicar o evento de expiração.

**Fora de escopo**

- Invoices com `billingType` diferente de `BOLETO` (ignoradas sem erro).
- Invoices já `CONFIRMED` (o pagamento confirmado prevalece).

## Regras de Negócio

**Pré-condições**

- A invoice com o `paymentId` correspondente deve existir.
- O `billingType` da invoice deve ser `BOLETO`.
- A invoice não deve estar no status `CONFIRMED` (pagamentos confirmados são ignorados).

**Configuração**

| Campo | Valor padrão (mercado) |
|---|---|
| `daysAfterDueDateToRegistrationCancellation` | `1` — boleto cancelado 1 dia após o vencimento |

**Regras**

1. **Apenas BOLETO**: webhooks `PAYMENT_OVERDUE` para outros `billingType` são ignorados sem erro.
2. **Idempotência**: receber `PAYMENT_OVERDUE` para um boleto já `EXPIRED` é no-op.
3. **CONFIRMED imune**: se a invoice já está `CONFIRMED`, o webhook é ignorado — o pagamento confirmado prevalece.
4. **Padrão de mercado**: `daysAfterDueDateToRegistrationCancellation=1` é o padrão Asaas para cancelamento automático.

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/boleto-auto-cancellation.feature`; marcar após verificação.

- [ ] Boleto vencido é automaticamente expirado
- [ ] Boleto criado com configuração de cancelamento automático
- [ ] Webhook PAYMENT_OVERDUE duplicado é tratado de forma idempotente
- [ ] Boleto confirmado não é expirado
- [ ] PAYMENT_OVERDUE para billingType incorreto é ignorado
- [ ] Valor padrão de daysAfterDueDateToRegistrationCancellation é aplicado

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Sem Service Deck — pendente. Candidato: [compra-com-boleto](../product/context/service-decks/compra-com-boleto.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.expired` | Planejado | Transição para `EXPIRED` bem-sucedida. — *substitui `payment.boleto.expired`* | [apurar] |

> **Divergência de contrato (decisão do dono do OBC).** O código (`expireBoletoInvoice` em `invoice.service.ts`) transita a invoice para `EXPIRED` mas **não emite** `payments.invoice.expired`; o BDD (`boleto-auto-cancellation.feature`, linha 13) exige que o evento seja publicado e o teste e2e não verifica isso. Opções: (a) implementar a emissão do evento (item de Delivery) ou (b) remover a promessa do OBC e do BDD. Enquanto isso o evento fica `Planejado`, e o SLI de publicação em 5s não é mensurável.

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Eventos publicados dentro de 5s após o webhook recebido | 99,9% | [apurar] — não mensurável enquanto o evento não for emitido |
| Idempotência em webhooks duplicados | 100% | [apurar] |
| Boletos CONFIRMED nunca transitados para EXPIRED | 100% | [apurar] |

## Reliability Rules

- Idempotência: `PAYMENT_OVERDUE` repetido para um boleto já `EXPIRED` é no-op e não publica evento duplicado.
- Falha transiente: [apurar]
- Isolamento: webhooks para `billingType` diferente de `BOLETO`, ou para invoice já `CONFIRMED`, são ignorados sem erro e sem alterar o estado.
- Auditoria: [apurar]

## APIs

| Método | Caminho | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/webhook/payments` | header `asaas-access-token` | Recebe os eventos do PSP, entre eles `PAYMENT_OVERDUE` |

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| RISK-BC-001 — Boleto pago após vencimento sem webhook de confirmação | [apurar] | `prodops/artifacts/risks/risks.md` |
| RISK-BC-002 — Webhook PAYMENT_OVERDUE para invoice já CONFIRMED | [apurar] | `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço externo | Asaas (PSP) | Origem do webhook `PAYMENT_OVERDUE`; crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: estrutura reorganizada nas seções do template (conteúdo preservado), Status normalizado, evento classificado como `Planejado` e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. A divergência do evento `payments.invoice.expired` foi registrada, não resolvida. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/boleto-auto-cancellation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-BC-001, RISK-BC-002)
- GitHub Issue: #174
