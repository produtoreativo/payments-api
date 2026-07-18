# payments-api — Product Repository

This repository is a **Product Repository** within the ProdOps architecture — the level responsible for implementing and operating a specific product. The documentation in this directory teaches the complete ProdOps architecture, of which this repository occupies only the last level.

```
ProdOps Framework  →  ProdOps Portfolio  →  ProdOps Workspace  →  Product Repository
                                                                    (this repository)
```

→ [Full architecture and definitions](framework/operating-model.en.md#prodops-architecture)

> **Language note:** This framework is authored in Portuguese. See [why this project is in Portuguese](language.md).

## Official flow

```
Origin Stream → Business Signal → Global or Local Flow → Local OBC Draft in Product Backlog → Mode (Upstream | Downstream) → Discovery + Assessment → Assessment Review → committed OBC/BDD → Iteration Backlog (VIEW) → Iteration Plan → Delivery → Operation
```

→ [Full flow explained](framework/flow.en.md)
→ [The four Origin Streams](framework/origin-streams.en.md)

## Operating model

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Business Signal → Business Intent → OBC draft (BIB or Product Backlog)
  ↔ Continuous Assessment → Reliability Plan
  ↓ Assessment Review
Execution Mode → Journey → Phase → Practice → Delivery Capability → Artifacts
```

→ [Full operating model](framework/operating-model.en.md)

## Reading order

1. `framework/principles.en.md` — principles
2. `framework/glossary.en.md` — canonical terms
3. `framework/canonical-paths.en.md` — canonical locations
4. `framework/flow.en.md` — official Framework flow
5. `framework/origin-streams.en.md` — the four Origin Streams
6. `framework/operating-model.en.md` — full operating model
7. `execution-model/README.en.md` — Upstream vs Downstream
8. `journeys/README.en.md` — the 5 journeys
9. The specific journey for the task
10. The phase within the journey
11. The phase capabilities

## Portal

| Area | Description |
|---|---|
| [framework/](framework/) | Principles, glossary, flow, Origin Streams, operating model |
| [artifacts/business/intents/](artifacts/business/intents/) | Registered Business Intents |
| [execution-model/](execution-model/) | Upstream and Downstream as execution modes |
| [journeys/](journeys/) | The 5 journeys: Discovery, Delivery, Operation, Assessment, Diligence |
| [artifacts/](artifacts/) | Produced artifacts: OBCs, BDD Features, plans, trails, evidence |
| [templates/](templates/) | Centralized templates by area |
| [skills/](skills/) | Executable skills for agents |
| [journeys/delivery/capabilities/commit-workflow/](journeys/delivery/capabilities/commit-workflow/) | Commit Workflow: native Git hooks, scripts, documentation |
| [documentation-review.en.md](documentation-review.en.md) | Framework documentation review and state |
