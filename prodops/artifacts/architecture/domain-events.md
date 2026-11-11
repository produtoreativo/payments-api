# Catálogo de eventos de negócio — Payments

> **Fonte única no código:** [`api/src/events/payments-events.ts`](../../../api/src/events/payments-events.ts).
> Este catálogo documenta o que está lá. Em caso de divergência, **o código manda** e este documento deve ser corrigido.
> Atualizado em 2026-11-10.

## 1. Convenção de nomes

```
payments.<agregado>.<fato>
```

| Regra | Descrição | Exemplo |
|---|---|---|
| N1 | O prefixo `payments.` identifica o produto e é obrigatório em todo evento de negócio | `payments.invoice.confirmed` |
| N2 | Minúsculas, `snake_case`, em inglês, só ASCII | `payments.split_payment.pix_confirmed` |
| N3 | O **agregado** é o substantivo singular da raiz do domínio: `invoice`, `split_payment`, `customer`, `security` | |
| N4 | O **fato** descreve o que aconteceu, no passado ou como estado. Nunca imperativo nem intenção | `created`, `confirmed`, `refund_requested`, `chargeback_reversal_pending` |
| N5 | Falha é `<substantivo>_failed` | `payments.invoice.creation_failed` |
| N6 | O **meio de pagamento vai no payload** (`billingType`), não no nome, exceto quando o fato só existe para ele (no Split Payment: `pix_confirmed`, `boleto_expired`) | `payments.invoice.opened` com `billingType: BOLETO` |
| N7 | **Um fato, um nome.** Não se emite o mesmo fato sob dois nomes | ver seção 4 |
| N8 | Ortografia fixa: `cancelled` | `payments.invoice.cancelled` |
| N9 | O nome é um contrato. A versão do formato do payload é um campo, não parte do nome | |

**Fora desta convenção, de propósito:**

| O quê | Onde | Por quê |
|---|---|---|
| `payments.observability` e as chaves `event_key` (`pagamento.*`, `api.token.*`, `webhook.*`) | stream de observabilidade, ouvido por `ObservabilityListener` | Outra camada: alimenta métricas e dashboards do Datadog, não é fato de domínio |
| `payment.created`, `payment.failed`, `webhook.received`… | `api/src/observability/metrics.ts` | São **métricas** do Datadog, não eventos |
| `invoice.created`, `invoice.confirmed`, `invoice.cancelled` | tipos de evento entregues ao consumidor por webhook (`WebhookEventType`) | **Contrato externo**, sem o prefixo. O `WebhookDeliveryService` traduz `payments.invoice.confirmed` → `invoice.confirmed` e `payments.invoice.cancelled` → `invoice.cancelled` |

## 2. Eventos emitidos hoje (20)

