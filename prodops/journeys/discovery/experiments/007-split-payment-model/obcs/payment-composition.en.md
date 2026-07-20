# OBC — Payment Composition (Draft)

> Status: **Draft — awaiting partial failure policy decision**
> Location: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`
> Origin experiment: `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
> Promote via: `/upstream move-to-downstream` after product decision

---

## Observable Business Contract

### Outcome

> Customer can complete an order using 2 payment methods, receiving aggregate confirmation after all methods have been processed.

### Observable

| SLI | Measure | SLO | Window |
|---|---|---|---|
| Composition creation latency | p99 of `POST /v1/payment-compositions` | < 800ms | Rolling 24h |
| Aggregate confirmation | Time between creation and `CompositePaymentConfirmed` | < 5 min in 95% of cases | Rolling 7d |
| Full reversal after failure | Time between `PartialPaymentFailed` and reversal of confirmed methods | < 30s in 99% | Rolling 7d |
| Composition endpoint availability | Success rate 2xx on `POST /v1/payment-compositions` | ≥ 99.5% | Rolling 30d |

---

## Preconditions

- Customer authenticated with valid `X-Api-Token`
- `orderId` exists and is in an eligible state for payment
- `totalAmount` = sum of `methods[].amount`
- Each method has a valid `billingType` (PIX, CREDIT_CARD)
- Method combination permitted by MVP policy (max. 2 methods; at least one immediate confirmation method)

---

## Postconditions

**Success (composition confirmed):**
- `PaymentComposition.compositionStatus` = `CONFIRMED`
- `confirmedAmount` = `totalAmount`
- Event `CompositePaymentConfirmed` emitted with `compositionId`, `orderId`, `totalAmount`, `methods[]`
- Order Management notified

**Partial failure — Policy B (recommended):**
- Confirmed method remains in `CONFIRMED`
- `PaymentComposition.compositionStatus` = `PARTIALLY_FAILED`
- Event `PartialPaymentFailed` emitted
- Customer can replace failed method without losing confirmed method

**Total failure:**
- All methods fail → `FAILED`
- No reversal needed (no method reached `CONFIRMED`)
- Event `CompositePaymentFailed` emitted

---

## Reliability Rules

| Rule | Criterion |
|---|---|
| Idempotency | Same `compositionId` does not create new state or new invoices if received again |
| Webhook idempotency | Duplicate webhook from Asaas does not trigger a duplicate `PartialPaymentConfirmed` event |
| Expiration | Composition without full confirmation in `X minutes` (to be defined by product) enters `EXPIRED` |
| Reversal atomicity | Composition reversal cancels ALL confirmed invoices or none |
| Non-regression | Simple payment (without `compositionId`) is not affected by any composition change |

---

## Not covered by this OBC

- Composition with more than 2 methods (post-MVP)
- Boleto as a partial method (requires analysis of asynchronous confirmation window)
- Composition with gift card / cashback (depends on internal balance entity — separate scope)
- Cross-tenant payment

---

## Failure modes and mitigations

| Failure mode | Probability | Mitigation |
|---|---|---|
| Out-of-order webhook (Charge B confirmed before A) | Low | Idempotent state machine; event only emitted when `allConfirmed` |
| Partial confirmation + order cancellation | Medium | Total cancellation contract must include reversal of confirmed methods |
| Asaas timeout on second charge | Medium | Retry with backoff + `PartialPaymentFailed` event after max retries |
| Divergence between `confirmedAmount` and sum of invoices | Low | Validation in `PaymentCompositionService` before emitting `CompositePaymentConfirmed` |

---

## Pending product decision

| Question | Options | Status |
|---|---|---|
| Partial failure policy | A (revert all), B (keep confirmed), C (partial window) | **Pending** |
| Expiration window | 5 min / 10 min / 30 min | **Pending** |
| Allowed MVP combinations | Pix+Card only / Pix+Card+Boleto | **Recommended: Pix+Card only** |

---

## Next step after decision

1. Fill in failure policy and expiration window above
2. Create BDD Feature: `prodops/journeys/discovery/experiments/007-split-payment-model/features/payment-composition.feature`
3. Execute `/upstream move-to-downstream` — will move OBC and BDD Feature to `artifacts/`
4. Update Iteration Plan to include Split Payment
5. Bootstrap → Hack

---

## References

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/artifacts/business/intents/split-payment.md`
