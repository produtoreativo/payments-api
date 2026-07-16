# ProdOps Operating Model

## ProdOps Architecture

ProdOps is organized in four hierarchical levels:

```
ProdOps Framework
       ↓
ProdOps Portfolio
       ↓
ProdOps Workspace
       ↓
Product Repository     ←  this repository (payments-api)
```

| Level | Responsibility | Does not contain |
|---|---|---|
| **Framework** | Principles, journeys, capabilities, skills, templates, glossary | Roadmap, Backlogs, Business Intents, Releases, Features |
| **Portfolio** | Global Tracking List, Roadmaps, Platform Releases, Milestones | Software implementation |
| **Workspace** | Integration and joint execution of Product Repositories | Roadmap, Business Intents |
| **Product Repository** | Implement and operate a specific product | — |

This repository (`payments-api`) is a **Product Repository**. It serves as the reference implementation of the ProdOps Framework. The Portfolio and Workspace levels exist in the architecture and are referenced in this documentation; they do not yet have physical repositories created.

→ See [glossary.en.md](glossary.en.md) for canonical definitions of each level.

---

## Operating model

ProdOps organizes product and engineering work in hierarchical layers, with traceable origin from the source of the need through to the produced artifacts:

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Intent → OBC Draft (Business Intent Backlog or Product Intent Backlog)
  ↓
Exploration (Icebox)
  ↔ Continuous Assessment → Reliability Plan → Assessment Review
  ↓
OBC + BDD committed
  ↓
Backlog Management (Diligence)        ← Repository Tracking List → Product Intent Backlog → Icebox → Iteration Backlog → Iteration Plan
  ↓
Execution Mode
├── Upstream
└── Downstream
  ↓
Journey
├── Discovery
├── Delivery
├── Operation
├── Assessment
└── Diligence
  ↓
Phase
├── Bootstrap
├── Hack
├── Sync
├── Finish
├── Ship
├── Validate
└── Promote
  ↓
Practice
└── ProdOps TDD
  ↓
Delivery Capability
├── Commit Workflow
├── Contract Management
├── Evidence Management
├── Observability
└── Reliability
  ↓
Artifacts
├── OBCs
├── BDD Features
├── Plans
├── Trails
└── Evidence
```

→ [Full flow: how each step works](flow.en.md)
→ [Origin Streams: the four types of origin](origin-streams.en.md)
→ [Backlog hierarchy: definitions and official model](backlogs.en.md)

---

**Origin Stream** — the classification of the origin of an Intent. Four possibilities: Business (market, customer, product), Enterprise (compliance, regulation, governance), Team (process, automations, productivity), Technology (platform, security, infrastructure). Every Intent has exactly one Origin Stream. See [`origin-streams.md`](origin-streams.en.md).

**Intent** — Framework entry point. An intention to generate value not yet committed. The Intent registers the "why" without prescribing the "how". *Formerly called Business Intent.*

**Exploration** — refines the OBC draft and reduces uncertainty through the Discovery journey. Discovery exists in both modes; rigor and commitment vary between Upstream and Downstream. See [`flow.md`](flow.en.md).

**OBC (Observable Business Contract)** — born as a Draft when the Intent enters the Business Intent Backlog (global flow) or the Product Intent Backlog (local flow). Refined through Discovery in the Icebox until reaching **Minimum OBC** (entry gate to the Iteration Backlog). Becomes **Active** during Delivery and **Operational** in Operation. *Formerly incorrectly defined as Outcome-Based Criterion.*

**Continuous Assessment** — continuously evaluates risks, opportunities, and decides the next step.

**Execution Mode** — the level of commitment and quality criteria applied:
- **Upstream** — permissive, experimental, no delivery commitment, variable maturity
- **Downstream** — delivery commitment with every current quality gate applied across journeys

**Journey** — the work path within an execution mode:
- Discovery, Delivery, Operation — classic journeys
- Assessment, Diligence — cross-cutting journeys

**Phase** — the sequence of stages within the Delivery journey:
- CI Sync: Bootstrap → Hack → Sync → Finish
- CI Async: Ship → Validate → Promote

**Practice** — the method used during a phase:
- ProdOps TDD (used by Hack)

**Delivery Capability** — reusable technical competencies consumed by the phases:
- Commit Workflow
- Contract Management
- Evidence Management
- Observability
- Reliability

**Artifacts** — artifacts produced and consumed by the Framework:
- OBCs, BDD Features, Plans, Trails, Evidence

---

## Journeys

### Discovery

Explores problems, hypotheses, and possibilities. Discovery exists in both Upstream and Downstream modes; it is not synonymous with either.

→ [prodops/journeys/discovery/README.en.md](../journeys/discovery/README.en.md)

### Delivery

Governed implementation. Uses the knowledge validated by Exploration to deliver with confidence. Requires committed OBC before starting.

→ [prodops/journeys/delivery/README.en.md](../journeys/delivery/README.en.md)

### Operation

Continuous operation. Runbooks, incidents, postmortems, operational trail.

→ [prodops/journeys/operation/](../journeys/operation/)

### Assessment

Cross-cutting journey. Evaluates risks, opportunities, OBCs, and Iteration Plans.

→ [prodops/journeys/assessment/README.en.md](../journeys/assessment/README.en.md)

### Diligence

Cross-cutting journey. Guardian of ProdOps work system consistency. Ensures that the state of each OBC remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

→ [prodops/journeys/diligence/README.en.md](../journeys/diligence/README.en.md)
→ [Managed backlog hierarchy](backlogs.en.md)

---

## Execution Modes

→ [prodops/execution-model/README.md](../execution-model/README.en.md)

---

## Product Capability lifecycle

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓ generates
Intent
  ↓ enters
Business Intent Backlog (global flow) or Product Intent Backlog (local flow) → OBC Draft
  ↓
Exploration (Discovery in Icebox) ↔ Assessment
  Experiment → learning → Decision Package
  Assessment → risks + Reliability Plan
  ↓ Assessment Review (PM + Tech Lead)
OBC committed + BDD Feature committed
  ↓ if approved
Iteration Plan (status: In)
  ↓ Downstream (Delivery)
Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
  ↓
Operation
```

---

## Principles

→ [principles.md](principles.en.md)

## Glossary

→ [glossary.md](glossary.en.md)

## Full flow

→ [flow.md](flow.en.md)

## Origin Streams

→ [origin-streams.md](origin-streams.en.md)