| Evento | Quando | Campos do payload | Escutado por |
|---|---|---|---|
| `payments.invoice.created` | Invoice persistida, antes de falar com o provedor | `invoiceId`, `orderId`, `provider`, `status`, `timestamp` | — |
| `payments.invoice.opened` | Provedor registrou a cobrança; a invoice está **pagável** (qualquer meio) | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `status`, `billingType`, `dueDate`, `correlationId`, `timestamp` | — |
| `payments.invoice.creation_failed` | Falha ao criar a cobrança no provedor (qualquer meio) | `invoiceId`, `orderId`, `tenantId`, `provider`, `billingType`, `reason`, `correlationId`, `timestamp` | — |
| `payments.invoice.idempotency_hit` | Retentativa com a mesma chave de idempotência; a invoice existente é devolvida (hoje só para `BOLETO`) | `invoiceId`, `orderId`, `tenantId`, `correlationId` | — |
| `payments.invoice.confirmed` | Pagamento aprovado pelo provedor — libera o pedido | `invoiceId`, `orderId`, `tenantId`, `amount`, `currency`, `provider`, `providerPaymentId`, `confirmedAt`, `timestamp` | `WebhookDeliveryService` → webhook externo `invoice.confirmed` |
| `payments.invoice.expired` | Boleto vencido e cancelado automaticamente (`PAYMENT_OVERDUE`); a invoice passa para `EXPIRED` | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `billingType`, `amount`, `currency`, `dueDate`, `expiredAt`, `correlationId` | `WebhookDeliveryService` → webhook externo `invoice.cancelled` (`status: EXPIRED`) |
| `payments.invoice.received` | Liquidação financeira (conciliação); não libera o pedido de novo | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `receivedAt`, `correlationId` | — |
| `payments.invoice.cancelled` | Cancelamento confirmado | `invoiceId`, `orderId`, `tenantId`, `amount`, `currency`, `provider`, `providerPaymentId`, `cancelledAt`, `timestamp` | `WebhookDeliveryService` → webhook externo `invoice.cancelled` |
| `payments.invoice.refund_requested` | Refund de cartão solicitado | `invoiceId`, `orderId`, `tenantId`, `providerPaymentId`, `amount`, `reason`, `correlationId` | — |
| `payments.invoice.chargeback_requested` | Chargeback solicitado pelo portador (só `CREDIT_CARD`) | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.invoice.chargeback_disputed` | Chargeback em disputa | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.invoice.chargeback_reversal_pending` | Aguardando reversão do chargeback | `invoiceId`, `orderId`, `tenantId`, `amount`, `occurredAt` | — |
| `payments.customer.provider_linked` | Cliente vinculado ao provedor (criado ou reaproveitado) | `tenantId`, `customerId`, `provider`, `providerCustomerId`, `timestamp` | — |
| `payments.security.webhook_rejected` | Webhook do provedor rejeitado por token inválido | `provider`, `reason`, `timestamp` | — |
| `payments.split_payment.created` | Split Payment criado | `splitPaymentId`, `orderId`, `pixAmount`, `boletoAmount`, `totalAmount`, `correlationId` | — |
| `payments.split_payment.creation_failed` | Falha ao criar o Split Payment | `orderId`, `reason`, `correlationId` | — |
| `payments.split_payment.pix_confirmed` | Parte Pix confirmada | `splitPaymentId`, `orderId`, `pixInvoiceId`, `confirmedAt`, `correlationId` | — |
| `payments.split_payment.boleto_confirmed` | Parte Boleto confirmada | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `confirmedAt`, `correlationId` | — |
| `payments.split_payment.completed` | Pix e Boleto confirmados | `splitPaymentId`, `orderId`, `completedAt`, `correlationId` | — |
| `payments.split_payment.boleto_expired` | Boleto do Split expirou | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `expiredAt`, `pixStatus`, `correlationId` | — |

## 3. Mapeamento dos nomes antigos

| Nome antigo | Nome atual |
|---|---|
| `payments.invoice.provider_failed`, `payment.boleto.creation_failed` | `payments.invoice.creation_failed` |
| `payment.boleto.created`, `payment.card.hosted_invoice.created` | `payments.invoice.opened` |
| `payment.confirmed` + `payments.invoice.confirmed` | `payments.invoice.confirmed` |
| `payment.cancelled` + `payments.invoice.cancelled` | `payments.invoice.cancelled` |
| `payment.boleto.idempotency_hit` | `payments.invoice.idempotency_hit` |
| `payment.received` | `payments.invoice.received` |
| `payment.card.refund.requested` | `payments.invoice.refund_requested` |
| `payment.chargeback_requested`, `payment.chargeback_dispute`, `payment.chargeback_reversal_pending` | `payments.invoice.chargeback_requested`, `payments.invoice.chargeback_disputed`, `payments.invoice.chargeback_reversal_pending` |
| `split_payment.created` / `.creation_failed` / `.completed` | `payments.split_payment.created` / `.creation_failed` / `.completed` |
| `split_payment.pix.confirmed` / `.boleto.confirmed` / `.boleto.expired` | `payments.split_payment.pix_confirmed` / `.boleto_confirmed` / `.boleto_expired` |

## 4. Duplicatas eliminadas

Eram 24 nomes emitidos; **5 eram duplicatas** de outro evento e foram eliminadas. Restavam 19; hoje são 20, com `payments.invoice.expired`.

