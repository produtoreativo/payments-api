# Iteration Plan - Payments Release

> Document generated from `prodops/framework/journeys/assessment/reliability-plans/setup/iteration-plan.prompt.md`.
> Focus: business scope decision for the next iteration. This document does not replace the Reliability Plan.

## Executive Summary

The next iteration should prioritize the smallest set of features capable of putting the new payment journey in a position to generate value for Checkout without excessively increasing Release risk.

The recommended scope is to focus the Release on three business outcomes: create a Pix invoice, confirm payment, and inform the customer of payment status. Boleto should be split off so it does not compete with stabilizing the Pix journey. Invoice cancellation should be kept out of the main commitment for this iteration, despite already existing in the code, because it is not essential for validating the activation of the new gateway in Checkout.

The main decision is to reduce the batch: deliver a smaller, complete and understandable journey for the customer and the business, rather than including all payment methods and capabilities at the same time.

## Release Objectives

- Enable Checkout to consume the new Payments gateway in a controlled payment journey.
- Reduce Ecommerce coupling to the monolith and to direct provider integrations.
- Validate the new Payments domain as responsible for payment creation and confirmation.
- Ensure the customer receives reliable information about payment status.
- Reduce Release failure probability by limiting scope to the highest-immediate-value flow.

## Risks that influenced scope

| Risk | Business impact | Probability | Influence on scope |
| --- | --- | --- | --- |
| New gateway still disabled by Feature Flag due to a localized bug. | Very high: prevents Release activation and, per `prodops/artifacts/risks/risks.md`, there is a relevant contractual risk. | High | Reduce scope to the most important journey, avoiding parallel features that divert focus from activation. |
| Notification Service has had incidents affecting customer confirmation. | High: customer may pay and not receive reliable information. | High | Keep status notification inside the Release, but only as part of the main journey, not as a full communication platform. |
| Monolith decoupling increases complexity between teams and services. | High: integration failures may prevent the end-to-end experience. | High | Prefer one smaller complete journey over multiple incomplete journeys. |
| Pix and Boleto have different rules and expectations. | Medium/high: treating both as a simple variation can increase business error. | Medium | Split Boleto and do not commit the main Release to all payment method variations. |
| Payment confirmation is the critical point for order release and customer communication. | Very high: confirmed payment without Ecommerce reflection causes loss of trust and support tickets. | High | Confirmation enters as a mandatory part of the iteration. |
| Cancellation competes with payment states and refund flow. | Medium: important for operations, but less central for validating the initial Checkout activation. | Medium | Defer cancellation as a Release commitment, keeping it out of the smallest value scope. |
| Divergence between documents and code. | Medium: can generate incorrect alignment about what will be delivered. | High | Scope must be described by business capabilities, not by endpoint details or technical design. |

## Opportunities considered

| Opportunity | Impact | Urgency | Relevance for this iteration | Influence on scope |
| --- | --- | --- | --- | --- |
| Validate Payments as an autonomous Ecommerce domain. | High | High | High | Prioritizes features that prove the end-to-end payment cycle, not just isolated endpoints. |
| Create business visibility over the payment journey. | High | High | Medium | Reinforces the choice of a smaller and business-measurable journey, without expanding functional scope. |
| Reduce direct provider dependency. | High | High | High | Prioritizes creation and confirmation via Payments gateway. |
| Increase customer confidence in payment confirmation. | High | High | High | Keeps status notification inside the main scope. |
| Accelerate additional payment methods. | Medium/high | Medium | Medium | Justifies preparing Boleto, but not including the full journey if that reduces predictability. |
| Integrate Payments into the corporate incident model. | Medium | Medium | Low for scope decision | Does not change the iteration's features; should be handled in its own reliability artifact. |

## Identified Iteration Backlog

