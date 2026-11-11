# OBC - Boleto Auto-Cancellation

## Metadados

| Campo | Valor |
|---|---|
| Owner | Christiano Milfont (dono do sinal e Tech Lead) |
| DS-ID | DS-63 (entrega original) — a revisão ainda não tem DS-ID |
| Iteração | v0.15.0 (entrega original); revisão sem iteração atribuída |
| Última atualização | 2026-11-10 |

## Status

**Estado:** Refining
**Rastreado em:** DS-63 (#174) — v0.15.0, PR #177 (entrega original). Revisão do contrato em andamento na branch `feat/autocancelamento`, sem iteração atribuída. Registro anterior: `Status: committed`, última atualização 2026-08-11.
**Pendência:** o contrato foi reaberto para incluir o **webhook de boleto cancelado ao consumidor** (BS-006). Volta a `Committed` com a aprovação do Owner; a `Operational` depois da implementação e da confirmação em produção.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-006](../business-signals/BS-006.md) |
| Business Intent | [PI-017](../business-intents/PI-017.md) |
| Product Tracking Item | issue #174 (DS-63), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

O sistema cancela automaticamente boletos vencidos após 1 dia da data de vencimento, publica o evento de expiração e **entrega ao consumidor, por webhook, o evento de boleto cancelado**.

Quando uma invoice BOLETO recebe o evento `PAYMENT_OVERDUE`:

1. O status é transitado para `EXPIRED`.
2. O evento de domínio `payments.invoice.expired` é publicado.
3. Os webhooks ativos do tenant inscritos em `invoice.cancelled` recebem a notificação, com `reason: "BOLETO_OVERDUE"`.

## Escopo

**Dentro do escopo**

- Tratar o webhook `POST /webhook/payments` com `event = PAYMENT_OVERDUE` para invoice com `billingType = BOLETO`.
- Transitar a invoice para `EXPIRED` e publicar `payments.invoice.expired`.
- Entregar o webhook `invoice.cancelled` (mesmo tipo do cancelamento solicitado) com `reason: "BOLETO_OVERDUE"` aos webhooks do tenant inscritos nesse tipo.

**Fora de escopo**

- Invoices com `billingType` diferente de `BOLETO` (ignoradas sem erro).
- Invoices já `CONFIRMED` (o pagamento confirmado prevalece).
- Um novo tipo de webhook `invoice.expired` (alternativa avaliada e descartada; ver Decisões).
- Notificação por outros canais além do webhook.
- Alterar a política de entrega dos webhooks (timeout, assinatura, headers): segue a do `WebhookDeliveryService`.

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
2. **Idempotência**: receber `PAYMENT_OVERDUE` para um boleto já `EXPIRED` é no-op — sem novo evento e sem nova entrega de webhook.
3. **CONFIRMED imune**: se a invoice já está `CONFIRMED`, o webhook é ignorado — o pagamento confirmado prevalece, sem evento e sem webhook.
4. **Padrão de mercado**: `daysAfterDueDateToRegistrationCancellation=1` é o padrão Asaas para cancelamento automático.
5. **Webhook de boleto cancelado**: ao expirar o boleto, o consumidor recebe `invoice.cancelled` com `status: "EXPIRED"` e `reason: "BOLETO_OVERDUE"`, se o tenant tiver webhook ativo inscrito nesse tipo.
6. **Uma entrega por expiração**: o webhook é disparado apenas na transição para `EXPIRED`.
7. **Falha de entrega não desfaz a expiração**: a invoice permanece `EXPIRED` mesmo que o endpoint do consumidor falhe.

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/boleto-auto-cancellation.feature`; marcar após verificação.

- [ ] Boleto vencido é automaticamente expirado e o evento é publicado
- [ ] Boleto vencido entrega o webhook `invoice.cancelled` ao consumidor inscrito
- [ ] Consumidor não inscrito em `invoice.cancelled` não recebe o webhook
- [ ] Falha na entrega do webhook não desfaz a expiração
- [ ] Boleto criado com configuração de cancelamento automático
- [ ] Webhook PAYMENT_OVERDUE duplicado é tratado de forma idempotente (sem evento nem webhook duplicados)
- [ ] Boleto confirmado não é expirado e não gera evento nem webhook
- [ ] PAYMENT_OVERDUE para billingType incorreto é ignorado
- [ ] Valor padrão de daysAfterDueDateToRegistrationCancellation é aplicado

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | [compra-com-boleto](../product/context/service-decks/compra-com-boleto.md) (nó do serviço) e [configuracao-e-entrega-de-webhook](../product/context/service-decks/configuracao-e-entrega-de-webhook.md) (entrega do webhook) |
| Stakeholders | Christiano Milfont (dono do sinal e Tech Lead); consumidor do webhook — [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payments.invoice.expired` | Emitido | Transição para `EXPIRED` bem-sucedida (boleto vencido e cancelado automaticamente). Dispara o webhook `invoice.cancelled` ao consumidor. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `dueDate`, `expiredAt`, `correlationId` |

