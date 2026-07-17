# Intent — Support for Multiple Payments at Checkout

## Identification

Field	Content
Title	Support for Multiple Payments at Checkout
Registration date	2026-07-07
Requester	Product Team
Product owner	

⸻

## Intention

We want buyers to be able to complete an order using more than one payment method when a single method does not meet their need, increasing the conversion rate and reducing checkout abandonment.

⸻

## Context

The current model assumes that an order is paid using only one payment method. This model limits common business scenarios, such as combining different payment methods to complete a purchase.

Beyond the functional limitation, the evolution of the payments ecosystem indicates the need to support new composition strategies between payment methods without increasing the complexity of the user experience.

This intention seeks to evaluate how to make checkout flexible for multiple payments while preserving operational simplicity, scalability, and compatibility with future payment methods.

⸻

## Business hypotheses

- [ ] Some customers abandon purchases because they cannot use more than one payment method.
- [ ] Allowing multiple payments will increase the checkout conversion rate.
- [ ] The experience can remain simple even while supporting different payment compositions.
- [ ] The model can be extended to new payment methods without requiring major architectural changes.
- [ ] Payment flexibility will be most valuable for higher-value orders.



## Open questions

- [x] * Which business scenarios justify the use of multiple payments? → Pix + Card (insufficient limit); gift card/cashback + primary method
- [x] * Which combinations of payment methods should be supported initially? → Pix + Card (P0 MVP); Card + Card (P1 post-MVP); Boleto as partial method outside MVP
- [x] * Is there a maximum number of payments per order? → 2 methods in MVP
- [x] * How to represent the remaining balance during payment composition? → `remainingAmount` derived; `confirmedAmount` persisted in `PaymentComposition`
- [x] * How should modification or removal of a payment before confirmation work? → Cancel invoice at Asaas if `OPEN`; new invoice for the replacement method
- [ ] ⚠ * How to handle partial failures when only one of the payments is authorized? → **Pending product decision** — Policy B recommended (keep confirmed, retry)
- [x] * How to reconcile asynchronous confirmations from different gateways? → Aggregation in `PaymentCompositionService` with `allInvoicesConfirmed()` in webhook processing
- [x] * How to preserve a simple user experience throughout the flow? → `compositionId` as primary reference; aggregated state via `GET /v1/payment-compositions/:id`
- [x] * What impacts does this change bring to the current Order and Payment model? → Additive change: `compositionId?` and `allocatedAmount?` in `InvoiceRecord`; new entity `PaymentComposition`
- [x] * Which business events should exist to support observability and auditing? → 7 new events: `ComposicaoDePagamentoCriada`, `PagamentoParcialConfirmado`, `PagamentoCompostoConfirmado`, `PagamentoParcialFalhou`, `PagamentoCompostoFalhou`, `PagamentoCompostoExpirou`, `ComposicaoCancelada`

⸻

## Suggested execution mode

- [x] * Upstream — there is sufficient uncertainty to explore before committing
- [ ] * Downstream — there is sufficient clarity; OBC and BDD can be written now

### Rationale:

Although the business need is clear, there are still important decisions related to the domain model, user experience, architecture, business events, payment gateway integrations, and observability strategy. These uncertainties justify an exploration phase before implementation.

⸻

## Next step

Execute an activity in Upstream (exploratory) mode to:

* research market benchmarks for checkouts with multiple payments;
* identify consolidated UX patterns;
* model domain alternatives;
* conduct Event Storming of the new flow;
* draft a candidate OBC;
* evaluate impacts on the existing architecture;
* decide the model that will proceed to implementation.

⸻

## Generated artifacts

| Artifact | Location |
|---|---|
| Experiment EXP-007 (full analysis) | `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md` |
| Experiment trail | `prodops/journeys/discovery/experiments/007-split-payment-model/upstream-trail.md` |
| Candidate OBC (draft) | `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md` |
| BDD Feature | `prodops/artifacts/business/bdd/payment-composition.feature` — **to be created after policy decision** |