| # | Eliminado | Sobrevivente | Por que era duplicata |
|---|---|---|---|
| 1 | `payment.confirmed` | `payments.invoice.confirmed` | Mesmo fato, emitido na mesma linha, com o mesmo payload (o segundo só acrescentava `timestamp`) |
| 2 | `payment.cancelled` | `payments.invoice.cancelled` | Idem |
| 3 | `payment.boleto.creation_failed` | `payments.invoice.creation_failed` | Era a mesma falha de criação que `payments.invoice.provider_failed`, emitida em sequência (só para boleto, com `reason` no lugar de `message`) |
| 4 | `payment.boleto.created` | `payments.invoice.opened` | Eco por meio de pagamento do mesmo momento: a invoice ficou pagável. `dueDate` passou para o payload do sobrevivente |
| 5 | `payment.card.hosted_invoice.created` | `payments.invoice.opened` | Idem, para cartão. O meio de pagamento agora vem em `billingType` |

Consequências:
- Os consumidores (`WebhookDeliveryService`) escutam `payments.invoice.confirmed` e `payments.invoice.cancelled`; o webhook entregue ao cliente não mudou.
- Nenhum evento passou a ser emitido em duplicidade: há um teste que garante a emissão única e que nenhum nome antigo reaparece no código (`api/src/events/payments-events.spec.ts` e o spec de confirmação).

## 5. Eventos planejados

Nenhum no momento. Um evento prometido num OBC e ainda não emitido entra aqui como `Planejado`. O último a sair desta lista foi `payments.invoice.expired` (OBC [`boleto-auto-cancellation`](../obcs/boleto-auto-cancellation.md)); o fato é a expiração do boleto e o meio de pagamento vai em `billingType` (regra N6).

## 6. Do evento interno ao webhook entregue ao consumidor

O webhook que o consumidor recebe tem um tipo **externo**, estável e sem o prefixo `payments.`. Mais de um evento interno pode alimentar o mesmo tipo externo:

| Evento interno | Tipo externo entregue | Situação |
|---|---|---|
| `payments.invoice.confirmed` | `invoice.confirmed` | Emitido |
| `payments.invoice.cancelled` | `invoice.cancelled` (`status: CANCELLED`) | Emitido |
| `payments.invoice.expired` | `invoice.cancelled` (`status: EXPIRED`, `reason: BOLETO_OVERDUE`) | Emitido |

`invoice.created` é aceito na inscrição (`WebhookEventType`), mas nenhum evento interno o entrega hoje.

Decisão registrada em [`boleto-auto-cancellation`](../obcs/boleto-auto-cancellation.md): reutilizar `invoice.cancelled` em vez de criar `invoice.expired`, a confirmar com o consumidor (risco `RISK-BC-003`).

## 7. Pendências conhecidas (não tratadas nesta mudança)

- **Campo de tempo com 5 nomes:** `timestamp`, `occurredAt`, `receivedAt`, `confirmedAt`, `expiredAt`/`cancelledAt`/`completedAt`. A convenção de payload (envelope) ainda não foi definida.
- **`tenantId` e `correlationId` ausentes** em parte dos eventos (por exemplo `payments.invoice.created` e os de chargeback).
- **`payments.invoice.idempotency_hit`** só é emitido para `BOLETO`, embora o nome seja genérico.
- **Eventos prometidos nos OBCs e ainda não emitidos** aparecem como `Planejado`; seus nomes já seguem esta convenção.

## 8. Como acrescentar um evento

1. Escolha o nome pela convenção (seção 1) e confira se o fato já não existe (N7).
2. Acrescente a constante em `api/src/events/payments-events.ts` — é a única fonte de nomes.
3. Emita com `this.eventEmitter.emit(PaymentsEvent.<Nome>, payload)`; nunca com literal.
4. Escreva o teste que verifica a emissão (com o nome literal, para travar o contrato).
5. Registre o evento no OBC da capability (`Observable Events`, Situação `Emitido`) e neste catálogo.
