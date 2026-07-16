# ProdOps Artifact Governance

This document defines the governance of all ProdOps Framework artifacts: where each artifact is born, who is responsible, who can modify it, who approves changes, who consumes it, and which journeys it participates in.

→ [Backlog hierarchy](backlogs.en.md)
→ [Operating model](operating-model.en.md)

---

## Governance Principles

1. **Each artifact has exactly one Owner.** No artifact has two owners.
2. **Each artifact has a single source of truth.** The same artifact must not exist duplicated in two repositories.
3. **Every artifact belongs to exactly one architecture level.** Framework, Portfolio, Workspace, or Product Repository.
4. **Approvals occur only at points defined by the Framework.** No implicit or ad hoc approvals.
5. **Every artifact has a clearly defined lifecycle.** Creation, evolution, and closure are documented.
6. **Skills never generate information that replaces the OBC.** New artifacts produced by Skills complement or reference the OBC.

---

## Role of each architecture level

### Framework (ProdOps Framework)

- Defines standards, journeys, templates, Skills, validations, and canonical terminology.
- Does not govern products, Roadmaps, or product backlogs.
- Provides the model that other levels adopt.
- Repository: `prodops-framework` (canonical reference; documented in this repository as reference implementation).

### Portfolio (ProdOps Portfolio)

- Manages the Global Tracking List, Business Intent Backlog, Roadmap, Platform Releases, and Milestones.
- Decides what the platform delivers, when, and in what sequence.
- Does not implement software directly.
- Repository: `prodops-portfolio` (not yet created; concepts documented here as reference).

### Workspace (ProdOps Workspace)

- Integrates multiple Product Repositories for joint execution and testing.
- Does not govern Backlogs, does not govern Roadmaps, does not create Business Intents.
- Coordinates exclusively the integrated execution between Product Repositories.
- Repository: `prodops-workspace` (not yet created; concepts documented here as reference).

### Product Repository

- Implements and operates a specific product.
- Governs Repository Tracking List, Product Intent Backlog, Icebox, Iteration Backlog, Iteration Plan, OBCs, Reliability Plans.
- This repository (`payments-api`) is a Product Repository.

---

## Global flow (Portfolio → Product)

```
Global Tracking List
  ↓ recognized as Intent
Business Intent Backlog       ← OBC Draft born here
  ↓ prioritized
Roadmap
  ↓ committed to a release
Platform Release
  ↓ accepted by Product Owner
Product Intent Backlog
```

## Local flow (Product)

```
Repository Tracking List
  ↓ Premortem + Reliability Plan + Owner Approval
Product Intent Backlog        ← OBC Draft born here if not yet existing
```

## Convergence — Delivery flow

```
Product Intent Backlog
  ↓ Discovery (Icebox)
Icebox
  ↓ Minimum OBC validated
Iteration Backlog
  ↓ OBC committed + BDD committed
Iteration Plan
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation
```

---

## Governance of Platform artifacts

### Global Tracking List

| Field | Value |
|---|---|
| **Owner** | Portfolio (Portfolio Product Manager) |
| **Where born** | Portfolio — any platform signal without sufficient understanding |
| **Repository** | `prodops-portfolio` (external; referenced, not replicated) |
| **Who modifies** | Portfolio Product Manager, authorized stakeholders |
| **Who approves** | Portfolio Product Manager |
| **Consumers** | Business Intent Backlog, Assessment (Portfolio) |
| **Lifecycle** | Item created → investigated → recognized as Intent (advances to Business Intent Backlog) or discarded |
| **Journeys** | Assessment (Portfolio) |

### Business Intent Backlog

