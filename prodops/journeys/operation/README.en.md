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

## Relationship With Other Journeys

- **Delivery** feeds Operation with releases and deploy evidence — Operation begins after Promote.
- **Assessment** receives signals from Operation to update risks and the Reliability Plan.
- **Diligence** observes the operation and triggers verifications when anomalies are detected.
- **Repository Tracking List** receives new items originating from operational learnings.
