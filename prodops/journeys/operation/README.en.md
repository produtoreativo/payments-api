# Operation

## Responsibility

Operate and evolve the product in production.

## When it begins

Operation begins after the delivery is promoted by the Promote phase of CI Async.

## What it does

- continuous operation of the product in production
- observability and monitoring
- incident response
- operational metrics collection
- postmortems and operational learning

Operational learnings can originate new items for the **Repository Tracking List**. This is the mechanism by which Operation feeds the product evolution cycle.

## Files

| File | Purpose |
|---|---|
| [incidents.md](incidents.md) | Incident registration and response |
| [postmortems.md](postmortems.md) | Postmortems and root cause analysis |
| [runbooks.md](runbooks.md) | Operational runbooks |
| [operational-trail.md](operational-trail.md) | Append-only trail of operational events |

## DORA as a Continuous Health Instrument

Continuous Assessment uses the extended DORA metrics to identify when the product needs a new improvement Intent. Operation is the primary source of signals that feed these metrics.

**Priority metrics at the current product stage (MVP → IPR):**

| DORA Metric | Weight at this stage | Operational signal | Action when deteriorating |
|---|---|---|---|
| Lead Time for Change | High (8→5) | Average time from commit to first event in production | Technology Intent: review pipeline and automation |
| Reaction Time | High (5→3) | Gap `webhook.received` → `payment.confirmed` | Technology Intent: review processing architecture |
| Release Frequency | Growing (5→8) | Deploy count per week | Team Intent: review delivery process |
| Change Fail Rate | Growing (3→5) | Rate of `*_failed` events correlated with deploys | Technology Intent: test quality and gates |
| MTTR | Growing (1→3) | Gap failure event → recovery by `correlationId` | Technology Intent: runbooks + alerts |
| Availability | Growing (2→3) | Success/failure ratio per OBC and time window | Technology Intent: SLO + error budget |
| Rate of Return | Growing (3→5) | Rate of `idempotency_hit` + `refund.requested` | Team Intent: validation process and quality |

**How Operation generates new Intents via DORA:**

```
Operational Trail detects DORA metric deterioration
  ↓
Continuous Assessment records signal in risks.md or opportunities.md
  ↓
New item in Repository Tracking List with identified Origin Stream
  ↓
Premortem + Owner Approval → Product Intent Backlog (Inception)
```

**OBC events that feed each DORA metric:**
→ See complete mapping in [`../../framework/dora-metrics.en.md`](../../framework/dora-metrics.en.md)

**Maturity assessment:** run periodically on Certificare with `balanced` profile (or as appropriate) to get a maturity score and improvement roadmap.

---

## Relationship With Other Journeys

- **Delivery** feeds Operation with releases and deploy evidence — Operation begins after Promote.
- **Assessment** receives signals from Operation to update risks and the Reliability Plan.
- **Diligence** observes the operation and triggers verifications when anomalies are detected.
- **Repository Tracking List** receives new items originating from operational learnings.
