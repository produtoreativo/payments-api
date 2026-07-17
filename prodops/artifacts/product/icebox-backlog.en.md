# Icebox - Payments

> **Purpose:** Items committed by the Product Owner that are still being prepared for Delivery. The necessary Discovery occurs here — functional, technical or operational. The goal is to produce a Local OBC in the Committed state. Until that happens, the item remains in the Icebox.
>
> Items that complete the Committed state advance to the Iteration Backlog (ready to develop).
>
> → [Backlog hierarchy](../../framework/backlogs.en.md)

## 1. Icebox Governance

| Field | Content |
| --- | --- |
| Product | Payments |
| Context | Payment gateway for Magazine Siara ecommerce, with initial focus on Pix purchase and Asaas integration. |
| Product owner | `[Product Manager Payments]` |
| Technical owner | `[Tech Lead Payments]` |
| Channel | `[Slack/Teams: #payments-prodops]` |
| Main source | Features in `prodops/artifacts/bdd` |
| Last updated | `2026-06-30` |

## 2. How to use this backlog

1. Record opportunities as observable problems, not just solutions.
2. Classify each item by expected outcome, risk, dependency and evidence.
3. Keep items in the icebox while context, priority or capacity are missing.
4. Promote to discovery when there is a critical question to answer.
5. Promote to delivery only when there are acceptance criteria, minimum telemetry, known dependencies and a defined owner.

## 3. Item states

| State | Meaning | Movement criterion |
| --- | --- | --- |
| Icebox | Item committed by the Product Owner (from PIB), being refined through Discovery to reach the Committed state. | OBC Draft under refinement; functional, technical or operational Discovery still in progress. |
| Discovery | Item under product, business, technical, operations or data investigation. | Clear question, owner and learning deadline exist. |
| Ready for Delivery | Item ready for sprint/kanban planning. | Acceptance criteria, dependencies, metrics and risks are clear. |
| Delivery | Item under implementation. | Team assumed commitment and started execution. |
| Done | Delivered and observed in production. | Acceptance criteria, logs, metrics, events and operational documentation validated. |
| Dropped | Will not be executed now. | Decision recorded with reason and revisit condition. |

## 4. Standard fields per item

| Field | Description |
| --- | --- |
| ID | Stable item identifier in the backlog. |
| Title | Short name, outcome-oriented. |
| Type | Feature, improvement, risk, experiment, technical debt, observability or operation. |
| Problem/opportunity | Pain, risk or business opportunity justifying the item. |
| User/customer | Person, system or team impacted. |
| Expected outcome | Measurable change in behavior, operations or result. |
| Current evidence | Data, incident, requirement, feature file, feedback or hypothesis. |
| MVP scope | Smallest useful and verifiable delivery. |
| Out of scope | Explicit limits to prevent silent expansion. |
| Dependencies | Systems, teams, contracts, data or decisions required. |
| Risks | Main business, data, technology, security or operations risks. |
| Minimum telemetry | Events, logs, metrics, traces and audit required. |
| Acceptance criteria | Objective conditions for considering the item done. |
| Score | Prioritization by RICE/ICE/WSJF adapted to the product. |
| Status | Current state of the item. |

## 5. Prioritization model

Use RICE as the default criterion and complement with operational risk when journey reliability is a central part of the decision.

| Field | Scale | Question |
| --- | --- | --- |
| Reach | 1-5 | How many customers, orders, teams or flows are impacted? |
| Impact | 1-5 | How much does the item protect conversion, GMV, trust, efficiency or continuity? |
| Confidence | 1-5 | How much evidence exists to support the priority? |
| Effort | 1-5 | What is the relative engineering, product, data and operations effort? |
| Operational Risk | 1-5 | What is the risk of incident, rework, financial loss or operational divergence if not done? |

Suggested formula:

```text
Score = ((Reach * Impact * Confidence) + Operational Risk) / Effort
```

## 6. Summarized backlog

| ID | Title | Type | Expected outcome | Status | Initial score | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PAY-ICE-001 | Create invoice via gateway with single contract | Feature | Ecommerce issues charges without direct coupling to the Asaas provider. | Delivery | 16.4 | [create-invoice.feature](../bdd/create-invoice.feature) |
| PAY-ICE-002 | Confirm payment via reliable webhook | Feature | Order and ecommerce receive confirmation exactly once, with auditable events. | Delivery | 20.8 | [payment-confirmation.feature](../bdd/payment-confirmation.feature) |
| PAY-ICE-003 | Cancel pending invoice with idempotency | Feature | Open charges can be cancelled without undue payment or duplicate event. | Ready for Delivery | 13.7 | [cancel-invoice.feature](../bdd/cancel-invoice.feature) |

