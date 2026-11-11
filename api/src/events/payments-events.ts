/**
 * Eventos de negócio do produto Payments — fonte única de nomes.
 *
 * Convenção: `payments.<agregado>.<fato>` — tudo em minúsculas, snake_case, em inglês.
 *  - o prefixo `payments.` identifica o produto;
 *  - o agregado é o substantivo singular da raiz do domínio (`invoice`, `split_payment`, `customer`);
 *  - o fato descreve o que aconteceu (passado ou estado); o meio de pagamento vai no payload
 *    (`billingType`), não no nome, exceto quando o fato só existe para ele.
 *
 * Catálogo, regras e a lista de duplicatas eliminadas:
 * `prodops/artifacts/architecture/domain-events.md`.
 *
 * Fora desta lista, e de propósito:
 *  - `payments.observability` — stream de observabilidade (chaves `event_key`), outra camada;
 *  - métricas do Datadog (`payment.created`, `webhook.received`…) — não são eventos;
 *  - tipos de evento entregues ao consumidor por webhook (`invoice.confirmed`, `invoice.cancelled`)
 *    — contrato externo, sem o prefixo `payments.`.
 */
export const PaymentsEvent = {
  // Invoice
  InvoiceCreated: 'payments.invoice.created',
  InvoiceOpened: 'payments.invoice.opened',
  InvoiceCreationFailed: 'payments.invoice.creation_failed',
  InvoiceIdempotencyHit: 'payments.invoice.idempotency_hit',
  InvoiceConfirmed: 'payments.invoice.confirmed',
  InvoiceExpired: 'payments.invoice.expired',
  InvoiceReceived: 'payments.invoice.received',
  InvoiceCancelled: 'payments.invoice.cancelled',
  InvoiceRefundRequested: 'payments.invoice.refund_requested',
  InvoiceChargebackRequested: 'payments.invoice.chargeback_requested',
  InvoiceChargebackDisputed: 'payments.invoice.chargeback_disputed',
  InvoiceChargebackReversalPending:
    'payments.invoice.chargeback_reversal_pending',

  // Customer
  CustomerProviderLinked: 'payments.customer.provider_linked',

  // Segurança
  SecurityWebhookRejected: 'payments.security.webhook_rejected',

  // Split Payment
  SplitPaymentCreated: 'payments.split_payment.created',
  SplitPaymentCreationFailed: 'payments.split_payment.creation_failed',
  SplitPaymentPixConfirmed: 'payments.split_payment.pix_confirmed',
  SplitPaymentBoletoConfirmed: 'payments.split_payment.boleto_confirmed',
  SplitPaymentCompleted: 'payments.split_payment.completed',
  SplitPaymentBoletoExpired: 'payments.split_payment.boleto_expired',
} as const;

export type PaymentsEventName =
  (typeof PaymentsEvent)[keyof typeof PaymentsEvent];
