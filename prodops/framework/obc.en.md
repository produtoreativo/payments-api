# OBC — Observable Business Contract

The **Observable Business Contract** is the living contract that represents a business intent throughout its entire lifecycle. It is the source of truth for the work — connecting business, product, architecture, engineering, operation, observability, and reliability. No other document should play this role.

The OBC exists at two distinct levels: **Global OBC** and **Local OBC**. They are not hierarchical in the inheritance sense — they are scope specializations.

→ [Global OBC Template](../templates/obcs/global-obc.en.md)
→ [Local OBC Template](../templates/obcs/local-obc.en.md)
→ [Product OBCs](../artifacts/business/obcs/)
→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)

---

## The two OBC levels

### Global OBC

The **Global OBC** represents a complete business intention — independent of products, teams, or repositories. It is the canonical contract of the business capability.

**Focus:** strategic.

**Belongs to:** platform (BIB). Never to a product.

**Born at:** Business Intent Backlog, when an Intent is accepted.

**Lives throughout:** the entire lifecycle of the intention — it does not disappear after decomposition. It continues evolving during Discovery, Delivery, and Operation.

**Contains:**
- Business Goal
- Business Value
- Stakeholders
- Business Rules
- Business Events
- KPIs / Expected Outcomes
- Value Stream
- Products involved (when known)
- Local OBC traceability

**Does not contain:** implementation details, specific APIs, repositories, BDD, technical acceptance criteria.

**Location:** Platform portfolio repository (external to product repositories).

---

### Local OBC

The **Local OBC** represents the responsibility of **a single product**. In the global flow it specializes part of a Global OBC; in the local flow it directly represents an Intent accepted by the product. It belongs to exactly one Product Intent Backlog.

**Focus:** product implementation and delivery.

**Belongs to:** Product Intent Backlog of a specific product.

**Born at:** Product Intent Backlog, through OBC Partitioning in the global flow or Owner Approval in the local flow.

**Relationship with its origin:** when originated by Portfolio, it is not a copy — it is a **specialization/partition** of the Global OBC and must reference it. When originated locally, it must reference the Intent and Repository Tracking Item that justified Owner Approval.

**Contains:**
- Mandatory origin reference: Global OBC (global flow) or Intent + Repository Tracking Item (local flow)
- Product / Repository / Bounded Context
- APIs and Events
- BDD / Acceptance Criteria
- Observability (Observable Events)
- Reliability Rules
- Response Contract
- Technical Dependencies
- Evidence

**Location:** `prodops/artifacts/business/obcs/<slug>.md`

---

## Relationship between levels

```
Global flow: 1 Global OBC → N Local OBCs
Local flow:  1 local Intent → 1 Local OBC
```

Never the inverse. Use the terms: **decomposition**, **specialization**, **partition**. NEVER use: parent, child, inheritance.

---

## OBC Partitioning

**OBC Partitioning** is the capability responsible for transforming a Global OBC into Local OBCs. It occurs between Discovery in the BIB and the creation of items in the products' PIBs.

**Partitioning responsibilities:**
- Identify the products involved
- Identify the repositories
- Identify the Bounded Contexts
- Decompose the Global OBC
- Create the Local OBCs
- Maintain traceability between them

**Result:** each product receives a Local OBC in its PIB. The Global OBC receives an updated traceability table with the Local OBCs created.

**Who executes:** Portfolio PM + Tech Leads of the involved products.

---

## States

States represent **contract maturity**, not software state.

| State | When | Description |
|---|---|---|
| **Draft** | BIB / PIB — entry | Created; may be incomplete; records initial intent and hypotheses |
| **Refining** | PIB — Icebox view | Under active refinement; Discovery/Upstream may be occurring |
| **Committed** | PIB — Iteration Backlog view | Minimum information validated; ready for Delivery |
| **In Delivery** | Iteration Plan → Delivery | In execution; implementation in progress |
| **Operational** | Operation | In production; updated with operational evidence |
| **Archived** | — | Intent closed; history preserved |

---

## Lifecycle

### Global OBC

| Where the item is | Global OBC State | What happens |
|---|---|---|
| Global Tracking List | Does not exist | Signal is not yet a recognized Intent |
| Business Intent Backlog | Draft | Global OBC created; captures Intent and initial hypotheses |
| BIB — Roadmap view | Draft | Item positioned in strategic horizon |
| BIB — Platform Release view | Draft | Item grouped in platform version |
| Discovery (BIB) | Refining | Exploration refines the Global OBC; hypotheses tested |
| OBC Partitioning | Refining | Local OBCs created; traceability established |
| Operation | Operational | Updated with consolidated evidence from all products |
| — | Archived | Intent closed |

### Local OBC