## 7. Detailed items

### PAY-ICE-001 - Create invoice via gateway with single contract

| Field | Content |
| --- | --- |
| Type | Feature |
| Problem/opportunity | Ecommerce needs to create charges without depending directly on a specific provider's API, preserving the future capability to swap or fallback gateway. |
| User/customer | Magazine Siara Ecommerce, Checkout, Payments, Operations. |
| Expected outcome | Invoice created with trackable status, provider registered, external identifier persisted and standardized response to ecommerce. |
| Current evidence | Feature `Create invoice in the payment gateway`; need for single contract and per-order idempotency. |
| MVP scope | Create invoice in Asaas, create/reuse Asaas customer, validate enabled provider, guarantee idempotency and handle transient failures/validation. |
| Out of scope | Multiple active provider with automatic fallback, payment split, refund, full financial reconciliation. |
| Dependencies | Asaas credentials, provider registration per tenant, customer binding model, idempotency storage, response contract to ecommerce. |
| Risks | Duplicate charge, duplicated Asaas customer, open invoice without `providerPaymentId`, sensitive payload exposure in error. |
| Minimum telemetry | Invoice created event, provider call attempt, provider latency, provider error code, idempotency hit/miss, rejection audit log. |
| Acceptance criteria | Scenarios in [create-invoice.feature](../bdd/create-invoice.feature) pass; retry with the same key does not call the provider; 5xx failure does not return `OPEN` invoice without `providerPaymentId`; validation error is auditable without secrets. |
| Score | Reach 4, Impact 5, Confidence 4, Effort 5, Operational Risk 2 = 16.4 |
| Status | Delivery — OBC committed at `prodops/artifacts/obcs/create-invoice.md`. Entered the Iteration Plan. |

**Discovery questions**

- What is the canonical invoice contract that must remain stable across providers?
- How to identify a reusable customer safely: document, `externalReference` or internal binding?
- Which Asaas errors become business error, technical error or safe retry?

### PAY-ICE-002 - Confirm payment via reliable webhook

| Field | Content |
| --- | --- |
| Type | Feature |
| Problem/opportunity | Confirmed payment needs to release the order exactly once, even with a duplicate, delayed or out-of-order webhook received before the invoice's internal consolidation. |
| User/customer | Magazine Siara Ecommerce, Order Management, Payments, Finance, Customer Service. |
| Expected outcome | Canonical `payment.confirmed` event published exactly once per confirmed payment, with updated invoice and auditable raw event. |
| Current evidence | Feature `Payment confirmation by webhook`; need for reliable confirmation, reconciliation and duplicate protection. |
| MVP scope | Validate Asaas token, persist raw event, process `PAYMENT_CONFIRMED`, process `PAYMENT_RECEIVED`, deduplicate events, correlate by `providerPaymentId` or `externalReference`. |
| Out of scope | Full financial dashboard, dispute, chargeback, advanced multi-provider reconciliation rules. |
| Dependencies | Public webhook endpoint, Asaas secret/token, raw event storage, canonical event publication, contract with ecommerce/Orders. |
| Risks | Order released twice, payment received without order released, token leaked in logs, uncorrelated event, divergence between `CONFIRMED` and `RECEIVED`. |
| Minimum telemetry | Webhook received, webhook rejected, event deduplication, invoice status transition, canonical event published, lag between receipt and publication. |
| Acceptance criteria | Scenarios in [payment-confirmation.feature](../bdd/payment-confirmation.feature) pass; invalid webhook does not alter invoice; duplicate event returns technical success without republishing; `PAYMENT_RECEIVED` does not release the order a second time. |
| Score | Reach 5, Impact 5, Confidence 4, Effort 5, Operational Risk 4 = 20.8 |
| Status | Delivery — OBC committed at `prodops/artifacts/obcs/payment-confirmation.md`. Entered the Iteration Plan. |

**Discovery questions**

- Which canonical event should release the order: `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` or both with different rules?
- What is the acceptable SLA between webhook received and event delivered to ecommerce?
- How to operate uncorrelated or out-of-order events?

### PAY-ICE-003 - Cancel pending invoice with idempotency

