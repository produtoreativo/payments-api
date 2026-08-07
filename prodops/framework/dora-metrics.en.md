# DORA Metrics — Extended Model

ProdOps adopts an extended DORA model of **7 metrics** that expands the 4 original metrics from the DORA Research Program with 3 product- and operation-oriented extensions. The weight of each metric varies by **product stage**, reflecting what matters most at each point in the lifecycle.

→ See [`product-stages.en.md`](product-stages.en.md) for stage definitions.
→ See [`glossary.en.md`](glossary.en.md) for canonical terms.
→ Assessment on the Certificare platform uses these metrics as the basis for delivery maturity evaluation.

---

## The 7 metrics

### DORA Core — the original 4

#### Lead Time for Change
**What it measures:** time between a code commit and it running in production.

**Why it matters:** the shorter, the faster the team learns and delivers value. In early stages (PoC/MVP), learning speed is everything.

**How to measure:** commit timestamp → timestamp of first OBC event after the production deploy.

**Current gap:** requires CI/CD → observability platform integration.

---

#### Release Frequency
**What it measures:** frequency of successful deployments to production.

**Why it matters:** high-performing teams deploy multiple times per day. In acceleration stages (MVR/MVT), high frequency signals a mature process.

**How to measure:** deployment count per period in the CI/CD pipeline.

**Current gap:** requires CI/CD → observability platform integration.

---

#### Change Fail Rate
**What it measures:** percentage of changes that cause observable failure or degradation in production.

**Why it matters:** in advanced stages (MVT/MLP), reliability is non-negotiable. A high post-deploy failure rate indicates insufficient quality or testing.

**How to measure:** OBC failure events (`*_failed`, `*_rejected`, `*_refused`) correlated with deploys in the preceding 30 minutes.

**OBC event pattern feeding this metric:**
Events with suffix `*_failed`, `*_rejected`, `*_refused`, `*_error` correlated with recent deploys. Product example (payments-api): `invoice.creation_failed`, `webhook.delivery.failed`.

→ Create your OBC → DORA mapping at `prodops/artifacts/experiments/<slug>/evidence/obc-dora-mapping.md`

---

#### Mean Time to Recovery (MTTR)
**What it measures:** mean time from failure detection to full recovery.

**Why it matters:** failures happen. What differentiates mature teams is recovery speed. In advanced stages (MVT/MLP), high MTTR is unacceptable.

**How to measure:** time gap between failure event and corresponding recovery event, by `correlationId` or domain entity identifier.

**Event pair pattern feeding this metric:**
`<entity>.creation_failed` → `<entity>.created`, `<entity>.delivery.failed` → `<entity>.delivery.sent`

---

### ProdOps Extensions — the 3 additional metrics

#### Reaction Time
**What it measures:** time between the arrival of an external signal and the first action processed by the system.

**Why it matters:** responsiveness metric. In early stages (PoC/MVP), high Reaction Time indicates slow architecture or manual processes. It is analogous to MTTD (Mean Time to Detect).

**How to measure:** gap between the received external signal event and the first corresponding internal processing event, by `correlationId`.

**Event pattern feeding this metric:**
`<signal>.received` → `<entity>.processed`, `<entity>.authorization.requested` → `<entity>.authorized`, `<signal>.delivery.sent` (delivery latency)

**Typical aligned SLIs:**
- Notification deliveries within X seconds — Y% (defined by product OBC)
- Confirmation outcomes within N minutes — Y% (defined by product OBC)

---

#### Rate of Return
**What it measures:** rate of defects escaped to production and rework generated — client retries, refunds, post-confirmation cancellations.

**Why it matters:** rework is an invisible cost. In MVR/MVT stages, high Rate of Return indicates quality problems consuming operational capacity.

**How to measure:** count of idempotency and refund events per time window.

**OBC event pattern feeding this metric:**
Events with suffix `*_idempotency_hit`, `*_refund.requested`, `*_refund.required`, `*_retry`. Product example (payments-api): `invoice.idempotency_hit`, `payment.card.refund.requested`.

---

#### Availability
**What it measures:** percentage of time the service is available and responding correctly.

