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

- Manages the Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmap (VIEW over BIB), Platform Releases (VIEW over BIB), and Milestones.
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
- Governs Product Tracking List (Business Signals), Product Backlog (Business Intents), Icebox (VIEW), Iteration Backlog (VIEW), Release (VIEW), Iteration Plan, OBCs, Reliability Plans.
- This repository (`payments-api`) is a Product Repository.

---

## Global flow (Portfolio → Product)

```
Portfolio Tracking List
  ↓ Business Signal generates Business Intent
Business Intent Backlog       ← Global OBC Draft born here
  ↓ prioritized
  ├─ Roadmap [VIEW over BIB]
  └─ Platform Release [VIEW over BIB]
  ↓ accepted by Product Owner
Product Backlog
```

## Local flow (Product)

```
Product Tracking List
  ↓ Business Signal → Business Intent + Owner Approval
Product Backlog               ← Local OBC Draft born here if not yet existing
```

## Convergence — Delivery flow

```
Product Backlog
  ↓ VIEW Icebox — Discovery
Icebox [VIEW]
  ↓ OBC Committed
Iteration Backlog [VIEW]
  ↓ OBC committed + BDD committed
Iteration Plan
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation
```

---

## Governance of Platform artifacts

### Portfolio Tracking List

| Field | Value |
|---|---|
| **Owner** | Portfolio (Portfolio Product Manager) |
| **Contains** | ONLY Business Signals |
| **Where born** | Portfolio — any platform Business Signal without sufficient understanding |
| **Repository** | `prodops-portfolio` (external; referenced, not replicated) |
| **Who modifies** | Portfolio Product Manager, authorized stakeholders |
| **Who approves** | Portfolio Product Manager |
| **Consumers** | Business Intent Backlog (when Business Signal generates a Business Intent) |
| **Lifecycle** | Business Signal created → investigated → generates Business Intent (advances to BIB) or discarded |
| **Journeys** | Assessment (Portfolio) |

### Business Intent Backlog

| Field | Value |
|---|---|
| **Owner** | Portfolio (Portfolio Product Manager) |
| **Contains** | ONLY Business Intents |
| **Where born** | Portfolio — Business Intent generated from a Business Signal in Portfolio Tracking List |
| **Repository** | `prodops-portfolio` (external) |
| **Who modifies** | Portfolio Product Manager |
| **Who approves** | Portfolio Product Manager |
| **Consumers** | Roadmap (VIEW), Platform Release (VIEW), Product Backlog (via OBC Partitioning) |
| **OBC** | Global OBC Draft created upon entry to this backlog |
| **Lifecycle** | Business Intent accepted → Global OBC Draft created → Discovery → Roadmap/Platform Release (VIEWs) or discarded |
| **Journeys** | Assessment (Portfolio), Discovery (Upstream) |

### Roadmap (VIEW over Business Intent Backlog)

| Field | Value |
|---|---|
| **Owner** | Portfolio |
| **Nature** | VIEW over the Business Intent Backlog — not a separate backlog |
| **Where born** | Portfolio — Business Intent positioned in a strategic horizon |
| **Repository** | GitHub Projects (Views of the Portfolio GitHub Project) |
| **Who modifies** | Portfolio Product Manager |
| **Who approves** | Portfolio Leadership |
| **Consumers** | Platform Release (VIEW), Product Repositories |
| **Lifecycle** | Business Intent positioned in horizon → committed to Platform Release |
| **Journeys** | Assessment (Portfolio), Diligence |

### Platform Release (VIEW over Business Intent Backlog)

| Field | Value |
|---|---|
| **Owner** | Portfolio |
| **Nature** | VIEW over the Business Intent Backlog — not a separate backlog |
| **Where born** | Portfolio — set of Business Intents grouped for coordinated delivery |
| **Repository** | `prodops-portfolio` (external) / GitHub Projects (Views of the Portfolio GitHub Project) |
| **Who modifies** | Portfolio Manager |
| **Who approves** | Portfolio Leadership |
| **Consumers** | Product Backlog (Product Repositories via OBC Partitioning), Workspace |
| **Lifecycle** | Planned → committed → distributed to repositories → validated in Workspace |
| **Journeys** | Delivery (Workspace), Assessment (Portfolio) |

---

## Governance of Product Repository artifacts

### Product Tracking List

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Contains** | ONLY Business Signals |
| **Where born** | Product Repository — any local Business Signal not yet understood |
| **Canonical artifact** | `prodops/artifacts/product/backlogs/tracking-list.md` |
| **Who modifies** | Any team member |
| **Who approves** | Product Owner |
| **Consumers** | Product Backlog (when Business Signal generates a Business Intent via Premortem + Owner Approval) |
| **Entry criteria** | Any Business Signal — business, technical, or operational — without commitment |
| **Exit criteria** | Approved by Product Owner → generates Business Intent + enters Product Backlog; or discarded |
| **Journeys** | Assessment, Diligence, Operation (as destination of operational learnings) |