> **Divergência fechada em 2026-11-10** (branch `feat/autocancelamento`, ainda sem commit): `expireBoletoInvoice` passou a emitir `payments.invoice.expired` depois de persistir, via `emitAsync`, e o `WebhookDeliveryService` o entrega como `invoice.cancelled`. Cobertura: `api/test/boleto-auto-cancellation.e2e-spec.ts` (14 testes).

**Evento entregue ao consumidor (webhook)**

| Tipo externo | Disparado por | Campos do payload entregue |
|---|---|---|
| `invoice.cancelled` | `payments.invoice.expired` (novo) e `payments.invoice.cancelled` (existente, cancelamento solicitado) | `invoiceId`, `orderId`, `amount`, `currency`, `status`, `reason`, `billingType`, `dueDate`, `cancelledAt` |

Diferença entre as duas origens do mesmo tipo externo:

| | Cancelamento solicitado (existente) | Boleto vencido (novo) |
|---|---|---|
| `status` | `CANCELLED` | `EXPIRED` |
| `reason` | ausente hoje | `BOLETO_OVERDUE` |
| `billingType`, `dueDate` | ausentes hoje | presentes |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Eventos publicados dentro de 5s após o webhook recebido | 99,9% | [apurar] — não mensurável enquanto o evento não for emitido |
| Idempotência em webhooks duplicados (sem evento e sem webhook duplicados) | 100% | [apurar] |
| Boletos CONFIRMED nunca transitados para EXPIRED | 100% | [apurar] |
| Webhook `invoice.cancelled` entregue ao consumidor inscrito após a expiração | [apurar] | [apurar] |

## Reliability Rules

- Idempotência: `PAYMENT_OVERDUE` repetido para um boleto já `EXPIRED` é no-op e não publica evento nem entrega webhook em duplicidade.
- Falha transiente: a falha de entrega do webhook não reverte a expiração; a entrega segue a política existente do `WebhookDeliveryService` (timeout de 10 s). Política de nova tentativa: [apurar].
- Isolamento: webhooks para `billingType` diferente de `BOLETO`, ou para invoice já `CONFIRMED`, são ignorados sem erro e sem alterar o estado.
- Auditoria: a entrega ao consumidor é assinada (`X-Payments-Signature`) e identificada (`X-Payments-Delivery-Id`), como as demais; o payload não carrega segredos.

## APIs

