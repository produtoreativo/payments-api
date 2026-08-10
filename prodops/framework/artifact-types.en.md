# Canonical Artifact Types

This document defines the canonical artifact types of the ProdOps Framework: what each type represents, when it is born, which journey it belongs to, and how it relates to others.

For governance (owners, approvals, lifecycle), see [artifact-governance.en.md](artifact-governance.en.md).
For GitHub labels and fields, see [github-workspace.md](github-workspace.md).

---

## Product artifact chain

Product artifacts follow a progressive refinement chain — each one presupposes the previous:

```
Business Signal
    ↓ generates
Business Intent
    ↓ contains / originates
OBC (Global or Local)
    ↓ specifies behavior in
BDD Feature
    ↓ identifies risks documented in
Risk Register
    ↓ informs
Reliability Plan
```

Execution artifacts (`Iteration Plan`, `Context Capsule`, `Release Trail`) are produced during Delivery and consume the product artifacts above.

---

## Product artifacts

### `business-signal`

**What it is:** a market, customer, operational, or technical observation indicating something may need to change. Carries no solution — only the signal.

**Born when:** any team member identifies a pattern or problem worth attention. Can come from metrics, customer feedback, an incident, competitive analysis, or a strategic decision.

**Journey:** Assessment (capture and triage) → feeds Discovery or Operation.

**Canonical path:** `prodops/artifacts/business-signals/<id>.md`

**Relations:** generates a `business-intent` when the Product Owner approves the investigation.

---

### `business-intent`

**What it is:** a structured business intention — connects a `business-signal` to a solution hypothesis, defines the owner, and sets the execution mode (Upstream or Downstream).

**Born when:** the Product Owner approves a Business Signal and decides it will be investigated or built.

**Journey:** Discovery (both modes) → Delivery (Downstream).

**Canonical path:** `prodops/artifacts/business-intents/<id>.md`

**Relations:** originates an OBC (Global or Local). In Downstream, must have OBC Committed before entering the Iteration Plan.

---

### `global-obc`

**What it is:** an Observable Business Contract spanning multiple capabilities or the entire product. Defines the observable contract at platform or product level.

**Born when:** a platform-level Business Intent (Portfolio) is accepted and the scope is broad enough to cross multiple repositories.

**Journey:** Discovery (Portfolio), Assessment, Delivery (Workspace).

**Canonical path:** `prodops/artifacts/obcs/<slug>-global.md`

**Relations:** can be partitioned into multiple `local-obc` entries for specific repositories.

---

### `local-obc`

**What it is:** an Observable Business Contract for a specific capability within a Product Repository. Defines Business Outcome, Observable Events, SLIs, Reliability Rules, and Response Contract.

**Born when:** a Business Intent enters the Product Backlog — starts as Draft and evolves to Committed as Discovery progresses.

**Journey:** Discovery → Delivery → Operation → Assessment (retroactive).

**Canonical path:** `prodops/artifacts/obcs/<slug>.md`

**Possible statuses:** `Draft` → `Refining` → `Committed` → `In Delivery` → `Operational` → `Archived`

**Relations:** presupposed by `bdd-feature`, `reliability-plan`, `context-capsule`, and `release-trail`. Without OBC Committed, there is no entry into the Iteration Plan.

---

### `bdd-feature`

**What it is:** a behavioral specification in Gherkin format (Given/When/Then) describing the expected scenarios of the capability. It is the executable definition of what will be built.

**Born when:** the OBC reaches Committed status and the Tech Lead writes the scenarios that will guide the TDD cycle.

**Journey:** Delivery (Hack phase — Red → Green → Refactor cycle).

**Canonical path:** `prodops/artifacts/bdd/<slug>.feature`

**Relations:** presupposes `local-obc`. Consumed by the `hack-tdd-agent` and referenced by the `release-trail`.

---

### `risk-register`

**What it is:** a record of risks mapped for a capability or iteration — each risk with impact, probability, criticality, and resolution status.

**Born when:** the OBC is committed and risks are mapped before entering Downstream.

**Journey:** Assessment (identification) → Delivery (monitoring) → Operation (post-go-live review).

**Canonical path:** `prodops/artifacts/risks/risks.md` (consolidated register per product)

**Relations:** informs the `reliability-plan`. Unresolved risks block Promote without explicit acceptance.

---

## Execution artifacts

### `iteration-plan`

**What it is:** the active iteration plan — lists capabilities with `Entrou` status, maps DS-IDs to GitHub Issues, and records the history of completed iterations.

**Born when:** the team decides which capabilities will enter the next Delivery iteration.

**Journey:** Delivery (CI Sync and CI Async).

**Canonical path:** `prodops/artifacts/plans/iteration-plan.md`

**Relations:** presupposes `local-obc` Committed + `bdd-feature` + `risk-register`. Referenced by `context-capsule` and `release-trail`.

---

### `reliability-plan`

**What it is:** a reliability plan with risk analysis, initiative roadmap (P0/P1/P2), operational SLOs, and DoD criteria beyond the functional.

**Born when:** the capability meets at least one trigger: financial impact, external integration, committed SLO, or high risk in the `risk-register`.

**Journey:** Assessment (creation via Premortem) → Delivery (reference during Validate) → Operation (continuous monitoring).

**Canonical path:** `prodops/artifacts/plans/reliability/README.md`

**Relations:** references `local-obc` (SLIs), `risk-register`, and feeds the criteria of the `release-trail`.

