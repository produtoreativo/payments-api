# ProdOps Premortem - Payments and Checkout

> Preventive exercise to anticipate likely failures in the integration sprint between Checkout, Payments and Notification Service. The objective is to transform known risks into observable actions before enabling the new gateway in production.

## 1. Executive Context

The Magazine Siara Ecommerce teams started a monolith decomposition process to increase team autonomy, reduce dependency between deliveries and allow faster evolution of business domains. Within this movement, the Payments team was created to manage features related to customer payment management, including charge creation, payment confirmation, status events and integrations with external providers.

Part of the notification structure was already extracted to a separate service, since it was technically ready to operate outside the monolith. As a result, some features were made available early for consumption by Ecommerce, which continues to centralize conversation with customers and orchestrate communication of the purchase journey status.

The Checkout service is already ready to use the new gateway in production, but activation remains blocked by a Feature Flag due to a localized bug. At the same time, the Notification Service is already in use and has a recent history of incidents that compromised payment confirmation communication to the customer.

The team's next sprint, scheduled to start on the 20th and last 15 days, intends to deliver the capabilities needed for the Checkout feature:

- Create invoice via Pix.
- Create invoice via Boleto.
- Confirm payment.
- Notify payment status.

## 2. Premortem Premise

We are at the end of the 15-day sprint and the delivery has failed or needed to be reverted. The new payment flow was not safely enabled in production, customers were left without reliable information about the payment, or there was divergence between Checkout, Payments, Notification Service and the payment provider.

This document answers: what probably happened, what signals would have appeared beforehand and what actions reduce the chance of failure.

## 3. Expected Sprint Result

| Result | Description |
| --- | --- |
| Checkout integrated with gateway | Checkout can create invoices in Payments using a stable contract for Pix and Boleto. |
| Confirmable payment | Payments receives confirmation from the provider, updates internal state and publishes the canonical event. |
| Informed customer | Notification Service communicates payment status to the customer without duplication, excessive delay or operational silence. |
| Safe Feature Flag | Activation of the new gateway can be done gradually, reversibly and observably. |
| Prepared operation | Teams can diagnose failures by orderId, invoiceId, paymentId, providerPaymentId and correlationId. |

## 4. Critical Hypotheses

| Hypothesis | Risk if false | How to validate before go-live |
| --- | --- | --- |
| The Checkout -> Payments contract covers Pix and Boleto without ambiguity. | Checkout sends a valid payload for one method and an invalid one for the other; errors only appear in production. | Contract tests for Pix and Boleto, versioned examples and schema validation. |
| The Feature Flag fully isolates the new gateway. | Part of the traffic uses the new gateway without control or consistent rollback. | Activation/deactivation test in a controlled environment and audit by tenant/channel. |
| Notification Service can handle the expected load and events. | Customer pays but does not receive confirmation or receives duplicate messages. | Light load test, event deduplication and send/failure dashboard. |
| Payments has idempotency per order/invoice. | Retries create duplicate charges. | Tests with the same idempotency key for success, timeout and retry. |
| Payment confirmation and notification use correlatable events. | Confirmed payment does not find the correct order or notification. | Trace correlationId, orderId, invoiceId, paymentId and providerPaymentId end to end. |

## 5. Probable Failure Scenarios

| ID | Imagined Failure | Probable Cause | Impact | Anticipated Signals | Preventive Action |
| --- | --- | --- | --- | --- | --- |
| PMT-PRE-001 | Checkout enables the new gateway and some orders do not create an invoice. | Incomplete Pix/Boleto contract, divergent validation or bug still protected by the Feature Flag. | Conversion drop and increased error at checkout. | 4xx/5xx in invoice creation, feature flag on for few users with error above baseline. | Create Checkout -> Payments contract suite and flag release checklist. |
| PMT-PRE-002 | Customer pays but does not receive confirmation. | Notification Service fails, does not consume event or does not correlate payment and order. | Support tickets, low confidence and stalled orders. | `payment.confirmed` without notification sent; increase of retry/dead-letter events. | Define notification SLO and alert for confirmation without customer communication. |
| PMT-PRE-003 | Payment is confirmed more than once. | Duplicate webhook, provider retry or non-idempotent consumption. | Order released twice, duplicate notification and operational risk. | Repeated events with same `providerPaymentId`; duplicity of `payment.confirmed`. | Persist raw events and deduplicate by provider event id, payment id and state transition. |
| PMT-PRE-004 | Pix works, but Boleto fails in production. | Boleto was treated as a simple invoice variation, without its own rules for due date, barcode line and status. | Boleto customers are blocked or receive incorrect instructions. | Errors concentrated in `billingType=Boleto`; payloads rejected by the provider. | Separate acceptance criteria for Pix and Boleto and test specific contracts per method. |
| PMT-PRE-005 | Feature Flag does not allow a clean rollback. | State created in the new gateway has no reconciliation or fallback to the old flow. | Operation is stuck between two flows and needs to handle orders manually. | Orders started in the new gateway continue receiving events after flag is turned off. | Define rollback policy: new orders return to the old flow, already-initiated orders are reconciled in Payments. |
| PMT-PRE-006 | Teams cannot diagnose failures quickly. | Logs without correlationId, incomplete dashboards or events without common identifiers. | High MTTR and decision by perception, not evidence. | Incidents depend on manual database/provider queries; Support without reliable status. | Standardize logs and events with orderId, invoiceId, paymentId, providerPaymentId and correlationId. |
| PMT-PRE-007 | Invoice creation generates a duplicate charge. | Checkout retry after timeout without consistent idempotency. | Customer may pay twice; reconciliation and support are compromised. | Same orderId with more than one open invoice in the provider. | Require idempotency key per operation and block duplicity by orderId + method + tenant. |
| PMT-PRE-008 | Sprint delivers endpoints but not operability. | Scrum focuses on functional items and leaves alerts, runbooks and dashboards for later. | Technically possible go-live but operationally fragile. | Stories without observability criteria; absence of runbook for known incidents. | Include operational Definition of Done for each sprint story. |