| Field | Content |
| --- | --- |
| Type | Feature |
| Problem/opportunity | Ecommerce needs to cancel pending charges to prevent undue payment, maintaining idempotency and a clear decision when the provider diverges. |
| User/customer | Magazine Siara Ecommerce, Checkout, Payments, Customer Service, Operations. |
| Expected outcome | Open invoice can be cancelled safely, without a duplicate provider call and without an incorrect canonical event. |
| Current evidence | Feature `Cancel invoice in the payment gateway`; need to cancel still-active charges. |
| MVP scope | Cancel `OPEN` invoice in Asaas, record `CANCEL_REQUESTED`, confirm `CANCELLED`, publish `payment.cancelled`, prevent cancellation after `CONFIRMED`, handle provider 404. |
| Out of scope | Refund after confirmed payment, financial dispute, partial cancellation, advanced reconciliation policies. |
| Dependencies | Invoice state policy, Asaas endpoint `DELETE /v3/payments/{id}`, cancellation idempotency, `payment.cancelled` event, 404 policy. |
| Risks | Charge remaining payable after local cancellation, cancellation publication without provider confirmation, undue cancellation after payment, duplicate event. |
| Minimum telemetry | Cancel request, provider delete latency/error, status transition, idempotency hit/miss, webhook `PAYMENT_DELETED`, canonical cancellation published. |
| Acceptance criteria | Scenarios in [cancel-invoice.feature](../bdd/cancel-invoice.feature) pass; `CONFIRMED` invoice is not cancelled; retry with the same key does not call the provider; 404 does not publish `payment.cancelled` without explicit decision. |
| Score | Reach 3, Impact 4, Confidence 4, Effort 4, Operational Risk 2 = 13.7 |
| Status | Ready for Delivery — OBC committed at `prodops/artifacts/obcs/cancel-invoice.md`. Deferred to next iteration. |

**Discovery questions**

- Should the `payment.cancelled` event be published on the cancel command or only after the `PAYMENT_DELETED` webhook?
- What operational policy should be applied when Asaas returns 404?
- Which statuses allow cancellation and which require a refund flow?

## 8. Definition of Ready

An item should only leave the icebox for delivery when it meets the criteria below.

| Criterion | Expected evidence |
| --- | --- |
| Clear problem | Pain, opportunity or risk written in business and operations language. |
| Measurable outcome | Metric, event or expected behavior defined. |
| Known user/customer | Impacted systems, people or teams identified. |
| Delimited MVP scope | Inclusions and exclusions documented. |
| Defined contract | API, event, payload or external versioned behavior. |
| States and errors mapped | Main transitions, expected failures and retry/idempotency rules clear. |
| Planned observability | Minimum logs, metrics, traces, audit and alerts defined. |
| Known dependencies | Teams, credentials, topics, queues, tables and providers mapped. |
| Acceptance criteria | Testable and traceable scenarios to a feature file or specification. |
| Defined owner | Product and technical owner named. |

## 9. Operational Definition of Done

| Dimension | Criterion |
| --- | --- |
| Product | Initial outcome validated or active measurement plan. |
| Engineering | Relevant automated tests passing, versioned contract and traceable deploy. |
| Reliability | Minimum logs, metrics, traces and alerts working. |
| Operations | Runbook or support procedure updated for known failures. |
| Data | Canonical events and audit persisted when applicable. |
| Security | Secrets, tokens and sensitive payloads protected in logs, errors and audit. |
| Learning | Decisions, limits and trade-offs recorded in the corresponding artifact. |

## 10. Pending decisions

| ID | Decision | Impact | Owner | Status |
| --- | --- | --- | --- | --- |
| DEC-001 | Define canonical invoice contract between ecommerce and Payments API. | Blocks API stability and contract tests. | Tech Lead Payments | Open |
| DEC-002 | Define publication policy for `payment.confirmed`, `payment.received` and `payment.cancelled`. | Affects Orders, ecommerce and reconciliation. | PM Payments + Tech Lead Payments | Open |
| DEC-003 | Define policy for Asaas 404, 409, 422, 5xx and timeout errors. | Affects retry, support and invoice final state. | Payments Engineering | Open |
| DEC-004 | Define retention and masking of raw webhook events. | Affects audit, security and LGPD. | Security + Payments | Open |
| DEC-005 | Define initial payment confirmation SLO. | Affects dashboards, alerts and operational readiness. | SRE + Payments | Open |

## 11. Recommended next actions

| Action | Suggested owner | Expected output |
| --- | --- | --- |
| Review scores with PM, Tech Lead and SRE. | PM Payments | Initial prioritization validated. |
| Turn PAY-ICE-002 into a technical-operational discovery. | Tech Lead Payments | Decision on events, idempotency and correlation. |
| Specify canonical invoice contract. | Payments Engineering | OpenAPI or internal versioned contract. |
| Define canonical events and publication topics. | Payments + Orders | Integration contract between Payments and ecommerce/Orders. |
| Create invoice state matrix. | Payments Engineering | Allowed states, transitions and error rules. |
