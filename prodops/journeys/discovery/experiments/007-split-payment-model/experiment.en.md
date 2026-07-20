# EXP-007 — Split Payment: Payment Composition Model

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

**Business Intent:** [`prodops/artifacts/business/intents/split-payment.md`](../../../../artifacts/business/intents/split-payment.md)

---

# Business Goal

Determine the viable model to support multiple payment methods in a single order, identifying: the priority combinations, the appropriate domain model, the necessary business events, the architectural impacts on the Payments API and the partial failure policy that should guide the Downstream.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [x] Payments domain logic
- [x] Provider integration (Asaas)
- [x] Webhook handling
- [x] Persistence (DynamoDB)
- [x] API/event contract owned by Payments

## External dependencies

- **Checkout** — responsible for presenting the payment composition to the customer and collecting the methods
- **Order Management** — must recognize `CompositePaymentConfirmed` instead of a simple `PaymentConfirmed`
- **Notification Service** — must notify per confirmed method and per complete composition
- **Product Team** — decision on partial failure policy (see section below)

## Scope decision

- [x] Continue as executable Upstream experiment in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

---

# Questions to Answer

| # | Question | Status |
|---|---|---|
| Q1 | Which business scenarios justify multiple payments? | ✅ Answered |
| Q2 | Which payment method combinations to support initially? | ✅ Answered |
| Q3 | Is there a maximum payment limit per order? | ✅ Answered |
| Q4 | How to represent the remaining balance during composition? | ✅ Answered |
| Q5 | How to handle changes or removal before confirmation? | ✅ Answered |
| Q6 | How to handle partial failures when only one method is authorized? | ⚠ Partial — requires product decision |
| Q7 | How to reconcile asynchronous confirmations from different gateways? | ✅ Answered |
| Q8 | How to preserve a simple experience for the user? | ✅ Answered |
| Q9 | What are the impacts on the Order and Payment model? | ✅ Answered |
| Q10 | Which business events are needed for observability and audit? | ✅ Answered |

---

# Hypothesis

> It is possible to support multiple payment methods in a single order by creating multiple independent invoices in Asaas (one per method), orchestrated by a new `PaymentComposition` entity in the Payments API, without changing the semantics of existing invoices and without depending on a native Asaas feature.

---

# Technical Findings

## Q1 — Business scenarios that justify multiple payments

| Scenario | Estimated frequency | Business value |
|---|---|---|
| Insufficient credit limit → complement with Pix | High | Reduces abandonment on medium-high value orders |
| Gift card / cashback balance + main method | Medium | Increases benefit usage and loyalty |
| High-value order — two cards from the same customer | Medium | Enables ticket above individual card limit |
| Partial boleto + Pix to complete | Low | Complicates reconciliation — not a priority |

**Conclusion:** The priority scenario is **Pix + Credit Card**, followed by **Gift Card/Cashback + main method**. Boleto as a partial method should stay out of the MVP due to asynchronous reconciliation complexity.

---

## Q2 — Initially supported combinations

| Combination | Viability | Priority |
|---|---|---|
| Pix + Credit Card | High — both have defined confirmation | P0 — MVP |
| Gift Card / Cashback + any method | High — gift card is internal, no gateway latency | P0 — MVP |
| Pix + Pix (two QR Codes) | Low utility | P2 |
| Card + Card | Medium — requires tokenization of both | P1 — post-MVP |
| Boleto + any method | Low — Boleto has a long asynchronous confirmation window | P2 — not recommended in MVP |

**MVP decision:** support up to 2 methods per order, with at least one being an immediate confirmation method (Pix or Card).

---

## Q3 — Maximum payment limit per order

**Recommendation: 2 methods per order in the MVP.**

Reason: each additional method multiplies the possible partial failure states and the complexity of the reversion policy. The UX experience for 3+ methods is substantially more complex without proportional conversion gain.

The limit can be raised to 3 in a later iteration if usage data justifies it.

---

## Q4 — Representation of remaining balance

The remaining balance is calculated dynamically:

```
remainingAmount = totalOrderAmount - sum(invoices.map(i => i.amount))
```

It is not persisted as a field — it is derived from the composition. `PaymentComposition.confirmedAmount` is persisted as webhooks arrive:

```
confirmedAmount += invoice.amount  (when status → CONFIRMED)
```