## 6. Questions That Need Answers Before the Sprint

| Question | Why It Matters | Suggested Owner |
| --- | --- | --- |
| What bug keeps the new gateway disabled by Feature Flag? | Defines the real go-live risk and minimum fix criteria. | Tech Lead Checkout + Payments |
| Does the Pix and Boleto delivery use the same contract or specialized contracts? | Prevents rules from one method contaminating the other. | Payments Engineering |
| Who owns final customer communication: Ecommerce or Notification Service? | Defines responsibility when payment confirms but customer is not notified. | PM Ecommerce + PM Payments |
| Which event triggers payment status notification: creation, confirmation, receipt or cancellation? | Prevents early, duplicate or missing messages. | Payments + Notification |
| What is the policy for orders created while the flag was on and then turned off? | Prevents loss of traceability during rollback. | Checkout + Payments + Operation |
| Which recent Notification Service incidents would recur in this flow? | Uses real learning to reduce recurrence. | SRE + Notification |

## 7. Readiness Checklist

| Area | Minimum Criteria Before Enabling in Production | Status |
| --- | --- | --- |
| Product | Pix and Boleto journey described with expected states and customer messages. | Open |
| Checkout | Feature Flag with gradual rollout, audit and tested rollback. | Open |
| Payments | Idempotent invoice creation for Pix and Boleto. | Open |
| Payments | Deduplicated payment confirmation correlated with invoice/order. | Open |
| Notification | Event consumption with deduplication and traceability per order. | Open |
| Observability | Dashboard with invoice creation, confirmation, notification, error and latency. | Open |
| Alerts | Alert for confirmed payment without customer notification. | Open |
| Operation | Runbook for invoice failure, missing confirmation, missing notification and flag rollback. | Open |
| Support | Query or procedure to report reliable status to the customer. | Open |
| Security | Sensitive provider secrets and payloads masked in logs and audit. | Open |

## 8. Risk Reduction Plan

| Priority | Action | Expected Result | Suggested Owner |
| --- | --- | --- | --- |
| P0 | Fix and document the bug keeping the gateway disabled. | Feature Flag stops hiding an unknown risk. | Checkout + Payments |
| P0 | Define the canonical invoice contract for Pix and Boleto. | Checkout and Payments integrate without payload and error ambiguity. | Payments |
| P0 | Implement idempotency and deduplication in creation and confirmation. | Retries do not generate duplicate charges or notifications. | Payments |
| P0 | Create alert for `payment.confirmed` without delivered notification. | Customer-without-information incident appears before the support ticket. | SRE + Notification |
| P1 | Create end-to-end journey dashboard. | Team visualizes technical conversion per step. | SRE + Payments |
| P1 | Test Feature Flag rollback with orders in progress. | Disabling does not abandon already-created invoices. | Checkout + Payments |
| P1 | Review recent Notification Service incidents. | Mitigation actions enter the sprint, not the post-incident. | Notification + SRE |
| P2 | Create initial runbook for confirmed payment without notification. | Support and operation have a standard procedure. | Payments + Support |

## 9. ProdOps Definition of Done for the Sprint

A sprint story should only be considered complete when it meets the points below, where applicable:

- Functional criteria implemented and tested.
- API or event contract documented.
- Expected errors mapped with a clear response to Checkout/Ecommerce.
- Idempotency validated for client retry, timeout and duplicate webhook.
- Structured logs with `correlationId`, `orderId`, `invoiceId`, `paymentId` and `providerPaymentId`.
- Success, error and latency metrics emitted.
- Canonical event published exactly once per relevant transition.
- Dashboard or operational query available.
- Minimum runbook updated for known failures.
- Feature Flag tested for gradual activation and rollback.

## 10. Improved Narrative for Alignment

The decomposition of the Magazine Siara monolith created a new boundary between Ecommerce, Checkout, Payments and Notification Service. This boundary increases autonomy but also transfers part of the risk to contracts, events, observability and cross-team operation.

Payments becomes the owner of the payment domain: creating invoices, integrating providers, receiving confirmations and maintaining reliable states. Ecommerce remains responsible for the conversation with the customer, but depends on correct and timely signals from Payments and Notification Service to inform the purchase status.

Since Notification Service already operates outside the monolith and has already experienced incidents, it must be treated as a critical journey dependency, not just an auxiliary channel. A technically correct payment confirmation can still fail as a customer experience if the notification is not sent, is duplicated or arrives late.

The new gateway is technically ready in Checkout, but remains disabled by Feature Flag due to a localized bug. This indicates that the sprint should not measure success only by delivered endpoints. Real success requires releasing the flow with a clear contract, idempotency, tested rollback, end-to-end telemetry and runbooks for the most likely failure scenarios.

For the 15-day sprint starting on the 20th, the deliveries of Pix invoice, Boleto invoice, payment confirmation and status notification must be planned as a single journey. The most dangerous failure is not just a call returning an error; it is the customer paying and the platform being unable to explain, confirm, notify or reconcile what happened.
