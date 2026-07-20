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
| **Portfolio** | Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmaps (VIEW), Platform Releases (VIEW), Milestones | Software implementation |
| **Workspace** | Integration and joint execution of Product Repositories | Roadmap, Business Intents |
| **Product Repository** | Implement and operate a specific product | — |

This repository (`payments-api`) is a **Product Repository**. It serves as the reference implementation of the ProdOps Framework. The Portfolio and Workspace levels exist in the architecture and are referenced in this documentation; they do not yet have physical repositories created.

→ See [glossary.en.md](glossary.en.md) for canonical definitions of each level.

---

## GitHub in the Execution Space

GitHub is the canonical tool for tracking the **execution of work** on ProdOps artifacts. Artifacts (OBCs, BDD, Intents, etc.) live as Markdown files in the repository — never as GitHub Issues.

### GitHub Projects as management domains

| Domain | GitHub Project | Tracks work on |
|---|---|---|
| **Portfolio** | Portfolio GitHub Project | Work Items on Business Signals and Business Intents |
| **Product Repository** | Product Repository GitHub Project | Work Items on Business Intents, OBCs, BDD, and Plans |

### GitHub Project Views as projections

GitHub Project Views are projections over data — not separate backlogs:

**Portfolio GitHub Project Views:**
- Business Signals — all Business Signals
- Discovery — Business Signals under investigation
- Business Intent Backlog — accepted Business Intents
- Roadmap — Business Intents by horizon (now/next/later)
- Platform Releases — Business Intents by platform version
- Completed — delivered Business Intents

**Product Repository GitHub Project Views:**
- Product Backlog — all Business Intents
- Release Planning — Business Intents by release version
- Current Iteration — Business Intents in the current iteration
- Doing — Business Intents in execution
- Review — Business Intents under review
- Done — delivered Business Intents
- Reliability — Business Intents with active Reliability Plan
- Bugs — bug Business Intents

### Work Items — operation types

| Work Item Type | Artifacts typically affected | Examples of operation |
|---|---|---|
| **Business Signal Work Item** | Business Signal | Investigate, Prioritize, Generate Intent |
| **Business Intent Work Item** | Business Intent, OBC, BDD | Explore, Refine OBC, Review, Deliver |

A Work Item must always declare: Artifact Type, Artifact ID, Operation, Journey. → [Knowledge vs Execution](knowledge-vs-execution.en.md)

### External tools are optional sync only

Jira, Azure DevOps, and Linear may receive synchronized data from GitHub, but they are **not the source of truth** for work state. The OBC `.md` file is the source of truth for content and state. GitHub Issues track the work performed on the OBC — they are not representations of the OBC. Jira, Azure DevOps, and Linear are optional sync tools over GitHub, never canonical sources.

→ [Execution Mapping — operations per artifact](execution-mapping/README.en.md)
→ [Mapping Matrix](execution-mapping/matrix.en.md)
→ [Work Item Schema](execution-mapping/work-item-schema.en.md)

---

## Operating model

ProdOps organizes product and engineering work in hierarchical layers, with traceable origin from the source of the need through to the produced artifacts:

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Business Signal → Business Intent (with OBC draft as contract) in BIB or Product Backlog
  ↓
Exploration (Icebox)
  ↔ Continuous Assessment → Reliability Plan → Assessment Review
  ↓
OBC + BDD committed
  ↓
Backlog Management (Diligence)        ← Product Tracking List → Product Backlog → Icebox → Iteration Backlog → Iteration Plan
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

**Origin Stream** — the classification of the origin of a Business Signal. Four possibilities: Business (market, customer, product), Enterprise (compliance, regulation, governance), Team (process, automations, productivity), Technology (platform, security, infrastructure). Every Business Signal has exactly one Origin Stream. See [`origin-streams.md`](origin-streams.en.md).

**Business Signal** — any opportunity, hypothesis, problem, benchmark, or idea that deserves attention. Lives in the Portfolio Tracking List or Product Tracking List. Generates Business Intents when investigated and recognized as strategic.

**Business Intent** — a strategic decision to pursue value. May be created from a Business Signal or directly in the BIB. Lives in the Business Intent Backlog and, after OBC Partitioning, also in the Product Backlog. Has an OBC as its contract document (Global OBC is co-born in the BIB; Local OBCs are created by OBC Partitioning).

**Exploration** — refines the OBC draft and reduces uncertainty through the Discovery journey. Discovery exists in both modes; rigor and commitment vary between Upstream and Downstream. See [`flow.md`](flow.en.md).

**OBC (Observable Business Contract)** — born as a Draft when a Business Intent enters the Business Intent Backlog (global flow) or the Product Backlog (local flow). Refined through Discovery in the Icebox until reaching the **Committed** state (entry gate to the Iteration Backlog). Becomes **In Delivery** during Delivery and **Operational** in Operation.

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
Business Signal → Business Intent
  ↓ enters
Business Intent Backlog (global flow) or Product Backlog (local flow) → OBC Draft
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
