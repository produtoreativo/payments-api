# OBC - Confirmação de Pagamento por Webhook

## Status

Downstream. Status `Entrou` em `prodops/artifacts/plans/iteration-plan.md` (seção "Iteration Plan recomendado").

## Business Outcome

O ecommerce Magazine Siará recebe confirmação confiável de pagamento e libera o pedido exatamente uma vez, mesmo quando o webhook do provedor chega duplicado, atrasado ou antes da consolidação interna da invoice. O evento canônico `payment.confirmed` é publicado apenas após validação do token de autenticação e correlação com a invoice correta. Eventos brutos do provedor são sempre persistidos para auditoria, independente do resultado do processamento.

### Em linguagem executiva

Quando um cliente paga via Pix, o Asaas envia uma notificação automática ao gateway avisando que o pagamento foi realizado. O gateway precisa garantir três coisas:

**1. A notificação é legítima.** Qualquer sistema na internet poderia fingir ser o Asaas e enviar uma notificação falsa dizendo "esse pedido foi pago". O gateway verifica uma senha secreta em cada notificação antes de fazer qualquer coisa — notificação sem senha válida é descartada sem afetar nenhum pedido.

**2. O pedido é liberado exatamente uma vez.** O Asaas pode enviar a mesma notificação várias vezes (rede instável, retentativa automática). O gateway reconhece as duplicatas e ignora — o pedido é liberado na primeira notificação válida e só nela.

**3. Toda notificação é salva, mesmo as que falham.** Se algo der errado no processamento, o registro da notificação original ainda existe para auditoria e reprocessamento. Nenhuma confirmação de pagamento se perde sem rastro.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `payment.confirmed` | Pagamento aprovado — pedido pode ser liberado pelo ecommerce. Publicado exatamente uma vez. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.received` | Liquidação financeira confirmada — para conciliação. Não libera pedido pela segunda vez. | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` |
| `webhook.received` | Evento bruto do provedor persistido antes de qualquer processamento. | `tenantId`, `provider`, `eventType`, `providerPaymentId`, `correlationId` |
| `webhook.rejected` | Webhook recebido com token inválido — rejeitado sem alteração de estado. | `tenantId`, `provider`, `reason`, `correlationId` |
| `webhook.deduplicated` | Webhook duplicado reconhecido — sucesso técnico retornado sem reprocessamento. | `invoiceId`, `tenantId`, `provider`, `eventType`, `correlationId` |
| `webhook.correlated_by_reference` | Evento correlacionado por `externalReference` na ausência de `providerPaymentId` interno. | `invoiceId`, `orderId`, `tenantId`, `externalReference`, `correlationId` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Eventos `payment.confirmed` publicados exatamente uma vez por pagamento aprovado. | 100% |
| Webhooks com token inválido rejeitados sem alteração de invoice. | 100% |
| Webhooks duplicados retornam sucesso técnico sem republicar `payment.confirmed`. | 100% |
| Evento `payment.received` não dispara segunda liberação de pedido. | 100% |
| Token de autenticação Asaas não exposto em logs ou respostas de erro. | 100% |
| Eventos brutos persistidos antes de qualquer processamento. | 99.9% |

## Reliability Rules

- O evento `payment.confirmed` é publicado exatamente uma vez por `providerPaymentId`. Deduplicação obrigatória: segunda chamada reconhece a duplicidade e retorna sucesso técnico ao provedor sem republicar o evento canônico.
- Toda requisição de webhook deve ter o header `asaas-access-token` válido antes de qualquer leitura ou alteração de estado. Requisição inválida é rejeitada; nenhum dado do payload é processado.
- Token de autenticação nunca é logado — nem no sucesso nem na rejeição. Log registra apenas o resultado da validação.
- Webhook recebido antes da consolidação interna da invoice é correlacionado por `externalReference`. O gateway localiza a invoice correta e conclui a confirmação sem criar duplicidade.
- `PAYMENT_RECEIVED` atualiza a invoice para `RECEIVED` e registra para conciliação financeira, mas não publica um segundo `payment.confirmed` — o pedido já foi liberado pelo `PAYMENT_CONFIRMED`.
- Eventos que não liberam pedido no MVP (ex.: `PAYMENT_OVERDUE`) são registrados e atualizam estado operacional quando aplicável, mas não publicam `payment.confirmed`.
- Evento bruto do provedor é persistido independente do resultado do processamento — garantia de auditoria mesmo em caso de falha.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/payment-confirmation.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/backlogs/icebox-backlog.md` — PAY-ICE-002
- OBCs relacionados: `prodops/artifacts/obcs/create-invoice.md`, `prodops/artifacts/obcs/webhook-configuration.md`
