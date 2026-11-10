# OBC - Cancelar Invoice via Gateway

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-51 |
| Iteração | v0.10.0 |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-51 (#47) — v0.10.0, PR #125. Registro anterior: Committed. Adiado para próxima iteração — ver `prodops/artifacts/plans/iteration-plan.md` (decisão "Adiada"). OBC committed; disponível para Bootstrap + Hack na iteração seguinte.
**Pendência:** iteração concluída (PR #125); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-006](../business-intents/PI-006.md) |
| Product Tracking Item | issue #47 (DS-51), ver `prodops/artifacts/plans/iteration-plan.md` |
| Icebox | PAY-ICE-003 — [`icebox-backlog.md`](../product/backlogs/icebox-backlog.md) |

## Business Outcome

O ecommerce Magazine Siará consegue cancelar uma invoice pendente via gateway de Payments sem acoplamento direto ao provedor Asaas. O cancelamento garante idempotência por chave de pedido, impede cancelamento após confirmação de pagamento e publica o evento canônico `payment.cancelled` apenas quando o cancelamento está efetivamente confirmado. Divergências do provedor (404, timeout) são tratadas com decisão operacional explícita — sem publicação de evento sem confirmação.

### Em linguagem executiva

Um cancelamento só é considerado concluído quando o Asaas confirma que removeu a cobrança do sistema dele. Enquanto essa confirmação não chega, a cobrança está "em processo de cancelamento" — não cancelada.

Três regras de negócio protegem o Magazine Siará:

**1. Cobrança paga não pode ser cancelada.** Se o cliente já pagou, a operação correta é um estorno — não um cancelamento. O gateway bloqueia a tentativa de cancelar uma cobrança confirmada antes de fazer qualquer chamada ao Asaas.

**2. Cancelar duas vezes não cancela duas vezes.** Se o Checkout enviar a mesma solicitação de cancelamento mais de uma vez (retentativa por timeout, por exemplo), o gateway reconhece que já processou aquele pedido e devolve o status atual sem chamar o Asaas novamente.

**3. "Não encontrei" não é cancelamento.** Se o Asaas responder que não reconhece aquela cobrança, o gateway não declara o cancelamento automaticamente — o caso fica marcado para investigação da equipe de operações. Nenhum pedido é alterado sem certeza.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/cancel-invoice.feature`; marcar após verificação.

- [ ] Cancelar invoice aberta com sucesso no Asaas
- [ ] Cancelamento idempotente
- [ ] Impedir cancelamento apos pagamento confirmado
- [ ] Provedor informa que cobranca nao existe
- [ ] Webhook de remocao confirma cancelamento

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [cancelamento-de-invoice](../product/context/service-decks/cancelamento-de-invoice.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `payment.cancelled` | Emitido | Invoice cancelada com confirmação — cobrança removida do provedor. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `cancelledAt`, `correlationId` |
| `invoice.cancel_requested` | Planejado | Cancelamento iniciado — invoice em `CANCEL_REQUESTED`, chamada ao provedor pendente. — *equivalente provável no código (a confirmar): `pagamento.cancelamento.cobranca.cancelamento.solicitado`* | `invoiceId`, `orderId`, `tenantId`, `provider`, `correlationId` |
| `invoice.cancel_rejected` | Planejado | Cancelamento rejeitado por regra de negócio — invoice em estado não cancelável (ex.: `CONFIRMED`). | `invoiceId`, `tenantId`, `currentStatus`, `correlationId` |
| `invoice.cancel_idempotency_hit` | Planejado | Retentativa de cancelamento com mesma chave — invoice já cancelada retornada sem nova chamada. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.cancel_provider_not_found` | Planejado | Provedor retornou 404 — invoice aguarda decisão de conciliação operacional. — *equivalente provável no código (a confirmar): `pagamento.cancelamento.cobranca.conciliacao.requerida`* | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |
| `webhook.payment_deleted` | Planejado | Webhook `PAYMENT_DELETED` do provedor confirma cancelamento para `CANCEL_REQUESTED`. — *equivalente provável no código (a confirmar): `pagamento.cancelamento.webhook.cancelamento.confirmado`* | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Invoices com status `CONFIRMED` rejeitadas ao cancelamento sem chamada ao provedor. | 100% | [apurar] |
| Retentativas com mesma `Idempotency-Key` retornam `CANCELLED` sem nova chamada ao provedor. | 100% | [apurar] |
| `payment.cancelled` não publicado sem confirmação de remoção ou decisão explícita de conciliação. | 100% | [apurar] |
| `payment.cancelled` não duplicado quando webhook `PAYMENT_DELETED` chegar após publicação no comando. | 100% | [apurar] |
| Invoice em `CANCEL_REQUESTED` transitada para `CANCELLED` ao receber webhook `PAYMENT_DELETED`. | 99.9% | [apurar] |

## Reliability Rules

- Invoice com status `CONFIRMED` não pode ser cancelada. Cancelamento após confirmação exige fluxo de estorno separado. O gateway rejeita a operação com erro de negócio claro sem chamar o provedor.
- Idempotência por `Idempotency-Key`: segunda chamada de cancelamento com a mesma chave retorna o status atual sem nova chamada ao Asaas.
- `payment.cancelled` é publicado exatamente uma vez. Se o evento foi publicado no comando de cancelamento, o webhook `PAYMENT_DELETED` confirma o estado mas não republica o evento canônico.
- Provedor retornando 404 ao cancelar não é tratado como cancelamento confirmado. A invoice entra em estado de investigação operacional; `payment.cancelled` não é publicado sem decisão explícita.
- O comando de cancelamento atualiza a invoice para `CANCEL_REQUESTED` antes de chamar o provedor — estado intermediário auditável, seguro para retry.
- Invoice com status final `CANCELLED` confirmado apenas quando: (a) provedor confirma a remoção no retorno do comando, ou (b) webhook `PAYMENT_DELETED` é recebido.

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

- BDD: `prodops/artifacts/bdd/cancel-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` (decisão: Adiada)
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-003
- OBCs relacionados: `prodops/artifacts/obcs/create-invoice.md`, `prodops/artifacts/obcs/payment-confirmation.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/cancelamento-de-invoice.md`
