# OBC - Credit Card Authorization And Confirmation

## Business Outcome

Magazine Siará can accept credit card payments through Payments API with clear
customer feedback, no direct dependency on Asaas contracts in Checkout, and
observable states for authorization, risk analysis, refusal, confirmation,
receipt and refund boundary.

## Downstream Scope (First Slice)

Hosted card entry only. Tokenized card, saved-card reuse and new-card
registration remain Upstream until token storage, PCI boundary, consent and
refund decisions are recorded.

## Observable Events

| Event | Meaning | Required dimensions |
| --- | --- | --- |
| `payment.card.hosted_invoice.created` | Hosted Asaas invoice/card entry was created. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `provider`, `correlationId` |
| `payment.card.saved.listed` | Saved card metadata was listed for Checkout. | `tenantId`, `userId`, `provider`, `cardsCount`, `correlationId` |
| `payment.card.saved.selected` | Checkout selected a saved card for payment. | `tenantId`, `userId`, `orderId`, `invoiceId`, `cardId`, `brand`, `last4` |
| `payment.card.token.registration_requested` | New card tokenization was requested. | `tenantId`, `userId`, `provider`, `correlationId`, `hasRemoteIp` |
| `payment.card.token.registered` | Provider token was created and safe metadata was stored. | `tenantId`, `userId`, `cardId`, `provider`, `brand`, `last4`, `expiryMonth`, `expiryYear` |
| `payment.card.authorization.requested` | Tokenized card payment was submitted to provider. | `tenantId`, `orderId`, `invoiceId`, `provider`, `correlationId`, `hasToken` |
| `payment.card.authorized` | Provider authorized card payment before final confirmation. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `providerStatus` |
| `payment.card.risk_analysis.awaiting` | Provider placed card payment under risk analysis. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |
| `payment.card.refused` | Card authorization or capture was refused. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `reasonCode` |
| `payment.confirmed` | Payment was confirmed and can release the order. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `confirmedAt` |
| `payment.card.refund.requested` | Refund/reversal was requested for confirmed card payment. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `amount`, `reason` |
| `payment.card.refund.required` | A confirmed card payment cannot be cancelled by delete and needs refund/reversal flow. | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |

## Initial SLIs

| SLI | Initial target |
| --- | --- |
| Card attempts with terminal known outcome: confirmed, refused, risk-analysis or provider error. | 99% in 5 minutes |
| Card confirmations published once to consumers after provider confirmation. | 99% in 30 seconds |
| Card capture refusals with known reason code or provider error code. | 99% |
| Webhook card events correlated by `providerPaymentId` or `externalReference`. | 99.5% |
| Saved-card operations rejected when tenant/user/card ownership does not match. | 100% |
| Card token, full number and CVV absent from application logs, traces and error payloads. | 100% |

## Reliability Rules

- Hosted card entry is the safest first Downstream slice because Payments API
  does not handle sensitive card data.
- Tokenized card payment can move Downstream only after `creditCardToken`,
  `remoteIp`, timeout, refusal and risk-analysis contracts are explicit.
- Cart/Checkout should use a Payments-owned `cardId` for saved cards. Provider
  tokens remain internal to Payments and must be resolved server-side.
- New-card registration can move Downstream only after Security approves raw
  card transit, token storage, log redaction and save-card consent.
- Direct raw card capture is out of scope for the first Downstream slice unless
  the product accepts PCI/security obligations.
- Confirmed card payment cancellation must be treated as refund or reversal, not
  as `DELETE /v3/payments`.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/credit-card-payment.feature`
- Upstream experiments: EXP-001, EXP-003
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