| Where the item is | Local OBC State | What happens |
|---|---|---|
| OBC Partitioning | Draft | Local OBC created with reference to the Global OBC |
| PIB — Icebox view | Refining | Discovery refines the Local OBC; criteria emerge |
| Assessment Review | Committed candidate | OBC reviewed by PM + Tech Lead; required sections validated |
| PIB — Iteration Backlog view | Committed | Minimum criteria validated; Downstream can begin |
| Iteration Plan / Delivery | In Delivery | Guides implementation; BDD Feature operationalizes it |
| Operation | Operational | In production; complemented with metrics, SLOs, incidents |
| — | Archived | Intent closed |

The OBC records the **living history of the work**: which states it passed through, when, decisions made, how criteria evolved, references to experiments and risks.

---

## Traceability

Traceability must work in **both directions**.

```
Business Intent → Global OBC → Local OBC A → Repository A
                             → Local OBC B → Repository B
                             → Local OBC C → Repository C
```

**Downward navigation:** from the Global OBC, reach any Local OBC and the repository that implements it.

**Upward navigation:** from any Local OBC, reach the Global OBC and the original business Intent.

The Global OBC maintains the traceability table. Each Local OBC maintains the link back to the Global OBC.

---

## Continuous OBC Refinement

The OBC is never considered finished. It continues evolving during:
- **Discovery:** new hypotheses and experiments update the contract
- **Delivery:** implementation decisions refine the criteria
- **Operation:** operational evidence, incidents, and postmortems enrich the contract

Every new piece of evidence updates the contract. The OBC is a living document — not an artifact generated once and archived.

---

## OBC in Upstream

During Upstream, the OBC remains in Draft or Refining. It can be freely modified, may be incomplete, and does not block experiments. It records learnings, hypotheses, and decisions produced by experiments. No Skill should require a complete OBC during Upstream.

OBCs produced within Upstream experiments remain in the experiment directory (`prodops/journeys/discovery/experiments/<NNN-slug>/obcs/`) until formal promotion.

**Note on modes:** Upstream and Downstream are **execution modes**, not phases or stages. An item can start Upstream at any lifecycle stage — when finished, it returns to the original stage. The mode never changes the stage.

---

## OBC in Downstream

Upon entering Downstream, the Local OBC ceases to be merely a record — it becomes the operational contract of the delivery. It is refined in the Icebox until reaching the Committed state, then controls the entire evolution of subsequent journeys.

Commitment may be declared before readiness. The minimum set required to reach **Downstream Ready** and start a Delivery phase is:
- Local OBC committed in `prodops/artifacts/business/obcs/<slug>.md` with Committed state
- BDD Feature committed in `prodops/artifacts/business/bdd/<slug>.feature`
- Documented risks and an `In` Iteration Plan entry
- Updated Reliability Plan when there is money movement, an external integration, an SLO change, high/critical risk, or a persistence or security change

---

## OBC and Skills

All Downstream Skills use the Local OBC as their primary source of context. Skills never generate parallel information that replaces the OBC. New artifacts produced by Skills complement or reference the OBC. The OBC remains the single source of truth for the intent.

---

## Governance

### Global OBC

| Field | Value |
|---|---|
| **Owner** | Portfolio PM |
| **Where born** | Business Intent Backlog |
| **Canonical artifact** | Platform portfolio repository (external to product repositories) |
| **Who modifies** | Portfolio PM, Tech Leads (with change record) |
| **Who approves** | Portfolio PM |
| **Consumers** | Local OBCs, OBC Partitioning, Roadmap, Platform Release |
| **Lifecycle** | Draft → Refining → Operational → Archived |
| **Journeys** | Discovery (BIB), Operation |

### Local OBC

| Field | Value |
|---|---|
| **Owner** | Product Manager + Tech Lead of the product |
| **Where born** | Product Intent Backlog (after OBC Partitioning) |
| **Canonical artifact** | `prodops/artifacts/business/obcs/<slug>.md` (when committed) |
| **Who modifies** | Product Manager, Tech Lead, engineers (with change record) |
| **Who approves** | Product Manager + Tech Lead (Assessment Review) |
| **Consumers** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Lifecycle** | Draft → Refining → Committed → In Delivery → Operational → Archived |
| **Journeys** | Discovery, Delivery, Operation, Assessment, Diligence |

---

## Artifact location

| Situation | Location |
|---|---|
| Exploratory OBC (in Upstream experiment) | `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` |
| Committed Global OBC | Platform portfolio repository (external to this repository) |
| Committed Local OBC | `prodops/artifacts/business/obcs/<slug>.md` |

---

## When not to use

Do not use OBC as a substitute for an isolated technical task or bug ticket without a corresponding Intent. GitHub Issues, Jira Cards, and Azure DevOps Work Items are **operational representations** of an already-existing OBC — they are not the entry point for work.

---

## References

→ [Global OBC Template](../templates/obcs/global-obc.en.md)
→ [Local OBC Template](../templates/obcs/local-obc.en.md)
→ [Product OBCs](../artifacts/business/obcs/)
→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)
→ [Artifact Governance](artifact-governance.en.md)
→ [Phases: Conception and Inception](phases.en.md)
→ [Discovery Journey](../journeys/discovery/README.en.md)
→ [Reliability Plans](../journeys/assessment/reliability-plans/README.en.md)
