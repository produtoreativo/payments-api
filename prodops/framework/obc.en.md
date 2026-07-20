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

**Born at:** Business Intent Backlog, when a Business Intent is accepted.

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

The **Local OBC** represents the responsibility of **a single product**. In the global flow it specializes part of a Global OBC; in the local flow it directly represents a Business Intent accepted by the product. It belongs to exactly one Product Backlog.

**Focus:** product implementation and delivery.

**Belongs to:** Product Backlog of a specific product.

**Born at:** Product Backlog, through OBC Partitioning in the global flow or Owner Approval in the local flow.

**Relationship with its origin:** when originated by Portfolio, it is not a copy — it is a **specialization/partition** of the Global OBC and must reference it. When originated locally, it must reference the Business Intent and Product Tracking Item that justified Owner Approval.

**Contains:**
- Mandatory origin reference: Global OBC (global flow) or Business Intent + Product Tracking Item (local flow)
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
Global flow: Business Signal → Business Intent → Global OBC → N Local OBCs
Local flow:  Business Signal → Business Intent + Product Tracking Item → Local OBC
```

Never the inverse. Use the terms: **decomposition**, **specialization**, **partition**. NEVER use: parent, child, inheritance.

---

## OBC Partitioning

**OBC Partitioning** is the capability responsible for transforming a Global OBC into Local OBCs. It occurs between Discovery in the BIB and the creation of items in the products' Product Backlogs.

**Partitioning responsibilities:**
- Identify the products involved
- Identify the repositories
- Identify the Bounded Contexts
- Decompose the Global OBC
- Create the Local OBCs
- Maintain traceability between them

**Result:** each product receives a Local OBC in its Product Backlog. The Global OBC receives an updated traceability table with the Local OBCs created.

**Who executes:** Portfolio PM + Tech Leads of the involved products.

---

## The 4 OBC Dimensions

The OBC is the contract that simultaneously satisfies the 4 origin dimensions of a business intent:

| Dimension | Question it answers | OBC Sections |
|---|---|---|
| **Business** | What does the business need to achieve? | Goal, Business Value, KPIs, Business Rules, Events |
| **Enterprise** | What organizational constraints and standards apply? | Stakeholders, Value Stream, Dependencies, Compliance |
| **Team** | What does the team need to deliver with confidence? | BDD, Acceptance Criteria, Reliability Plan, Risks |
| **Technology** | How do architecture and systems support delivery? | APIs, Events, Observability, Response Contract, Technical Dependencies |

These dimensions correspond to the Framework's 4 Origin Streams. The OBC is not a perspective — it is the synthesis of all 4.

---

## States

States represent **contract maturity**, not software state.

| State | When | Description |
|---|---|---|
| **Draft** | BIB / Product Backlog — entry | Created; may be incomplete; records initial intent and hypotheses |
| **Refining** | Product Backlog — Icebox view | Under active refinement; Discovery/Upstream may be occurring |
| **Committed** | Product Backlog — Iteration Backlog view | Minimum information validated; ready for Delivery |
| **In Delivery** | Iteration Plan → Delivery | In execution; implementation in progress |
| **Operational** | Operation | In production; updated with operational evidence |
| **Archived** | — | Intent closed; history preserved |

---

## Lifecycle

### Global OBC

| Where the item is | Global OBC State | What happens |
|---|---|---|
| Portfolio Tracking List | Does not exist | Business Signal has not yet generated a recognized Business Intent |
| Business Intent Backlog | Draft | Global OBC created; captures Business Intent and initial hypotheses |
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
| Product Backlog — Icebox view | Refining | Discovery refines the Local OBC; criteria emerge |
| Assessment Review | Committed candidate | OBC reviewed by PM + Tech Lead; required sections validated |
| Product Backlog — Iteration Backlog view | Committed | Minimum criteria validated; Downstream can begin |
| Iteration Plan / Delivery | In Delivery | Guides implementation; BDD Feature operationalizes it |
| Operation | Operational | In production; complemented with metrics, SLOs, incidents |
| — | Archived | Intent closed |

The OBC records the **living history of the work**: which states it passed through, when, decisions made, how criteria evolved, references to experiments and risks.

---

## Traceability

Traceability must work in **both directions**.

**Global flow** (when the Business Intent comes from the Portfolio):
```
Business Signal (1:N) → Business Intent → Repository A
                                        → Repository B  (via Local OBCs — contract documents)
                                        → Repository C
```

> The OBC is not a separate sequential entity after the Intent — it is the Intent's contract document, progressively refined. OBC Partitioning creates Local OBC documents per involved product.

**Local flow** (when the Business Intent comes from the product):
```
Business Signal → Business Intent + Product Tracking Item → Local OBC → Repository
```

**Downward navigation:** from the Global OBC, reach any Local OBC and the repository that implements it.

**Upward navigation:** from any Local OBC, reach its origin: the Global OBC and original Business Intent (global flow), or the Business Intent and Product Tracking Item (local flow).

In the global flow, the Global OBC maintains the traceability table and each Local OBC references its originating Global OBC. In the local flow, the Local OBC references directly the Business Intent and the Product Tracking Item that justified Owner Approval.

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
| **Where born** | Product Backlog (after OBC Partitioning) |
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

Do not use OBC as a substitute for an isolated technical task or bug ticket without a corresponding Business Intent. GitHub Issues are **operational representations** of an entity already defined in the Framework (Business Signal or Business Intent) — they are not the entry point for work. The OBC is a Markdown document — it does not have an Issue representation. Jira, Azure DevOps, and Linear are optional sync tools over GitHub, never the canonical entry point.

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