**Why it matters:** in advanced stages (MVT/MLP), availability is a product survival criterion.

**How to measure:** ratio of success events to total attempts per time window.

**Event ratio pattern feeding this metric:**
`<entity>.created` / (`<entity>.created` + `<entity>.creation_failed`),
`<entity>.confirmed` / external confirmation signals received,
`<signal>.delivery.sent` / (`<signal>.delivery.sent` + `<signal>.delivery.failed`)

**Typical aligned SLIs:** availability SLIs defined in product OBCs (e.g., 99%, 99.9%, 100%) are directly Availability metrics.

---

## Weights by product stage

Weights reflect what matters most at each moment. Scale 1–8: higher means more relevant for maturity assessment at that stage.

| Metric | PoC | MVP | IPR | MVR | MVT | MLP |
|---|---|---|---|---|---|---|
| Lead Time for Change | 8 | 8 | 5 | 5 | 3 | 3 |
| Reaction Time | 8 | 5 | 3 | 3 | 2 | 1 |
| Release Frequency | 2 | 5 | 8 | 8 | 8 | 5 |
| Change Fail Rate | 1 | 3 | 5 | 5 | 8 | 8 |
| Mean Time to Recovery | 1 | 1 | 3 | 5 | 8 | 8 |
| Availability | 1 | 2 | 3 | 5 | 8 | 8 |
| Rate of Return | 3 | 3 | 5 | 8 | 8 | 5 |

**Reading:** at PoC/MVP, learning speed dominates (Lead Time and Reaction Time at weight 8). At MVT/MLP, reliability dominates (Change Fail Rate, MTTR, and Availability at weight 8).

---

## Assessment profiles

Each product can adopt a profile that reweights the metrics according to its current focus.

| Profile | Focus | Prioritized metrics |
|---|---|---|
| `balanced` | Balance speed, quality, and reliability | All equally weighted |
| `velocity` | Reduce cycle time, increase frequency | Lead Time, Reaction Time, Release Frequency |
| `quality` | Reduce defects, regressions, rework | Change Fail Rate, Test Coverage, Test Pass Rate, Rate of Return |
| `reliability` | Stability, availability, recovery | Availability, MTTR, Rollback Health |
| `ai_readiness` | Quality and traceability for AI adoption | Change Fail Rate (9), Test Coverage (9), Test Pass Rate (9), MTTR (7), Availability (7) |
| `custom` | Team-defined weighting | Custom |

---

## Supplementary metrics

Used in specific profiles (especially `quality` and `ai_readiness`):

| Metric | What it measures |
|---|---|
| **Test Coverage** | Percentage of code covered by automated tests |
| **Test Pass Rate** | Percentage of tests passing in the current suite |
| **Rollback Health** | Ability to revert a deploy without data loss or incident |

---

## Maturity scale (0–5)

| Level | Name | Description |
|---|---|---|
| 0 | Inexistent | No established practices |
| 1 | Initial | Ad-hoc practices, no repeatability |
| 2 | Repeatable | Basic practices exist but are not systematic |
| 3 | Defined | Documented processes consistently followed |
| 4 | Managed | Metrics collected and used for decisions |
| 5 | Excellence | Continuous optimization based on data |

**Top-down evaluation strategy:** starts at level 5 and drops at the first mandatory criterion that does not pass. A level is only reached when all mandatory criteria at that level are satisfied.

---

## How to use in the product context

1. **Identify the current stage** of the product → see [`product-stages.en.md`](product-stages.en.md)
2. **Choose the assessment profile** according to the current focus
3. **Read the weights** from the table above for the current stage
4. **Map the Observable Events** from OBCs to the metrics → see `evidence/obc-dora-mapping.md`
5. **Configure dashboards** with the event ratios that feed each metric
6. **Run the assessment** on Certificare to get a maturity score and roadmap

---

## References

→ [Product Stages](product-stages.en.md)
→ [Glossary](glossary.en.md)
→ OBC → DORA Mapping: `prodops/artifacts/experiments/<slug>/evidence/obc-dora-mapping.md` (created by the product)
→ [Operation Journey](journeys/operation/README.en.md)
→ [Reliability Plans](../artifacts/plans/reliability/README.en.md)