Checkout displays `remainingAmount` during method selection. The `allocatedAmount` field on each invoice defines each method's share of responsibility.

---

## Q5 — Changes or removal of a method before confirmation

**States in which a method can be removed:**
- `CREATED` — invoice not yet sent to the provider → direct deletion
- `PROVIDER_PENDING` → `OPEN` — invoice active in Asaas → cancellation at the provider via `DELETE /v3/payments/{id}`

**Flow:**
1. Customer requests removal of Method B
2. Payments API cancels the Method B invoice (via Asaas if already `OPEN`)
3. Payments API recalculates `remainingAmount`
4. Customer selects new method → new invoice created

**Restriction:** A method in `CONFIRMED` state cannot be removed — only via complete order cancellation.

---

## Q6 — Partial failure handling (pending product decision)

This is the point of greatest uncertainty. Three viable policies:

| Policy | Behavior | Pros | Cons |
|---|---|---|---|
| **A — Revert all** | If any method fails, cancel all confirmed ones and reverse | Simpler, no partial state | Worst UX — customer loses the already-paid portion |
| **B — Keep confirmed, new attempt** | Confirmed invoice remains; customer selects new method for the failed portion | Better UX | Complexity in reversal if the entire order needs to be cancelled later |
| **C — Partial payment state with window** | Composition enters `PARTIALLY_CONFIRMED`; customer has N minutes to complete or cancel | Maximum flexibility | More complex to implement; requires expiration |

**This experiment's recommendation: Policy B** — preserves confirmed methods, allows a new attempt for the failed method. It is the most common approach in market solutions (Stripe, Adyen) and provides the best UX.

**⚠ This is a product decision — the Product Team must confirm before Downstream.**

---

## Q7 — Asynchronous reconciliation from different gateways

**Critical technical finding:** Asaas has no native concept of "payment composition". Each charge is independent. The Payments API must orchestrate the composition over independent charges.

**Reconciliation flow:**

```
[Asaas Webhook — Charge A CONFIRMED]
  → WebhookProcessor identifies invoiceId
  → Fetches PaymentComposition by invoiceId
  → Updates invoice A → CONFIRMED, confirmedAmount += A.amount
  → Checks: allInvoicesConfirmed(composition)?
       YES → emits CompositePaymentConfirmed, status → CONFIRMED
       NO → emits PartialPaymentConfirmed, status → PARTIALLY_CONFIRMED

[Asaas Webhook — Charge B CONFIRMED]
  → Same flow → allInvoicesConfirmed → true
  → emits CompositePaymentConfirmed
```

The lookup key is: `compositionId` via `InvoiceRecord.compositionId` (new field) or via GSI in DynamoDB by `orderId`.

**Idempotency:** the `WebhookProcessor` must be idempotent by `webhookId` — already guaranteed by the existing webhook processing model.

---

## Q8 — Preserving simple experience for the user

The model is internally complex but should be transparent to the user:

```
Checkout displays:
  "Total: R$ 250.00"
  [Method 1: Pix — R$ 100.00]  → QR Code generated ✓
  [Method 2: Card — R$ 150.00] → Processing...
  [Waiting for all payment confirmations]
```

The API returns a `paymentCompositionId` as the main reference for Checkout to track the aggregate state, instead of an `invoiceId` per method.

---

## Q9 — Impacts on the Order and Payment model

### InvoiceRecord — minimal changes

```typescript
interface InvoiceRecord {
  // existing fields preserved
  compositionId?: string;   // new: reference to the composition (null for simple payments)
  allocatedAmount?: number; // new: amount allocated to this method in the composition
}
```

The `orderId` field continues to exist — the `orderId → [invoice1, invoice2]` relationship is already technically supported by the current model; what changes is that it now has composition semantics.

### New entity: PaymentComposition

```typescript
interface PaymentComposition {
  compositionId: string;        // ULID
  orderId: string;
  tenantId: string;
  totalAmount: number;
  confirmedAmount: number;
  invoiceIds: string[];         // ordered list
  compositionStatus: CompositionStatus;
  failurePolicy: 'REVERT_ALL' | 'KEEP_CONFIRMED' | 'PARTIAL_WINDOW';
  partialWindowExpiresAt?: string; // for policy C
  createdAt: string;
  updatedAt: string;
}

type CompositionStatus =
  | 'PENDING'
  | 'PARTIALLY_CONFIRMED'
  | 'CONFIRMED'
  | 'PARTIALLY_FAILED'
  | 'FAILED'
  | 'CANCELLED'
  | 'EXPIRED';
```