| Feature | Expected value | Dependencies | Current state |
| --- | --- | --- | --- |
| Create invoice via Pix | Allows Checkout to initiate the highest-priority payment journey for the Release. | Checkout, Payments, Asaas provider, Feature Flag. | OBC at `prodops/artifacts/business/obcs/create-invoice.en.md`. BDD Feature at `prodops/artifacts/business/bdd/create-invoice.feature`. Partially implemented in code. |
| Create invoice via Credit Card (Hosted) | Extends payment methods with hosted card, without PCI exposure in the backend. | Checkout, Payments, Asaas provider, confirmation webhook. | OBC at `prodops/artifacts/business/obcs/credit-card-authorization-confirmation.md`. BDD Feature at `prodops/artifacts/business/bdd/credit-card-payment.feature`. Approved on 2026-07-07 (EXP-003 + EXP-001 hosted slice). Ready for Bootstrap + Hack. |
| Create invoice via Boleto | Extends payment methods served by the new gateway. | Checkout, Payments, Boleto rules, Asaas provider, notification. | OBC created at `prodops/artifacts/business/obcs/create-invoice-boleto.md`. BDD Feature created at `prodops/artifacts/business/bdd/create-invoice-boleto.feature`. Risks documented in `risks.md`. Ready to enter the Downstream flow. |
| Payment confirmation | Allows Ecommerce to recognize approved payment and continue the customer journey. | Payments, provider webhook, Ecommerce/Orders, Notification Service. | OBC at `prodops/artifacts/business/obcs/payment-confirmation.en.md`. BDD Feature at `prodops/artifacts/business/bdd/payment-confirmation.feature`. Implemented in code for main events. |
| Payment status notification | Closes the customer communication cycle and reduces post-payment uncertainty. | Ecommerce, Notification Service, Payments. | No OBC or BDD Feature in this repository — depends on implementation in Notification Service and Ecommerce. Returned to Upstream. |
| Cancel pending invoice | Prevents undue charges from remaining active. | Payments, Asaas provider, invoice state rules. | OBC at `prodops/artifacts/business/obcs/cancel-invoice.en.md`. BDD Feature at `prodops/artifacts/business/bdd/cancel-invoice.feature`. Implemented in code. |
| Enable new gateway for Checkout | Allows the Release to generate real value in production. | Checkout, Feature Flag, Payments. | No OBC or BDD Feature — depends on Feature Flag and integration in the Checkout repository. Returned to Upstream. |
| API token access validation | Ensures that only authorized systems consume the Payments API, with per-tenant traceability and a local key for development. | Payments API, environment variables, Checkout team and integrations. | Implemented. OBC at `prodops/artifacts/business/obcs/`. BDD at `prodops/artifacts/business/bdd/`. |
| Webhook configuration per API token | Allows consumers to receive automatic payment status change notifications without polling. | Payments API, API token, DynamoDB WebhooksTable. | New item; OBC and BDD created. |

## Recommended Iteration Plan

| Feature | Decision | Rationale | Value delivered |
| --- | --- | --- | --- |
| Enable new gateway for Checkout in the prioritized journey | Upstream | No OBC or BDD Feature in this repository. Enablement depends on Feature Flag and integration in the Checkout repository — scope outside the Payments API domain. Returned to Upstream for documentation as an external dependency in the Reliability Plan. | — |
| Create invoice via Credit Card (Hosted) | In | EXP-003 + EXP-001 (hosted slice) validated the approach. OBC and BDD Feature exist. Approved on 2026-07-07 — ready for Bootstrap + Hack. | Checkout now offers hosted card as a payment method via Payments gateway, without PCI exposure in the backend. |
| Create invoice via Pix | In | Pix is the best slice to validate the new gateway: has high value for Checkout, is present in the Service Deck and already has an implementation base. OBC at `prodops/artifacts/business/obcs/create-invoice.en.md`. | Customer can initiate Pix payment through the new Payments domain. |
| Payment confirmation | In | Without confirmation, the created invoice does not close the business journey. This feature reduces the main risk of a customer paying without a clear continuation. OBC at `prodops/artifacts/business/obcs/payment-confirmation.en.md`. | Ecommerce receives a reliable signal of approved payment. |

