# Upstream Trail — EXP-007: Split Payment

## Identification

| Field | Content |
|---|---|
| Experiment | EXP-007 |
| Business Intent | `prodops/artifacts/business/intents/split-payment.md` |
| Owner | Product Team |
| Start date | 2026-07-03 |
| End date | 2026-07-03 |
| Status | Completed — awaiting product decision |

---

## Exploration sequence

### 2026-07-03 — Analysis of the current model

**What was done:**

Reading the current domain model of the Payments API:
- `api/src/modules/invoices/types/invoice.types.ts`
- `api/src/modules/invoices/dto/create-invoice.dto.ts`
- `api/src/modules/invoices/dto/invoice-response.dto.ts`

**Finding:**

The current model is strictly 1:1:1 — 1 order : 1 invoice : 1 payment method. The `billingType` field in `InvoiceRecord` is a scalar field (not a list). The `orderId` field exists and is unique per invoice — the inverse relationship (orderId → multiple invoices) is already technically supported by the DynamoDB infrastructure, but has no composition semantics.

---

### 2026-07-03 — Market benchmark

**What was done:**

Comparative analysis of how payment providers and platforms handle method composition.

| Solution | Model | Learning |
|---|---|---|
| Stripe | Multiple `PaymentIntent` per `PaymentSession` | Each intent has an independent lifecycle; Session aggregates state |
| Adyen | Sub-intents within `PaymentSession` | Native support for partial composition |
| MercadoPago | Split between sellers (marketplace) | Not a split of methods per buyer — out of scope |
| Asaas | Independent charges | **No native composition support** — requires orchestration by the Payments API |

**Finding:**

The Payments API must absorb the responsibility for composition orchestration. Asaas operates at the level of individual charges. The correct pattern is analogous to Stripe: multiple independent charges aggregated by a composition entity managed by the Payments API.

---

### 2026-07-03 — Domain alternatives modeling

**Alternatives considered:**

**Option A — Multiple invoices per order with new `PaymentComposition` entity**

```
OrderId → PaymentComposition → [Invoice(Pix), Invoice(Card)]
```

- Additive change to the existing model
- Adds `compositionId?` and `allocatedAmount?` to `InvoiceRecord`
- New `PaymentComposition` entity manages aggregate state
- Simple payments continue working without change

**Option B — `paymentMethods[]` field in the main invoice**

```
OrderId → Invoice { paymentMethods: [Pix(100), Card(150)] }
```

- Requires structural change to `InvoiceRecord`
- Mixed semantics: one invoice would represent multiple charges
- Breaks the current state model (which status reflects the overall state?)

**Option C — "Master" invoice with child invoices**

```
OrderId → Invoice(master, COMPOSITE) → [Invoice(child-Pix), Invoice(child-Card)]
```

- Additional complexity without gain compared to Option A
- Complicates queries — self-join on the same table

**Decision:** Option A is the only one that preserves current semantics, does not break simple payments and is extensible. Selected.

---

### 2026-07-03 — Event Storming of the new flow

**New domain events mapped:**

```
[Customer selects Pix + Card in Checkout]
  → CompositionCreated
  → InvoiceCreated (Pix, R$100)
  → InvoiceCreated (Card, R$150)

[Pix QR Code confirmed via webhook]
  → PartialPaymentConfirmed (Pix, R$100)

[Card approved via webhook]
  → PartialPaymentConfirmed (Card, R$150)
  → CompositePaymentConfirmed (total R$250)

[Alternative: Card refused]
  → PartialPaymentFailed (Card)
  [Policy B: keep Pix confirmed, request new method]
  → New InvoiceCreated (Boleto, R$150)

[Alternative: payment window expired]
  → CompositePaymentExpired

[Alternative: customer cancels]
  → CompositionCancelled
  → [reversal of confirmed methods]
  → CompositePaymentFailed
```

---

### 2026-07-03 — Architectural impact analysis

**New component:** `PaymentCompositionService`
- Creates and persists `PaymentComposition`
- Processes aggregated webhooks
- Determines `CompositionStatus` transition
- Decides action according to the configured failure policy

**New endpoints:**
- `POST /v1/payment-compositions` — creates composition
- `GET /v1/payment-compositions/:id` — aggregate status

**Change to `WebhookProcessor`:**
- Detects if the invoice has `compositionId`
- If yes, delegates to `PaymentCompositionService` for aggregation
- If no, current flow unchanged

**DynamoDB:**
- New `CompositionsTable` or GSI `orderId-index` in `PaymentsTable`
- Access by `compositionId` (PK) and by `orderId` (GSI)

---

### 2026-07-03 — Candidate OBC

**Created at:** `prodops/artifacts/obcs/payment-composition-draft.md`

**Defined outcome:** Customer can complete an order using 2 payment methods with aggregate confirmation within 5 minutes.

**SLIs/SLOs:**
- Composition creation: p99 < 800ms
- Aggregate confirmation after both webhooks: < 5 min (SLO: 95%)
- Full reversal in case of failure after partial confirmation: < 30 seconds (SLO: 99%)

---

## Exit decision

**Status:** Upstream completed — awaiting product decision

**Open question:** Partial failure policy (A: revert all / B: keep confirmed / C: partial window)

**Recommendation:** Policy B — keep confirmed methods, request new attempt for the failed method.

**Next step:**
1. Product Team decides the failure policy
2. Create BDD Feature: `prodops/artifacts/bdd/payment-composition.feature`
3. Update Iteration Plan
4. Bootstrap → Hack

---

## References

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/artifacts/business/intents/split-payment.md`
- `prodops/artifacts/obcs/payment-composition-draft.md`
- `api/src/modules/invoices/types/invoice.types.ts`