### Impact on Order Management

The order release event changes from:
- `PaymentConfirmed` (simple invoice) → continues for simple payments
- **`CompositePaymentConfirmed`** → new event for compositions

Order Management must recognize both contracts.

### No breaking change for simple payments

Payments with a single method continue working without `compositionId`. The new capability is additive.

---

## Q10 — Business events for observability and audit

| Event | Producer | Consumers | Required fields |
|---|---|---|---|
| `CompositionCreated` | Payments API | Checkout, Analytics | `compositionId`, `orderId`, `totalAmount`, `methods[]`, `tenantId` |
| `PartialPaymentConfirmed` | Payments API | Checkout, Analytics | `compositionId`, `invoiceId`, `billingType`, `amount`, `confirmedAmount`, `remainingAmount` |
| `CompositePaymentConfirmed` | Payments API | Order Management, Notifications, Analytics | `compositionId`, `orderId`, `totalAmount`, `methods[]`, `confirmedAt` |
| `PartialPaymentFailed` | Payments API | Checkout, Support | `compositionId`, `invoiceId`, `billingType`, `failureReason`, `policy` |
| `CompositePaymentFailed` | Payments API | Order Management, Support | `compositionId`, `orderId`, `failureReason`, `refundedAmount` |
| `CompositePaymentExpired` | Payments API | Checkout, Support | `compositionId`, `orderId`, `confirmedAmount`, `remainingAmount` |
| `CompositionCancelled` | Payments API | Order Management, Checkout | `compositionId`, `orderId`, `cancelledBy`, `refundedAmount` |

---

# Business Findings

## Market benchmark

| Solution | Adopted model |
|---|---|
| **Stripe** | Multiple independent `PaymentIntent` objects linked to a `PaymentSession`; each intent has its own lifecycle |
| **Adyen** | `Payment Sessions` with sub-intents; native support for partial composition |
| **MercadoPago** | Focus on split between sellers (marketplace), not on multiple methods per buyer |
| **Asaas** | No native composition concept; each charge is independent — **requires orchestration by the Payments API** |

**Conclusion:** The approach of orchestrating independent charges in Asaas is the correct pattern given that Asaas does not offer native composition. The Payments API absorbs the orchestration complexity, keeping Asaas as a provider of individual charges.

## Validated business value

- Medium-to-high value orders (above R$ 500) are the highest-impact cases
- Pix + Card combination addresses the most common scenario of insufficient credit limit
- The capability is more valuable after adoption of hosted card (EXP-003), since without card the second method would always be asynchronous (Boleto)

---

# Architecture Impact

## New components

| Component | Type | Impact |
|---|---|---|
| `PaymentCompositionRepository` | Service + DynamoDB | New `CompositionsTable` table or GSI by `orderId` in `PaymentsTable` |
| `PaymentCompositionService` | Service | Orchestration: creation, webhook aggregation, status transition |
| `POST /v1/payment-compositions` | Controller | New endpoint — accepts `orderId`, `totalAmount`, `methods[]` |
| `GET /v1/payment-compositions/:id` | Controller | Aggregate composition status |
| `WebhookProcessor` | Change | Detects `compositionId` in the invoice → invokes `PaymentCompositionService` |
| `InvoiceRecord` | Additive change | Adds `compositionId?` and `allocatedAmount?` |

## No breaking change

Simple payments continue via `POST /v1/invoices`. No mandatory field is removed or altered.

## Estimated complexity: High

- New DynamoDB table with access patterns by `compositionId` and by `orderId`
- New state machine for `CompositionStatus` (7 states)
- Webhook processor needs aggregation logic
- Acceptance tests need to simulate multiple webhooks in sequence

---

# Artifacts Updated