| Field | Value |
|---|---|
| **Owner** | Portfolio (Portfolio Product Manager) |
| **Where born** | Portfolio — Intent recognized in the Global Tracking List |
| **Repository** | `prodops-portfolio` (external) |
| **Who modifies** | Portfolio Product Manager |
| **Who approves** | Portfolio Product Manager |
| **Consumers** | Roadmap, Product Intent Backlog (via Platform Release) |
| **OBC** | Draft created upon entry to this backlog |
| **Lifecycle** | Intent accepted → OBC Draft created → Discovery → Roadmap or discarded |
| **Journeys** | Assessment (Portfolio), Discovery (Upstream) |

### Roadmap

| Field | Value |
|---|---|
| **Owner** | Portfolio |
| **Where born** | Portfolio — Business Intent prioritized for a strategic horizon |
| **Repository** | External tool (GitHub Projects, Jira, Azure DevOps) |
| **Who modifies** | Portfolio Product Manager |
| **Who approves** | Portfolio Leadership |
| **Consumers** | Platform Release, Product Repositories |
| **Lifecycle** | Intent prioritized → enters Roadmap → committed to Platform Release |
| **Journeys** | Assessment (Portfolio), Diligence |

### Platform Release

| Field | Value |
|---|---|
| **Owner** | Portfolio |
| **Where born** | Portfolio — set of Business Intents committed for coordinated delivery |
| **Repository** | `prodops-portfolio` (external) |
| **Who modifies** | Portfolio Manager |
| **Who approves** | Portfolio Leadership |
| **Consumers** | Product Intent Backlog (Product Repositories), Workspace |
| **Lifecycle** | Planned → committed → distributed to repositories → validated in Workspace |
| **Journeys** | Delivery (Workspace), Assessment (Portfolio) |

---

## Governance of Product Repository artifacts

### Repository Tracking List

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — any local signal not yet understood |
| **Canonical artifact** | `prodops/artifacts/product/tracking-list.md` |
| **Who modifies** | Any team member |
| **Who approves** | Product Owner |
| **Consumers** | Product Intent Backlog (via Premortem + Reliability Plan + Owner Approval), Assessment |
| **Entry criteria** | Any business, technical, or operational signal without commitment |
| **Exit criteria** | Approved by Product Owner → Product Intent Backlog; or discarded |
| **Journeys** | Assessment, Diligence, Operation (as destination of operational learnings) |

### Product Intent Backlog (formerly: Committed Backlog)

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — convergence point of global and local flows |
| **Canonical artifact** | Managed by Diligence; instances tracked in the Iteration Plan |
| **Who modifies** | Product Owner + Diligence |
| **Who approves** | Product Owner (Owner Approval mandatory for local flow) |
| **Consumers** | Icebox, Assessment |
| **OBC** | Draft created upon entry (if not already existing via Business Intent Backlog) |
| **Entry criteria** | Global flow: Platform Release accepted by Product Owner; Local flow: Premortem + Reliability Plan + Owner Approval |
| **Exit criteria** | Item accepted in Icebox for Discovery |
| **Journeys** | Assessment, Diligence |

### Icebox

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — item accepted in Product Intent Backlog |
| **Canonical artifact** | `prodops/artifacts/product/icebox-backlog.md` |
| **Who modifies** | Product Team (Product Manager, Tech Lead, engineers) |
| **Who approves** | Product Owner + Tech Lead (for exit from Icebox) |
| **Consumers** | Iteration Backlog |
| **OBC** | Draft under refinement (Discovery); reaches Minimum OBC upon exit |
| **Entry criteria** | Item accepted in Product Intent Backlog |
| **Exit criteria** | Minimum OBC validated → Iteration Backlog |
| **Journeys** | Discovery (Downstream), Assessment |

### Iteration Backlog

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — item with Minimum OBC exiting the Icebox |
| **Canonical artifact** | `prodops/artifacts/plans/iteration-backlog.md` |
| **Who modifies** | Product Owner, Diligence |
| **Who approves** | Product Owner (prioritization) |
| **Consumers** | Iteration Plan |
| **OBC** | Minimum OBC → Committed (upon exit to Iteration Plan) |
| **Entry criteria** | Minimum OBC + BDD Feature draft |
| **Exit criteria** | OBC committed + BDD Feature committed + Iteration Plan entry |
| **Journeys** | Diligence, Assessment |

