# Domain Events

## Eventos no contexto Payments

| Evento | Gatilho | Consumidores downstream |
|--------|---------|------------------------|
| `payments.invoice.created` | Fatura salva após criação | Observabilidade, Order Management |
| `payments.invoice.opened` | Cobrança criada no provedor | Observabilidade |
| `payments.invoice.confirmed` | Webhook `PAYMENT_CONFIRMED` processado | Notificação, Order fulfillment |
| `payments.invoice.cancelled` | Cancelamento aplicado | Notificação, Order reversal |
| `payments.invoice.provider_failed` | Falha na criação no provedor | Alertas, retry |
| `payments.customer.provider_linked` | Customer vinculado ao Asaas | Observabilidade |

Eventos nomeados em `domínio.contexto.ação` com verbo no passado.

## Convenção de nome

Formato: `payments.<entidade>.<verbo-passado>`

- `payments.invoice.created` — não `invoice_created` nem `InvoiceCreated`
- `payments.invoice.confirmed` — não `payment.approved`

O `EventEmitter2` está configurado com `wildcard: true` e `delimiter: '.'` no
`AppModule` — permite `payments.**` para escutar todos os eventos de pagamento.

## Emitindo eventos com EventEmitter2

```typescript
// application/invoice.service.ts — confirmação via webhook
this.eventEmitter.emit('payments.invoice.confirmed', {
  invoiceId: confirmedInvoice.invoiceId,
  orderId: confirmedInvoice.orderId,
  tenantId: confirmedInvoice.tenantId,
  amount: confirmedInvoice.amount,
  currency: confirmedInvoice.currency,
  provider: confirmedInvoice.provider,
  providerPaymentId: confirmedInvoice.providerPaymentId,
  confirmedAt: payload.payment?.confirmedDate ?? confirmedInvoice.updatedAt,
  timestamp: confirmedInvoice.updatedAt,
});
```

## Consumindo eventos com @OnEvent

```typescript
// application/handlers/invoice-confirmed.handler.ts
@Injectable()
export class InvoiceConfirmedHandler {
  @OnEvent('payments.invoice.confirmed')
  async handle(payload: InvoiceConfirmedPayload): Promise<void> {
    // ex: publicar na fila SQS para processamento downstream
    await this.sqsPublisher.publish('invoice-events', payload);
  }
}
```

## Tipo do evento

```typescript
// types/invoice-events.types.ts
export interface InvoiceConfirmedPayload {
  invoiceId: string;
  orderId: string;
  tenantId: string;
  amount: number;
  currency: string;
  provider: string;
  providerPaymentId: string;
  confirmedAt: string;
  timestamp: string;
}
```

**Incluir:** `invoiceId`, `tenantId`, `orderId`, `timestamp`.
**Excluir:** dados sensíveis (número de cartão, CVV), payloads brutos do provedor.

## Relação com Event Storming

- **Command** → **Event**: `ConfirmInvoice` (webhook) → `payments.invoice.confirmed`
- **Trigger**: webhook do Asaas dispara o comando
- **Reação**: handler encaminha para SQS; contexto de Notificação consome

Cada evento deve corresponder a uma entrada no plano de observabilidade (`plan.json`).