### Product Backlog

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Contains** | ONLY Business Intents (each Intent has a Local OBC as its contract document) |
| **Where born** | Product Repository — convergence point of global and local flows |
| **Canonical artifact** | Managed by Diligence; instances tracked in the Iteration Plan |
| **Who modifies** | Product Owner + Diligence |
| **Who approves** | Product Owner (Owner Approval required for local flow) |
| **Consumers** | VIEW Icebox (Assessment, Discovery), VIEW Iteration Backlog (Delivery) |
| **OBC** | Local OBC Draft created upon entry (if not already existing via OBC Partitioning) |
| **Entry criteria** | Global flow: Local OBC via OBC Partitioning accepted by Product Owner; Local flow: Business Signal → Business Intent + Premortem + Owner Approval |
| **Exit criteria** | Item enters the Icebox VIEW for Discovery |
| **Journeys** | Assessment, Diligence |

### Icebox

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — item accepted in Product Backlog (VIEW over Product Backlog) |
| **Canonical artifact** | `prodops/artifacts/product/backlogs/icebox-backlog.md` |
| **Who modifies** | Product Team (Product Manager, Tech Lead, engineers) |
| **Who approves** | Product Owner + Tech Lead (for exit from Icebox) |
| **Consumers** | Iteration Backlog |
| **OBC** | Refining (Discovery); reaches Committed upon exit |
| **Entry criteria** | Item in Product Backlog with Local OBC in Draft state |
| **Exit criteria** | OBC Committed → Iteration Backlog |
| **Journeys** | Discovery (Downstream), Assessment |

### Iteration Backlog

| Field | Value |
|---|---|
| **Owner** | Product Owner |
| **Where born** | Product Repository — item with OBC Committed exiting the Icebox |
| **Canonical artifact** | `prodops/artifacts/product/backlogs/iteration-backlog.md` |
| **Who modifies** | Product Owner, Diligence |
| **Who approves** | Product Owner (prioritization) |
| **Consumers** | Iteration Plan |
| **OBC** | Committed |
| **Entry criteria** | OBC Committed + BDD Feature draft |
| **Exit criteria** | OBC committed + BDD Feature committed + Iteration Plan entry |
| **Journeys** | Diligence, Assessment |

### Iteration Plan

| Field | Value |
|---|---|
| **Owner** | Tech Lead / Product Owner |
| **Where born** | Product Repository — ongoing iteration execution |
| **Canonical artifact** | `prodops/artifacts/governance/plans/iteration-plan.md` |
| **Who modifies** | Delivery team |
| **Who approves** | Product Owner + Tech Lead (for item entry) |
| **Consumers** | Delivery (CI Sync, CI Async), Release Trail |
| **OBC** | In Delivery (during Delivery) |
| **Entry criteria** | Committed OBC + committed BDD Feature + Reliability Plan when canonical risk triggers apply |
| **Exit criteria** | Delivery completed + evidence recorded |
| **Journeys** | Delivery, Diligence |

### Observable Business Contract (OBC)

| Field | Value |
|---|---|
| **Owner** | Product Manager + Tech Lead of the item |
| **Where born** | Business Intent Backlog (global flow) or Product Backlog (local flow) |
| **Canonical artifact** | `prodops/artifacts/business/obcs/<slug>.md` (when committed) |
| **Who modifies** | Product Manager, Tech Lead, engineers (with change record) |
| **Who approves** | Product Manager + Tech Lead (Assessment Review) |
| **Consumers** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Lifecycle** | Draft → Refining → Committed → In Delivery → Operational → Archived |
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
| **Exit criteria** | Approved before entry into Iteration Plan — applicable only when canonical triggers are present |
| **Journeys** | Assessment, Delivery, Operation |

---

## Responsibility matrix

| Artifact | Owner | Who modifies | Who approves | Main consumers |
|---|---|---|---|---|
| Portfolio Tracking List | Portfolio PM | Portfolio PM + stakeholders | Portfolio PM | Business Intent Backlog |
| Business Intent Backlog | Portfolio PM | Portfolio PM | Portfolio PM | Roadmap (VIEW), Platform Release (VIEW), Product Backlog |
| Roadmap (VIEW over BIB) | Portfolio | Portfolio PM | Portfolio Leadership | Platform Release |
| Platform Release (VIEW over BIB) | Portfolio | Portfolio Manager | Portfolio Leadership | Product Backlog, Workspace |
| Product Tracking List | Product Owner | Any team member | Product Owner | Product Backlog (via approval) |
| Product Backlog | Product Owner | PO + Diligence | Product Owner | VIEW Icebox, VIEW Iteration Backlog |
| Icebox (VIEW) | Product Owner | Product Team | PO + Tech Lead | VIEW Iteration Backlog |
| Iteration Backlog (VIEW) | Product Owner | PO + Diligence | Product Owner | Iteration Plan |
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