### Iteration Plan

| Field | Value |
|---|---|
| **Owner** | Tech Lead / Product Owner |
| **Where born** | Product Repository — ongoing iteration execution |
| **Canonical artifact** | `prodops/artifacts/plans/iteration-plan.md` |
| **Who modifies** | Delivery team |
| **Who approves** | Product Owner + Tech Lead (for item entry) |
| **Consumers** | Delivery (CI Sync, CI Async), Release Trail |
| **OBC** | Active (during Delivery) |
| **Entry criteria** | OBC committed + BDD Feature committed + Reliability Plan |
| **Exit criteria** | Delivery completed + evidence recorded |
| **Journeys** | Delivery, Diligence |

### Observable Business Contract (OBC)

| Field | Value |
|---|---|
| **Owner** | Product Manager + Tech Lead of the item |
| **Where born** | Business Intent Backlog (global flow) or Product Intent Backlog (local flow) |
| **Canonical artifact** | `prodops/artifacts/obcs/<slug>.md` (when committed) |
| **Who modifies** | Product Manager, Tech Lead, engineers (with change record) |
| **Who approves** | Product Manager + Tech Lead (Assessment Review) |
| **Consumers** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Lifecycle** | Draft → Minimum OBC → Active → Operational → Archived |
| **Journeys** | Discovery, Delivery, Operation, Assessment, Diligence |

### Reliability Plan

| Field | Value |
|---|---|
| **Owner** | Tech Lead + SRE |
| **Where born** | Assessment — produced during Premortem or Assessment Review |
| **Canonical artifact** | `prodops/journeys/assessment/reliability-plans/` |
| **Who modifies** | Tech Lead, SRE, engineers |
| **Who approves** | Tech Lead + Product Owner |
| **Consumers** | Iteration Plan, Delivery, Operation |
| **Entry criteria** | Premortem completed; risks identified |
| **Exit criteria** | Approved before entry into Iteration Plan |
| **Journeys** | Assessment, Delivery, Operation |

---

## Responsibility matrix

| Artifact | Owner | Who modifies | Who approves | Main consumers |
|---|---|---|---|---|
| Global Tracking List | Portfolio PM | Portfolio PM + stakeholders | Portfolio PM | Business Intent Backlog |
| Business Intent Backlog | Portfolio PM | Portfolio PM | Portfolio PM | Roadmap, PIB |
| Roadmap | Portfolio | Portfolio PM | Portfolio Leadership | Platform Release |
| Platform Release | Portfolio | Portfolio Manager | Portfolio Leadership | PIB, Workspace |
| Repository Tracking List | Product Owner | Any team member | Product Owner | PIB (via approval) |
| Product Intent Backlog | Product Owner | PO + Diligence | Product Owner | Icebox |
| Icebox | Product Owner | Product Team | PO + Tech Lead | Iteration Backlog |
| Iteration Backlog | Product Owner | PO + Diligence | Product Owner | Iteration Plan |
| Iteration Plan | Tech Lead / PO | Delivery team | PO + Tech Lead | Delivery, Release Trail |
| OBC | PM + Tech Lead | PM, TL, engineers | PM + Tech Lead (Assessment Review) | Delivery, BDD, Release Trail |
| Reliability Plan | Tech Lead + SRE | TL, SRE, engineers | TL + PO | Iteration Plan, Delivery |
| BDD Feature | Tech Lead | PM, TL, engineers | Tech Lead | Hack, tests, Release Trail |
| Release Trail | Delivery team | Delivery team (append-only) | — | Operation, retrospectives |

---

## References

→ [Backlog hierarchy](backlogs.en.md)
→ [OBC: full lifecycle](glossary.en.md#obc-observable-business-contract)
→ [Operating model](operating-model.en.md)
→ [Official flow](flow.en.md)
