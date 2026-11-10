# OBC - Confirmação de Pagamento por Webhook

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-39 |
| Iteração | v0.5.0 (retrabalho em v0.6.0) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-39 (#39) — v0.5.0 (retrabalho em v0.6.0), PR #100. Registro anterior: Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` (seção "Iteration Plan recomendado").
**Pendência:** iteração concluída (PR #100); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-005](../business-intents/PI-005.md) |
| Product Tracking Item | issue #39 (DS-39), ver `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-002 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |
| Relacionado | [PI-PILOT-003](../business-intents/PI-PILOT-003.md) |

## Business Outcome

O ecommerce Magazine Siará recebe confirmação confiável de pagamento e libera o pedido exatamente uma vez, mesmo quando o webhook do provedor chega duplicado, atrasado ou antes da consolidação interna da invoice. O evento canônico `payment.confirmed` é publicado apenas após validação do token de autenticação e correlação com a invoice correta. Eventos brutos do provedor são sempre persistidos para auditoria, independente do resultado do processamento.

### Em linguagem executiva

Quando um cliente paga via Pix, o Asaas envia uma notificação automática ao gateway avisando que o pagamento foi realizado. O gateway precisa garantir três coisas:

**1. A notificação é legítima.** Qualquer sistema na internet poderia fingir ser o Asaas e enviar uma notificação falsa dizendo "esse pedido foi pago". O gateway verifica uma senha secreta em cada notificação antes de fazer qualquer coisa — notificação sem senha válida é descartada sem afetar nenhum pedido.

**2. O pedido é liberado exatamente uma vez.** O Asaas pode enviar a mesma notificação várias vezes (rede instável, retentativa automática). O gateway reconhece as duplicatas e ignora — o pedido é liberado na primeira notificação válida e só nela.

**3. Toda notificação é salva, mesmo as que falham.** Se algo der errado no processamento, o registro da notificação original ainda existe para auditoria e reprocessamento. Nenhuma confirmação de pagamento se perde sem rastro.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/payment-confirmation.feature`; marcar após verificação.

- [ ] Confirmar pagamento com evento PAYMENT_CONFIRMED
- [ ] Conciliar recebimento financeiro com evento PAYMENT_RECEIVED
- [ ] Rejeitar webhook com token invalido
- [ ] Processar webhook duplicado sem efeito colateral
- [ ] Receber webhook antes da resposta da criacao da invoice
- [ ] Ignorar evento que nao libera pedido no MVP

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [compra-com-pix](../product/context/service-decks/compra-com-pix.md), [compra-com-boleto](../product/context/service-decks/compra-com-boleto.md), [compra-com-cartao-de-credito](../product/context/service-decks/compra-com-cartao-de-credito.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payment.confirmed` | Emitido | Pagamento aprovado — pedido pode ser liberado pelo ecommerce. Publicado exatamente uma vez. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.received` | Emitido | Liquidação financeira confirmada — para conciliação. Não libera pedido pela segunda vez. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` |
| `webhook.received` | Planejado | Evento bruto do provedor persistido antes de qualquer processamento. | `tenantId`, `provider`, `eventType`, `providerPaymentId`, `correlationId` |
| `webhook.rejected` | Planejado | Webhook recebido com token inválido — rejeitado sem alteração de estado. | `tenantId`, `provider`, `reason`, `correlationId` |
| `webhook.deduplicated` | Planejado | Webhook duplicado reconhecido — sucesso técnico retornado sem reprocessamento. | `invoiceId`, `tenantId`, `provider`, `eventType`, `correlationId` |
| `webhook.correlated_by_reference` | Planejado | Evento correlacionado por `externalReference` na ausência de `providerPaymentId` interno. | `invoiceId`, `orderId`, `tenantId`, `externalReference`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Eventos `payment.confirmed` publicados exatamente uma vez por pagamento aprovado. | 100% | [apurar] |
| Webhooks com token inválido rejeitados sem alteração de invoice. | 100% | [apurar] |
| Webhooks duplicados retornam sucesso técnico sem republicar `payment.confirmed`. | 100% | [apurar] |
| Evento `payment.received` não dispara segunda liberação de pedido. | 100% | [apurar] |
| Token de autenticação Asaas não exposto em logs ou respostas de erro. | 100% | [apurar] |
| Eventos brutos persistidos antes de qualquer processamento. | 99.9% | [apurar] |

## Reliability Rules

- O evento `payment.confirmed` é publicado exatamente uma vez por `providerPaymentId`. Deduplicação obrigatória: segunda chamada reconhece a duplicidade e retorna sucesso técnico ao provedor sem republicar o evento canônico.
- Toda requisição de webhook deve ter o header `asaas-access-token` válido antes de qualquer leitura ou alteração de estado. Requisição inválida é rejeitada; nenhum dado do payload é processado.
- Token de autenticação nunca é logado — nem no sucesso nem na rejeição. Log registra apenas o resultado da validação.
- Webhook recebido antes da consolidação interna da invoice é correlacionado por `externalReference`. O gateway localiza a invoice correta e conclui a confirmação sem criar duplicidade.
- `PAYMENT_RECEIVED` atualiza a invoice para `RECEIVED` e registra para conciliação financeira, mas não publica um segundo `payment.confirmed` — o pedido já foi liberado pelo `PAYMENT_CONFIRMED`.
- Eventos que não liberam pedido no MVP (ex.: `PAYMENT_OVERDUE`) são registrados e atualizam estado operacional quando aplicável, mas não publicam `payment.confirmed`.
- Evento bruto do provedor é persistido independente do resultado do processamento — garantia de auditoria mesmo em caso de falha.

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

- BDD: `prodops/artifacts/bdd/payment-confirmation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-002
- OBCs relacionados: `prodops/artifacts/obcs/create-invoice.md`, `prodops/artifacts/obcs/webhook-configuration.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
