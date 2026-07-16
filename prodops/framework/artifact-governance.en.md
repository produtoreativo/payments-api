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

- Manages the Global Tracking List, Business Intent Backlog, Global OBCs, Roadmap, Platform Releases, and Milestones.
- Executes OBC Partitioning to decompose Global OBCs into Local OBCs.
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
- Governs Repository Tracking List, Product Intent Backlog, Icebox, Iteration Backlog, Iteration Plan, Local OBCs, Reliability Plans.
- This repository (`payments-api`) is a Product Repository.

---

## Global flow (Portfolio → Product)

```
Global Tracking List
  ↓ recognized as Intent
Business Intent Backlog       ← Global OBC Draft born here
  ↓ Discovery in BIB
OBC Partitioning              ← Global OBC → Local OBCs
  ↓ Local OBCs routed
Product Intent Backlog        ← Local OBC Draft arrives here (or born locally)
```

## Local flow (Product)

```
Repository Tracking List
  ↓ Premortem + Preliminary Risk Analysis + Owner Approval
Product Intent Backlog        ← Local OBC Draft born here if not yet existing
```

## Convergence — Delivery flow

```
Product Intent Backlog
  ↓ Discovery (Icebox)
Icebox                        ← Local OBC in Refining state
  ↓ Committed Local OBC validated
Iteration Backlog             ← Local OBC in Committed state
  ↓ committed Local OBC + committed BDD
Iteration Plan                ← Local OBC in Implemented state
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation                     ← Local OBC and Global OBC in Operational state
  ↓
Continuous OBC Refinement
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
| **Consumers** | Roadmap, OBC Partitioning, Product Intent Backlog (via Local OBCs) |
| **OBC** | Global OBC Draft created upon entry to this backlog |
| **Lifecycle** | Intent accepted → Global OBC Draft created → Discovery → OBC Partitioning → distributed to PIBs |
| **Journeys** | Assessment (Portfolio), Discovery (Upstream/Downstream) |

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
| **Consumers** | Product Intent Backlog (via Premortem + Preliminary Risk Analysis + Owner Approval), Assessment |
| **Entry criteria** | Any business, technical, or operational signal without commitment |
| **Exit criteria** | Approved by Product Owner → Product Intent Backlog; or discarded |
| **Journeys** | Assessment, Diligence, Operation (as destination of operational learnings) |

### Product Intent Backlog

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — convergence point of global and local flows |
| **Canonical artifact** | Managed by Diligence; instances tracked in the Iteration Plan |
| **Who modifies** | Product Owner + Diligence |
| **Who approves** | Product Owner (Owner Approval mandatory for local flow) |
| **Consumers** | Icebox, Assessment |
| **OBC** | Local OBC Draft created upon entry (if not already existing via OBC Partitioning) |
| **Entry criteria** | Global flow: Local OBC via OBC Partitioning; Local flow: Premortem + Preliminary Risk Analysis + Owner Approval |
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
| **OBC** | Local OBC in Refining state (Discovery); reaches Committed upon exit |
| **Entry criteria** | Item accepted in Product Intent Backlog |
| **Exit criteria** | Committed Local OBC validated → Iteration Backlog |
| **Journeys** | Discovery (Downstream), Assessment |

### Iteration Backlog

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — item with Committed Local OBC exiting the Icebox |
| **Canonical artifact** | `prodops/artifacts/plans/iteration-backlog.md` |
| **Who modifies** | Product Owner, Diligence |
| **Who approves** | Product Owner (prioritization) |
| **Consumers** | Iteration Plan |
| **OBC** | Local OBC in Committed state (upon exit to Iteration Plan) |
| **Entry criteria** | Committed Local OBC + BDD Feature draft |
| **Exit criteria** | committed Local OBC file + committed BDD Feature + Iteration Plan entry |
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
| **OBC** | Local OBC in Implemented state (during Delivery) |
| **Entry criteria** | committed Local OBC + committed BDD Feature + Reliability Plan |
| **Exit criteria** | Delivery completed + evidence recorded |
| **Journeys** | Delivery, Diligence |

### Global OBC

→ **Full definition, composition, lifecycle, and governance:** [`obc.en.md`](obc.en.md)

| Field | Value |
|---|---|
| **Owner** | Portfolio PM |
| **Where born** | Business Intent Backlog |
| **Canonical artifact** | `prodops/artifacts/obcs/global/<slug>.md` |
| **Lifecycle** | Draft → Refining → Operational → Archived |
| **Journeys** | Discovery (BIB), Operation |

### Local OBC

→ **Full definition, composition, lifecycle, and governance:** [`obc.en.md`](obc.en.md)

| Field | Value |
|---|---|
| **Owner** | Product Manager + Tech Lead of the product |
| **Where born** | Product Intent Backlog (after OBC Partitioning or local flow Owner Approval) |
| **Canonical artifact** | `prodops/artifacts/obcs/local/<slug>.md` (when committed) |
| **Lifecycle** | Draft → Refining → Committed → Implemented → Operational → Archived |
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
| Business Intent Backlog | Portfolio PM | Portfolio PM | Portfolio PM | Roadmap, OBC Partitioning |
| Roadmap | Portfolio | Portfolio PM | Portfolio Leadership | Platform Release |
| Platform Release | Portfolio | Portfolio Manager | Portfolio Leadership | PIB, Workspace |
| Repository Tracking List | Product Owner | Any team member | Product Owner | PIB (via approval) |
| Product Intent Backlog | Product Owner | PO + Diligence | Product Owner | Icebox |
| Icebox | Product Owner | Product Team | PO + Tech Lead | Iteration Backlog |
| Iteration Backlog | Product Owner | PO + Diligence | Product Owner | Iteration Plan |
| Iteration Plan | Tech Lead / PO | Delivery team | PO + Tech Lead | Delivery, Release Trail |
| Global OBC | Portfolio PM | Portfolio PM, Tech Leads | Portfolio PM | Local OBCs, Roadmap |
| Local OBC | PM + Tech Lead | PM, TL, engineers | PM + Tech Lead (Assessment Review) | Delivery, BDD, Release Trail |
| Reliability Plan | Tech Lead + SRE | TL, SRE, engineers | TL + PO | Iteration Plan, Delivery |
| BDD Feature | Tech Lead | PM, TL, engineers | Tech Lead | Hack, tests, Release Trail |
| Release Trail | Delivery team | Delivery team (append-only) | — | Operation, retrospectives |

---

## References

→ [Backlog hierarchy](backlogs.en.md)
→ [OBC: full lifecycle](obc.en.md)
→ [Operating model](operating-model.en.md)
→ [Official flow](flow.en.md)
