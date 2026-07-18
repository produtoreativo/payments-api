# Diligence — Cross-cutting Journey

## What it is

Diligence is the ProdOps Framework's cross-cutting journey responsible for keeping the work system synchronized and consistent throughout the product lifecycle.

> **Canonical principle:** Diligence is the guardian of ProdOps work system consistency. It ensures that the state of each Observable Business Contract remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

---

## Purpose

Close the gap between decisions produced by Assessment and work ready for Delivery. Diligence does not evaluate the product — that is Assessment's responsibility. It ensures that what was decided is reflected in all backlogs, tools, and management artifacts before Delivery needs that context.

---

## Problem it solves

Without Diligence, the work system fragments:

- A committed OBC exists in `prodops/artifacts/business/obcs/`, but the corresponding GitHub Issue was never created.
- An item was prioritized for the next Release, but the Product Tracking List was not updated.
- A risk identified in the Premortem appears in the plans, but was not reflected in the Icebox or the Iteration.
- The OBC state evolved, but external tools (Jira, GitHub Projects) still show the old state.
- An experiment ended with a decision made, but the Roadmap was not updated.

Diligence detects these gaps and corrects them before they cause confusion, rework, or decisions based on outdated state.

---

## Position in the Framework

```
Assessment              → produces decisions, OBCs, plans
Diligence               → synchronizes the state of those decisions across all backlogs and tools
Delivery                → consumes organized and traceable work
Operation               → feeds new signals back to Assessment and Diligence
```

Diligence continuously observes all journeys. It is activated by:

- New decisions from Assessment
- Concluded experiments in Discovery
- New risks or incidents in Operation
- Strategic changes to the Roadmap
- Detected divergences between artifacts and tools

---

## Principles

### 1. Synchronization, not implementation

Diligence never implements software. Never creates implementation Pull Requests. Never modifies product code. Its scope is the work system: backlogs, OBCs, management tools, ProdOps artifacts.

### 2. OBC as permanent identifier

The OBC is born when a Business Intent enters the Business Intent Backlog (global flow) or the Product Backlog (local flow). From that point, it accompanies the work throughout its entire life. Diligence uses the OBC as an anchor for all consistency checks. Every tool, every backlog, every artifact must be traceable back to an OBC.

### 3. Single state, multiple representations

A committed OBC has a single canonical state — recorded in `prodops/artifacts/business/obcs/`. GitHub Issues, Jira Cards, Azure DevOps Work Items are operational representations of that state in different tools. Diligence ensures those representations stay synchronized with the source of truth.

### 4. Continuity, not ceremony

Diligence has no beginning and end per cycle. It accompanies the product as long as it exists. It is not a weekly meeting or a sprint ritual. It is a continuous check that occurs every time the system state changes.

### 5. End-to-end traceability

Business Signal → Business Intent → OBC → Issue → PR → Release → Operation. Diligence ensures that every link in this chain is traceable. A gap at any point is an inconsistency that needs to be corrected.

---

## Responsibilities

### Backlog synchronization

Keep the state of each OBC synchronized across Product Tracking List, Product Backlog, Icebox, Iteration Backlog, Iteration Plan, and the corresponding external tools.

### Creating and updating operational representations

Create or update GitHub Issues, Jira Cards, and other operational representations when an OBC advances to the Iteration Backlog or Iteration Plan.

### Delivery prerequisites verification

Ensure all mandatory prerequisites are satisfied before an item enters Delivery: committed OBC, committed BDD Feature, Iteration Plan entry, documented risks. Verify whether a Reliability Plan exists — if so, confirm it was reviewed before the readiness decision (recommended, not mandatory).

### Divergence detection

Proactively identify gaps between the state of OBCs in ProdOps artifacts and the state in external tools.

### Management artifact evolution

Update management artifacts (Iteration Plan, Product Backlog, Roadmap entries) when Assessment decisions or Discovery results change the state of the work.

---

## What Diligence does NOT do

- Does not implement software or modify product code.
- Does not create implementation Pull Requests.
- Does not make product decisions — that is Assessment's responsibility.
- Does not substitute Assessment in risk evaluation or criteria definition.
- Does not execute Delivery phases (Bootstrap, Hack, Sync, Finish).

---

## Relationship with other journeys

| Journey | Relationship with Diligence |
|---|---|
| Discovery | Diligence updates backlogs and tools when experiments conclude with a decision made |
| Assessment | Diligence synchronizes Assessment decisions in backlogs and operational representations |
| Delivery | Diligence ensures work arrives at Delivery organized, traceable, and with prerequisites satisfied |
| Operation | Diligence receives signals of new risks and incidents to update backlogs and plans |

---

## Governed work system

Diligence governs the complete ProdOps Framework backlog hierarchy.

**Global flow (Portfolio → Product):**

```
Portfolio Tracking List
      │  Business Signal → Business Intent
      ▼
Business Intent Backlog   ← OBC Draft born here
      │
      ▼
Roadmap                   [VIEW over BIB]
      │
      ▼
Platform Release          [VIEW over BIB]
      │  accepted by Product Owner
      ▼
Product Backlog
```

**Local flow (Product):**

```
Product Tracking List
      │  Premortem + Reliability Plan + Owner Approval
      ▼
Product Backlog           ← OBC Draft born here if not yet existing
```

**Convergence — Delivery flow:**

```
Product Backlog
      │
      ▼
Icebox                    ← Downstream Discovery occurs here
      │  minimum OBC validated
      ▼
Iteration Backlog
      │  OBC committed + BDD committed
      ▼
Iteration Plan
      │
      ▼
Delivery
```

→ [Hierarchy definitions and official model](../../framework/backlogs.en.md)

---

## Evolution

Diligence can evolve to include automated checks, consistency dashboards, and automatic alerts when divergences are detected between artifacts. Automation serves the journey — it does not replace it. The decision to correct a divergence always involves human judgment about the impact on the product and work in progress.
