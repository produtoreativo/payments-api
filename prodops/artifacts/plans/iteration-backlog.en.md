# Iteration Backlog — Operational Demands

> **Purpose:** Items with minimum OBC validated, ready for immediate Delivery. The only remaining decision is the priority defined by the Product Owner. This backlog is not for refinement — refinement happens in the Icebox.
>
> Items here can enter Delivery as soon as prioritized. To enter the Iteration Plan, they need OBC committed + BDD Feature committed.
>
> → [Backlog hierarchy](../../framework/backlogs.en.md)
> → [Approved delivery scope](iteration-plan.en.md) — to see what's in/out/deferred

## Objective

Record items that have completed Discovery in the Icebox and are ready for Delivery execution. Each item must already have a Minimum OBC validated.

| ID | Area | Request | Type | Priority | Status | Next Step |
|----|------|---------|------|----------|--------|-----------|
| TL-001 | Marketing | Add Analytics to track the payment journey and results. | Business Observability | High | Open | Refine required KPIs, events and dashboards. |
| TL-002 | Sales | Track payment and cancellation indicators. | Business KPI | High | Open | Define metrics, data sources and executive reports. |
| TL-003 | Architecture | Deploy DataDog (MS-0172), instrument the Notifier, and ensure Payments is fully instrumented. | Technical Observability | High | Open | Draft instrumentation plan and update the Reliability Plan. |
| TL-004 | Infrastructure | Integrate the Payments team into Magazine Siará's corporate Incident Management model. | Operation / Reliability | Medium | Open | Define process, runbooks, on-call, and ITSM integrations. |

---

# Criteria to exit the Iteration Backlog

An item leaves the Iteration Backlog when:

- It has been refined sufficiently to compose an OBC.
- It has been discarded by business decision.
- It has been consolidated into an epic or Iteration Plan.
- It has been implemented and closed.

---

# Relationship with ProdOps artifacts

Each item may originate or update:

- Product Deck
- Service Deck
- Observable Business Contract (OBC)
- Reliability Plan
- Iteration Plan
- Iteration Backlog

The Repository Tracking List represents demands still under evaluation and serves as the main input source for Continuous Assessment.