| Payment status notification | Upstream | No OBC or BDD Feature in this repository. Implementation belongs to Notification Service and Ecommerce — external dependency. Returned to Upstream for registration in the Reliability Plan as an integration risk. | — |
| Create invoice via Boleto | In | OBC and BDD Feature created on 2026-07-06. Specific journey documented with 8 scenarios, 4 risks and response contract including `bankSlipUrl` and `identificationField`. Implementation dependencies identified in the OBC. Ready for Bootstrap + Hack. | Checkout now offers Boleto as a payment method via Payments gateway, with typed line and PDF link returned to the customer. |
| API token access validation | In | Protects the Payments API from unauthorized access and enables per-tenant traceability from the first production slice. Local key eliminates friction in the development environment. | Checkout and integrations now authenticate via registered token; local access works without dependency on external secrets. |
| Webhook configuration per API token | In | Completes the integration contract: consumers using the API token need to receive status notifications without polling. Direct dependency on the already-delivered API token. | Checkout and integrations receive `invoice.confirmed` and `invoice.cancelled` via HTTP POST with a verifiable signature. |
| Cancel pending invoice | Deferred | Despite being implemented, it is not essential for validating the initial activation of the new gateway in Checkout. Including it as a main commitment would increase the Release surface. OBC at `prodops/artifacts/business/obcs/cancel-invoice.en.md` — available for next iteration. | Value preserved for a later iteration with lower dispersion risk. |
| Corporate incident/ITSM integration | Out | Relevant for operations, but not a business feature of the iteration. | Keeps focus on the Release's functional scope. |
| Gateway fallback/Itau | Out | The Product Deck mentions interchangeability, but the current scope is Asaas. Including fallback now would make the Release too large. | Avoids turning the iteration into a platform program. |

## Trade-offs made

Boleto was split due to lack of evidence of a complete journey. On 2026-07-06 the OBC, BDD Feature and risks were created. The decision was revised to "In" — the contract and acceptance criteria are defined and the journey can proceed to Bootstrap + Hack without competing with Pix stabilization, since the artifacts clearly delimit the rules and implementation dependencies.

Cancellation remained deferred because, although it has operational value and is implemented, it is not the central capability to prove the new Checkout -> Payments -> confirmation -> informed customer journey. It can be resumed when the main activation is stable.

Observability, ITSM, runbooks, rollout and reliability items were not included as functional scope of the Iteration Plan because the prompt defines that these subjects belong to the Reliability Plan. They influence caution in scope selection, but do not enter as features of this business decision.

Fallback/Itau was excluded because it would greatly increase the Release size. The interchangeability opportunity remains valid in the Product Deck, but does not belong to the smallest set of features needed for this iteration.

## Assumptions

- The next iteration has a duration of 15 days, as per the premortem.
- The main Release objective is to enable the new gateway in Checkout with the lowest failure risk.
- Pix is the priority journey for validating the new gateway, as it is detailed in the Compra com Pix Service Deck.
- Boleto is desired by the business, but there is insufficient evidence in the artifacts to treat it as a journey as mature as Pix in this iteration.
- Notification Service remains a critical dependency for the customer experience.
- The Feature Flag bug is outside this repository's code, but directly influences the scope decision.
- The code analysis was used only to assess scope feasibility, not to propose implementation tasks.

## Sources consulted

- `prodops/artifacts/product/context/product-deck.md`
- `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
- `prodops/artifacts/product/backlogs/icebox-backlog.md`
- `prodops/artifacts/business/bdd/create-invoice.feature`
- `prodops/artifacts/business/bdd/payment-confirmation.feature`
- `prodops/artifacts/business/bdd/cancel-invoice.feature`
- `prodops/framework/journeys/assessment/`
- `prodops/artifacts/product/backlogs/iteration-backlog.md`
- `prodops/artifacts/product/event-storming/plan.json`
- `api/src/modules/invoices`
- `api/src/infra/asaas.service.ts`
- `api/test/criar-invoice.e2e-spec.ts`
