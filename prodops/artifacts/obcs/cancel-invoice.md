# OBC - Cancelar Invoice via Gateway

## Status

Committed. Adiado para próxima iteração — ver `prodops/artifacts/plans/iteration-plan.md` (decisão "Adiada"). OBC committed; disponível para Bootstrap + Hack na iteração seguinte.

## Business Outcome

O ecommerce Magazine Siará consegue cancelar uma invoice pendente via gateway de Payments sem acoplamento direto ao provedor Asaas. O cancelamento garante idempotência por chave de pedido, impede cancelamento após confirmação de pagamento e publica o evento canônico `payment.cancelled` apenas quando o cancelamento está efetivamente confirmado. Divergências do provedor (404, timeout) são tratadas com decisão operacional explícita — sem publicação de evento sem confirmação.

### Em linguagem executiva

Um cancelamento só é considerado concluído quando o Asaas confirma que removeu a cobrança do sistema dele. Enquanto essa confirmação não chega, a cobrança está "em processo de cancelamento" — não cancelada.

Três regras de negócio protegem o Magazine Siará:

**1. Cobrança paga não pode ser cancelada.** Se o cliente já pagou, a operação correta é um estorno — não um cancelamento. O gateway bloqueia a tentativa de cancelar uma cobrança confirmada antes de fazer qualquer chamada ao Asaas.

**2. Cancelar duas vezes não cancela duas vezes.** Se o Checkout enviar a mesma solicitação de cancelamento mais de uma vez (retentativa por timeout, por exemplo), o gateway reconhece que já processou aquele pedido e devolve o status atual sem chamar o Asaas novamente.

**3. "Não encontrei" não é cancelamento.** Se o Asaas responder que não reconhece aquela cobrança, o gateway não declara o cancelamento automaticamente — o caso fica marcado para investigação da equipe de operações. Nenhum pedido é alterado sem certeza.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `payment.cancelled` | Invoice cancelada com confirmação — cobrança removida do provedor. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `cancelledAt`, `correlationId` |
| `invoice.cancel_requested` | Cancelamento iniciado — invoice em `CANCEL_REQUESTED`, chamada ao provedor pendente. | `invoiceId`, `orderId`, `tenantId`, `provider`, `correlationId` |
| `invoice.cancel_rejected` | Cancelamento rejeitado por regra de negócio — invoice em estado não cancelável (ex.: `CONFIRMED`). | `invoiceId`, `tenantId`, `currentStatus`, `correlationId` |
| `invoice.cancel_idempotency_hit` | Retentativa de cancelamento com mesma chave — invoice já cancelada retornada sem nova chamada. | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.cancel_provider_not_found` | Provedor retornou 404 — invoice aguarda decisão de conciliação operacional. | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |
| `webhook.payment_deleted` | Webhook `PAYMENT_DELETED` do provedor confirma cancelamento para `CANCEL_REQUESTED`. | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Invoices com status `CONFIRMED` rejeitadas ao cancelamento sem chamada ao provedor. | 100% |
| Retentativas com mesma `Idempotency-Key` retornam `CANCELLED` sem nova chamada ao provedor. | 100% |
| `payment.cancelled` não publicado sem confirmação de remoção ou decisão explícita de conciliação. | 100% |
| `payment.cancelled` não duplicado quando webhook `PAYMENT_DELETED` chegar após publicação no comando. | 100% |
| Invoice em `CANCEL_REQUESTED` transitada para `CANCELLED` ao receber webhook `PAYMENT_DELETED`. | 99.9% |

## Reliability Rules

- Invoice com status `CONFIRMED` não pode ser cancelada. Cancelamento após confirmação exige fluxo de estorno separado. O gateway rejeita a operação com erro de negócio claro sem chamar o provedor.
- Idempotência por `Idempotency-Key`: segunda chamada de cancelamento com a mesma chave retorna o status atual sem nova chamada ao Asaas.
- `payment.cancelled` é publicado exatamente uma vez. Se o evento foi publicado no comando de cancelamento, o webhook `PAYMENT_DELETED` confirma o estado mas não republica o evento canônico.
- Provedor retornando 404 ao cancelar não é tratado como cancelamento confirmado. A invoice entra em estado de investigação operacional; `payment.cancelled` não é publicado sem decisão explícita.
- O comando de cancelamento atualiza a invoice para `CANCEL_REQUESTED` antes de chamar o provedor — estado intermediário auditável, seguro para retry.
- Invoice com status final `CANCELLED` confirmado apenas quando: (a) provedor confirma a remoção no retorno do comando, ou (b) webhook `PAYMENT_DELETED` é recebido.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/cancel-invoice.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` (decisão: Adiada)
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-003
- OBCs relacionados: `prodops/artifacts/obcs/create-invoice.md`, `prodops/artifacts/obcs/payment-confirmation.md`