---

### `context-capsule`

**What it is:** a technical summary generated during Bootstrap that concentrates everything the team needs to execute the Hack without re-reading source artifacts. Contains DS-ID, correlation-id, artifact paths, BDD scenarios, and current state.

**Born when:** the downstream-agent executes Plan Bootstrap (Step 3 — `Plan.Bootstrap.Issue.Entered`).

**Journey:** Delivery (exclusively — produced and consumed in CI Sync).

**Canonical path:** `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`

**Relations:** presupposes `local-obc`, `bdd-feature`, and `iteration-plan`. Consumed by the `hack-tdd-agent`.

---

### `release-trail`

**What it is:** formal evidence of delivery completion — produced by Finish after all quality gates pass. Records what was delivered, exit criteria, and validation evidence.

**Born when:** the Finish phase completes with all gates green (lint, build, acceptance, no_mocks).

**Journey:** Delivery (Finish phase) → Operation (historical reference) → Assessment (retroactive).

**Canonical path:** `prodops/artifacts/release-trail/<iteration-id>-<slug>.md`

**Relations:** references `local-obc`, `bdd-feature`, and `iteration-plan`. Consumed by retrospectives and retroactive Assessment.

---

## Knowledge artifacts

### `product-deck`

**What it is:** a single-page canvas that aggregates the essential information about a product — vision, services with SLOs, team, execution architecture, reliability matrix, analytics, and stakeholders. Inspired by Toyota's A3 Report.

**Born when:** the product exists as a recognized entity and the team needs a consolidated operational reference artifact — typically after the first service enters Operational.

**Journey:** cross-cutting — consumed by Assessment (premortems, maturity evaluation), Discovery (scope alignment), Delivery (Bootstrap context), and Operation (continuous metrics update).

**Canonical path:** `prodops/artifacts/product/product-deck.md` (one per product)

**Relations:** consumes `local-obc` (service SLOs), `reliability-plan` (Reliability Matrix), and `release-trail` (Product Analytics); consumed as input by premortems and Assessment.

→ Full definition: [`product-deck.en.md`](product-deck.en.md)

---

### `service-deck`

**What it is:** a single-page canvas that represents a service as a product — same sections as the Product Deck, but scoped to the service. A Product Service can be a `Service` (single deployable unit) or a `Value Stream` (logical grouping of multiple services). The Service Deck is the artifact that details each Product Services entry.

**Born when:** a service is listed in the Product Deck with a committed Local OBC — the Service Deck materializes that OBC's contracts as the operational view of the service.

**Journey:** cross-cutting — created when the OBC reaches Committed; updated in Operation (metrics, SLOs) and Assessment (risk and contract review).

**Canonical path:** `prodops/artifacts/services/<service-slug>/service-deck.md`

**Relations:** referenced by `product-deck` (Product Services); consumes `local-obc` (Service Endpoints: APIs, events, schemas, SLIs) and `reliability-plan`; feeds the Product Deck's Reliability Matrix.

→ Full definition: [`service-deck.en.md`](service-deck.en.md)

---

### `architecture`

**What it is:** an architectural decision or documentation — ADRs, component diagrams, technical decisions with context and consequences.

**Born when:** a relevant technical decision is made during Discovery, Delivery, or Operation.

**Journey:** Discovery (exploration), Delivery (decision), Operation (evolution).

**Canonical path:** `prodops/artifacts/architecture/`

**Relations:** may reference `local-obc` when the decision impacts the observable contract.

---

### `experiment`

**What it is:** the result of an Upstream experiment — hypothesis, methodology, results, and learnings. Does not presuppose delivery.

**Born when:** a Business Intent enters Upstream mode and the team executes a spike, prototype, or hypothesis test.

**Journey:** Discovery (Upstream exclusively).

**Canonical path:** `prodops/artifacts/experiments/<id>.md`

**Relations:** may evolve into a Downstream `business-intent` if learnings validate the hypothesis.

---

### `evidence`

**What it is:** a point-in-time piece of evidence for a phase — screenshot, log, test result, tool output. Complements the `release-trail` with specific detail.

**Born when:** any CI Sync or CI Async phase needs to record evidence that does not fit the narrative trail.

**Journey:** Delivery (any phase).

**Canonical path:** `prodops/artifacts/evidence/`

**Relations:** referenced by the `release-trail`.

---

## Internal Diligence types

These types are not product artifacts — they are outputs of the Diligence journey. They have no business templates, only operational structure.

| Type | What it is | Born when |
|---|---|---|
| `Finding` | An inconsistency, gap, or divergence detected by Diligence | Diligence Scan or Capture identifies a deviation |
| `Remediation` | A corrective action to resolve a Finding | A Finding is accepted and a concrete action is defined |
| `Waiver` | Explicit acceptance of a Finding without immediate correction | The team decides to live with the deviation for a defined period |
| `Check` | A point-in-time verification executed during Diligence Sync | Diligence reacts to a Delivery event |

Findings feed Assessment when they indicate a systemic pattern — they are not merely operational noise.

---

## References

→ [Artifact governance](artifact-governance.en.md) — owners, approvals, lifecycle
→ [Glossary](glossary.en.md) — canonical definitions of each concept
→ [GitHub Workspace](github-workspace.md) — labels and fields by type
→ [OBC: full specification](obc.en.md)
→ [Journeys](journeys/README.en.md)