| Método | Caminho | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/webhook/payments` | header `asaas-access-token` | Recebe os eventos do PSP, entre eles `PAYMENT_OVERDUE` |
| `POST` | URL do webhook do consumidor | assinatura HMAC (`X-Payments-Signature`) | Entrega `invoice.cancelled` quando o boleto expira |

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| RISK-BC-001 — Boleto pago após vencimento sem webhook de confirmação | [apurar] | `prodops/artifacts/risks/risks.md` |
| RISK-BC-002 — Webhook PAYMENT_OVERDUE para invoice já CONFIRMED | [apurar] | `prodops/artifacts/risks/risks.md` |
| RISK-BC-003 — Consumidor trata `invoice.cancelled` de boleto vencido como cancelamento solicitado | [apurar] | `reason` e `status: EXPIRED` no payload; validar com o consumidor; ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço interno | Webhooks do tenant (`WebhookDeliveryService`, `WebhooksTable`) | Entrega do `invoice.cancelled` ao consumidor |
| Serviço externo | Asaas (PSP) | Origem do webhook `PAYMENT_OVERDUE`; crítica (Product Deck, seção 4) |
| OBC | [`webhook-configuration`](./webhook-configuration.md) | Registro e entrega dos webhooks do consumidor |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: estrutura reorganizada nas seções do template (conteúdo preservado), Status normalizado, evento classificado como `Planejado` e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. | skill `obc` (modo `fix`); `check-obc.sh` |
| 2026-11-10 | Christiano Milfont é o dono do sinal (BS-006) e o Tech Lead que implementa. O consumidor precisa de um evento de boleto cancelado **como webhook**. | Define o dono e o requisito que reabrem o contrato. | Declaração do dono do sinal; `BS-006` |
| 2026-11-10 | O boleto vencido é entregue ao consumidor como `invoice.cancelled`, com `status: "EXPIRED"` e `reason: "BOLETO_OVERDUE"`. **A confirmar com o consumidor.** | Reaproveita o tipo que o consumidor já assina (`WebhookEventType` não muda) e o consumidor pediu um evento de "cancelado". `status` e `reason` mantêm a distinção entre cancelamento solicitado e vencimento. | `BS-006`; `WebhookDeliveryService` |
| 2026-11-10 | **Alternativa descartada:** novo tipo de webhook `invoice.expired`. | Exigiria novo valor em `WebhookEventType` e nova inscrição de cada consumidor; só vale se o consumidor precisar tratar a expiração de forma diferente do cancelamento. Reavaliar se a confirmação com o consumidor indicar isso. | `BS-006` |
| 2026-11-10 | O evento interno mantém o nome factual `payments.invoice.expired` (o fato é a expiração); o mapeamento para o webhook externo é n:1 (`payments.invoice.expired` e `payments.invoice.cancelled` → `invoice.cancelled`). | A convenção de eventos descreve o que aconteceu no domínio; o contrato externo é estável e menor. | Catálogo `domain-events.md` |
| 2026-11-10 | **H1:** o webhook reutiliza `invoice.cancelled`, com `status: EXPIRED` e `reason: BOLETO_OVERDUE` (campos aditivos). A confirmar com o consumidor (RISK-BC-003). | Contrato compatível: não exige novo tipo de inscrição. | Event Storming, H1 |
| 2026-11-10 | **H3:** a entrega do webhook de expiração é aguardada (`emitAsync`, listener sem `async: true`) antes de o processamento terminar; falha na entrega é registrada e não desfaz a expiração. | Comprovado que a entrega assíncrona terminava depois da resposta; no Lambda o worker poderia perdê-la. Custo: o processamento do `PAYMENT_OVERDUE` dura até o timeout do consumidor (10 s). | Event Storming, H3; e2e |
| 2026-11-10 | **H5:** pagamento confirmado depois da expiração continua aceito (`EXPIRED` → `CONFIRMED`). O consumidor deve tratar `invoice.confirmed` após `invoice.cancelled` de boleto vencido. | Dinheiro recebido não pode ser descartado; o contrato deve ser explícito sobre a sequência. A confirmar com Financeiro e o consumidor (RISK-BC-001). | Event Storming, H5 |
| 2026-11-10 | **H6:** nova tentativa e fila de falhas da entrega ficam **fora** desta entrega (uma tentativa, como nos demais webhooks). Registrar como evolução. | Escopo: vale para todos os tipos de webhook, não só para este. | Event Storming, H6 |
| 2026-11-10 | **Métricas do Datadog:** `invoice.expired`, `invoice.expiration_ignored` (tag `reason`: `confirmado`, `ja_expirado`, `billing_type`), `webhook.delivery.sent` e `webhook.delivery.failed` (tag `event`) passam a ser emitidas. `webhook.received` passa a ser contada **uma vez por webhook novo do PSP**, na entrada do processamento, com `event_type` = tipo do evento do PSP; `webhook.delivery.*` deixou de contar como `webhook.received`. | O dashboard precisa do caso principal (a expiração normal não era contada) e de métricas de entrega separadas. Efeito colateral: eventos de cartão passam a ser contados na entrada, não pela chave do observável. | `api/src/observability/metrics.ts`, `observability.listener.ts` |
| 2026-11-10 | **Verificação sem mocks:** as métricas são conferidas no Datadog real por `api/test/boleto-auto-cancellation.datadog.e2e-spec.ts` (`npm run test:e2e:datadog`), com `env` único por execução. O `dd-trace` se desativa dentro do Jest, então `metrics.ts` usa um socket DogStatsD direto quando o cliente é o noop. A ingestão leva ~5–10 min; o Datadog normaliza tags para minúsculas. | Teste que prova que o dado chega, não só que a função foi chamada. | spec datadog; BDD (cenários de observabilidade) |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/boleto-auto-cancellation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-BC-001, RISK-BC-002, RISK-BC-003)
- Catálogo de eventos: `prodops/artifacts/architecture/domain-events.md`
- Business Signal: `prodops/artifacts/business-signals/BS-006.md`
- Event Storming (proposta): `prodops/artifacts/event-storming/boleto-auto-cancellation.md`
- GitHub Issue: #174