- [x] Business Intent: `prodops/artifacts/business/intents/split-payment.md` — questions answered
- [x] Tracking List: `prodops/artifacts/product/tracking-list.md` — new product items
- [x] Candidate OBC: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md` — created
- [ ] BDD Feature — awaiting decision on partial failure policy
- [ ] Event Storming — update `prodops/journeys/assessment/event-storming/` with new events

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|---|---|---|
| Business scenarios | ✅ Answered | Benchmark + usage analysis |
| Priority combinations | ✅ Answered | Pix + Card = P0 |
| Maximum limit | ✅ Answered | 2 methods in MVP |
| Remaining balance | ✅ Answered | Derived calculation + `confirmedAmount` persisted |
| Changes before confirmation | ✅ Answered | Invoice cancellation + new invoice |
| Partial failures | ⚠ Partial | Policy B recommended, product decision pending |
| Asynchronous reconciliation | ✅ Answered | Multiple Asaas charges + aggregation in Payments API |
| Simple experience | ✅ Answered | `compositionId` as main reference in Checkout |
| Model impacts | ✅ Answered | Additive change — no breaking change |
| Business events | ✅ Answered | 7 new events defined |

---

# New Backlog Items

| Item | Classification | Note |
|---|---|---|
| Define partial failure policy (A, B or C) | **Repository Tracking List — product decision** | Blocker for Downstream |
| Validate `CompositePaymentConfirmed` contract with Order Management | **Repository Tracking List** | External dependency |
| Define DynamoDB strategy for CompositionsTable | **Candidate for Iteration Backlog** | After policy decision |
| Create BDD Feature for payment composition | **Candidate for Iteration Backlog** | After policy defined |
| Update Event Storming with new events | **Candidate for Iteration Backlog** | Can be done now |

---

# Recommendation

- [x] **Wait for business decision** — partial failure policy (Q6)

After the decision:

- [x] **Move to Downstream** — the model is sufficiently defined to start the Bootstrap → Hack cycle

**Justification:**

All technical and domain questions have been answered. The only blocker is the product decision on the partial failure policy (Policy A, B or C), which determines the state machine and the `PartialPaymentFailed` contract. Policy B (keep confirmed methods, new attempt for the failed one) is recommended.

With the policy defined, Downstream can start with:
1. OBC: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`
2. BDD Feature: to be created after policy definition
3. Entry in the Iteration Plan for the next iteration

---

# Decision Package

## Executive Summary

Split Payment is viable on the current Payments API architecture using multiple independent invoices in Asaas orchestrated by a new `PaymentComposition` entity. The change is **additive** — no existing contract is broken. The main complexity lies in composition state management and aggregated webhook processing.

The MVP should support 2 methods per order, prioritizing Pix + Card. The only pending product decision is the partial failure policy.

## Recommended Decision

**Approve Downstream** after confirmation of the partial failure policy (Policy B recommended).

## Identified Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Policy B creates inconsistency if order is cancelled after partial confirmation | Medium | High | Define total cancellation contract that includes reversal of confirmed methods |
| Asaas may introduce limits on simultaneous charges per orderId | Low | Medium | Validate in sandbox before Downstream |
| Order Management may not be ready to recognize new event | Medium | High | Early alignment with Orders squad |
| Out-of-order webhook (Charge B confirmed before A) | Low | Medium | State machine already guarantees idempotency — handle in aggregator |

## Opportunities

- Enables higher average ticket without UX friction
- Foundation for Gift Card / Cashback support as a partial payment method
- `PaymentComposition` model can be reused for cross-method installment support in the future

## Candidate OBC

→ `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`

## Recommended Downstream Scope (after policy decision)

1. `PaymentCompositionService` + `PaymentCompositionRepository`
2. `POST /v1/payment-compositions` + `GET /v1/payment-compositions/:id`
3. Webhook aggregation in `WebhookProcessor`
4. 7 new domain events
5. BDD Feature with scenarios: creation, full confirmation, partial confirmation, partial failure (Policy B), expiration

---

# Exit Criteria

- [x] Original hypothesis answered — composition via multiple invoices is viable
- [x] Questions classified — 9 answered, 1 awaiting product decision
- [x] Knowledge gaps documented — failure policy and alignment with Order Management
- [x] Architectural impact documented — new component, additive change to InvoiceRecord
- [x] Reliability impact documented — new failure modes, 4 risks identified
- [x] Artifacts updated — candidate OBC created, tracking list updated
- [x] Recommendation produced — Downstream after policy decision
- [x] Decision Package complete

---

# Next Step

1. **Product Team confirms the partial failure policy** (Policy B recommended)
2. Create BDD Feature: `prodops/artifacts/bdd/payment-composition.feature`
3. Add to Iteration Plan
4. Bootstrap → Hack
