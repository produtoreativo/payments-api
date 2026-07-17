# Backlog Hierarchy

The ProdOps Framework organizes work in two hierarchical flows: a **platform** flow (Portfolio) and a **product** flow (Product Repository). Each backlog answers a single question and has well-defined responsibilities.

Work never skips levels without explicit justification recorded in the OBC.

---

## Global Flow — Platform → Product

```
Global Tracking List       ← What deserves attention on the platform?
          ↓
Business Intent Backlog    ← What deserves Discovery? (Global OBC Draft born here)
    │         │
    │         ├─ Roadmap          [view: in which strategic horizon?]
    │         └─ Platform Release [view: in which platform version?]
    │
    │   (Discovery in the BIB)
          ↓
OBC Partitioning           ← Global OBC → Local OBCs (one per product)
          ↓
Product Intent Backlog     ← product source of truth (Local OBC lives here)
    │         │
    │         ├─ Icebox           [view: in refinement — Refining state]
    │         ├─ Iteration Backlog [view: committed — Committed state]
    │         └─ Release          [view: grouped by release version]
    │
    │   (item with Committed Local OBC + BDD + criteria satisfied)
          ↓
Iteration Plan             ← current iteration execution
          ↓
Delivery
          ↓
Operation                  ← Continuous OBC Refinement
```

> **Roadmap and Platform Release are not queues** — they are projections over BIB items.
> **Icebox, Iteration Backlog, and Release are also not queues** — they are projections over PIB items. An item does not leave the PIB when entering one of these views; it remains in the PIB and receives a state that determines which view represents it.

---

## Local Flow — Product

```
Repository Tracking List   ← What deserves attention in this product?
          ↓
Premortem + Preliminary Risk Analysis
          ↓
Owner Approval
          ↓
Product Intent Backlog     ← product source of truth (Local OBC born here)
[continues in the common flow — Icebox/Iteration Backlog/Release as views]
```

> **Note on Reliability Plan in the local flow:** The pre-PIB step requires a Premortem and preliminary risk analysis. The formal Reliability Plan is produced by Assessment during the Icebox and becomes a Delivery gate when there is money movement, an external integration, an SLO change, high/critical risk, or a persistence or security change.

After entering the **Product Intent Backlog**, the item's origin no longer matters. All items follow exactly the same journey — regardless of whether they came from the Portfolio or the local flow.

---

## Platform Backlogs

### Global Tracking List

**Question:** What deserves attention on the platform?

**Purpose:** Capture signals whose scope is undefined or spans more than one product. The signal belongs to the platform — it is not yet clear which product or team will resolve it.

**When to use:** The signal involves business, value chain, multiple products, or the entire platform. Problem ownership is not yet clear. Examples: market opportunities without a defined product, regulatory changes affecting multiple systems, cross-cutting platform initiatives.

**When not to use:** The signal already has a clear destination — a specific product or team that clearly owns the resolution. In that case, the signal belongs in that product's Repository Tracking List.

**Independence:** Items in the Global Tracking List are not copied to candidate products' Repository Tracking Lists. The item stays in the Global until triaged and routed. There is no duplication between the two flows.

**Contains:** Ideas, opportunities, problems, demands, compliance, improvements, risks — any signal of undetermined scope.

**Does not contain:** OBC. Commitment. Permanent identifier.

**When to advance:** When the item has been understood enough to be recognized as an Intent and enter the Business Intent Backlog.

**Managed by:** Portfolio.

---

### Business Intent Backlog

**Question:** What deserves Discovery?

**Purpose:** Represent Intents accepted for Discovery at the platform level. This is where the **Global OBC** is born as a Draft. The BIB contains only Global OBCs — never Local OBCs.

**What happens when an item enters this backlog:**
- The Intent receives a permanent identifier.
- A **Global OBC Draft** is created — captures the Intent and initial business hypotheses.
- The lifecycle of the work begins.

**Commitment:** The Intent is accepted for Discovery. No implementation commitment yet. Products, repositories, and the number of Local OBCs are still unknown at this point.

**Dimensions over the BIB:** Items in the BIB can receive strategic dimensions without leaving it:
- **Roadmap** — positions the item in a delivery horizon (now, next, later).
- **Platform Release** — associates the item with the platform version it belongs to.

An item can be in the BIB, associated with a Roadmap, and linked to a Platform Release simultaneously. These dimensions are projections — not queues the item passes through sequentially.

**When the item leaves the BIB:** After Discovery in the BIB and OBC Partitioning, the Portfolio routes the created Local OBCs to the Product Intent Backlogs of the involved products.

**Managed by:** Portfolio.

---

### OBC Partitioning

**What it is:** Capability responsible for transforming the Global OBC into Local OBCs — one per involved product. Occurs after Discovery in the BIB, before creating items in the products' PIBs.

**Responsibilities:**
- Identify the products involved in the implementation
- Identify the corresponding repositories
- Identify the Bounded Contexts
- Decompose the Global OBC into responsibility partitions
- Create the Local OBCs with reference to the Global OBC
- Maintain the traceability table in the Global OBC

**Result:** each product receives a Local OBC in its PIB. The Global OBC records the traceability of all Local OBCs.

**Who executes:** Portfolio PM + Tech Leads of the involved products.

---

### Roadmap

**Nature:** Strategic view over the Business Intent Backlog — not a queue. Items do not "enter" the Roadmap; they remain in the BIB and receive a position in the strategic horizon.

**Question:** In which delivery horizon does this item fit?

**Purpose:** Organize the strategic sequence of BIB items by horizon (now / next / later), Milestones, and cross-product dependencies. Allows the Portfolio to communicate intent without committing to delivery.

**What it represents:** A temporal projection of BIB items — which will be addressed in which time window.

**Is not:** A task list. Items on the Roadmap still live in the BIB and can be removed, reprioritized, or redirected without a formal removal process.

**Commitment:** Strategic intent, not delivery commitment. Delivery only becomes a commitment when the item enters a product's Product Intent Backlog.

**Managed by:** Portfolio. Lives in external strategic management tools.

---

### Platform Release

**Nature:** Grouping view over the Business Intent Backlog — not a queue. Items do not "pass through" the Platform Release; they remain in the BIB and are associated with a platform version.

**Question:** Which BIB items compose this platform version?

**Purpose:** Group BIB items that form a coherent platform delivery — a combination of Product Repository versions to be released together.

**Example:**
- Platform Release 3.0 = payments-api v3 + webshop-api v8 + order-api v2

**What it represents:** A strategic grouping of BIB items by platform version. It is the Portfolio's decision of which products and versions will be coordinated in the same delivery.

**Relationship with PIB:** Associating an item with a Platform Release may precede or accompany routing to a product's PIB — but does not replace it. The item only enters the product flow when the Portfolio explicitly routes it to the PIB.

**Responsibility:** Product Repositories do not control the Platform Release. Responsibility belongs exclusively to the Portfolio.

**Managed by:** Portfolio.

---

## Product Backlogs

### Repository Tracking List

**Question:** What deserves attention in this product?

**Purpose:** Capture signals already directed at this specific product or team. Ownership is defined — it is known that the problem belongs here.

**When to use:** The signal has a clear destination: this product, this team. No platform triage needed. Examples: bug identified in this service, internal technical debt, performance improvement opportunity in this domain, signal from this product's postmortem or operation.

**When not to use:** The signal is too broad, involves multiple products, or ownership is not yet clear. In that case, the signal belongs in the Global Tracking List.

**Independence:** The Repository Tracking List is autonomous — it does not depend on the Global Tracking List and does not receive copies from it. A signal that arrives here already has a defined destination and follows directly through the local flow (Premortem + Owner Approval → PIB), without going through the Portfolio.

**Contains:** Bugs, technical debt, architecture, observability, performance, security, costs, internal improvements, signals from operation and postmortems.

**Does not contain:** OBC. Commitment. Permanent identifier.

**When to advance:** Via Premortem + Preliminary Risk Analysis + Owner Approval → Product Intent Backlog.

**Canonical artifact:** `prodops/artifacts/product/backlogs/tracking-list.md`

---

### Product Intent Backlog

**Nature:** Backlog — source of truth for all work accepted by the product. Items live here from acceptance through delivery. Icebox, Iteration Backlog, and Release are projections over these items, not separate destinations.

**Question:** What has been officially accepted by the Product Owner?

**Contains exclusively:** Local OBCs. The PIB never contains Global OBCs.

**Two entry paths:**

| Origin | Entry path |
|---|---|
| Platform | Local OBC created by OBC Partitioning, routed by Portfolio after Discovery in BIB |
| Local | Repository Tracking Item promoted via Premortem + Preliminary Risk Analysis with Owner Approval |

**What happens when an item enters:**
- The Product Owner formalizes acceptance.
- If it didn't exist yet (local path), a **Local OBC Draft** is created.
- The item begins its traceable lifecycle in the product.
- The item receives the initial state **Draft**. When active Discovery starts, it transitions to **Refining** and is represented in the Icebox view.

**After entry, the origin no longer matters.** The item evolves in state within the PIB: Draft → Refining (Icebox) → Committed (Iteration Backlog) → In Delivery (Iteration Plan) → Operational.

> **Upstream promotion:** An item promoted from Upstream that satisfies the Committed criteria skips Icebox refinement and appears in the Iteration Backlog view. The Product Owner must still select it explicitly for the Iteration Plan.

**Commitment:** The Product Owner has committed to investigating and delivering this item.

---

### Icebox

**Nature:** View over the PIB — not a separate queue. Represents PIB items that are still in refinement: incomplete Local OBC, open decisions, Discovery in progress.

**Question:** Which PIB items are still being refined for Delivery?

**What it represents:** An item is in the Icebox view while its Local OBC has not yet reached Committed state. The necessary Discovery happens in this state. The Local OBC state is **Refining**.

**Discovery in the Icebox state can be:**
- **Functional** — understand what must be built
- **Technical** — understand how to build with confidence
- **Operational** — understand how to operate and monitor

**State transition:** The item leaves the Icebox view when the Local OBC reaches the Committed state — it is then represented in the Iteration Backlog view.

**Canonical artifact:** `prodops/artifacts/product/backlogs/icebox-backlog.md`

---

### Iteration Backlog

**Nature:** View over the PIB — not a separate queue. Represents PIB items that are committed and ready to start Delivery: Local OBC in Committed state, Discovery complete, delivery decision made.

**Question:** Which PIB items are ready to be developed?

**What it represents:** An item is in the Iteration Backlog view when it satisfies all readiness criteria. The Local OBC state is **Committed**. The only remaining decision is the Product Owner's priority for the next iteration.

**Not refinement.** Refinement happens in the Icebox state. An item that reaches this view is ready — no more Discovery needed.

**Criteria to be in this view:**
- Local OBC in Committed state
- Functional, technical, and operational Discovery sufficient
- Risks identified in `prodops/journeys/assessment/risks.md`

**Criteria to enter the Iteration Plan (begin execution):**
- Local OBC committed in `prodops/artifacts/business/obcs/`
- BDD Feature committed in `prodops/artifacts/business/bdd/`
- Reliability Plan entry when applicable: money movement, external integration, SLO change, high/critical risk, persistence or security change

**Canonical artifact:** `prodops/artifacts/product/backlogs/iteration-backlog.md`

---

### Release

**Nature:** View over the PIB — not a separate queue. Represents PIB items grouped by product release version.

**Question:** Which PIB items are part of this release version?

**What it represents:** An organized view of Local OBCs grouped by the release version they contribute to. Facilitates planning, communication, and version tracking.

**Do not confuse with:** Platform Release (which is a view on the BIB, under Portfolio responsibility). The PIB Release view is the Product Owner's responsibility.

**Managed by:** Product Owner.

---

### Iteration Plan

**Question:** What is being executed in this iteration?

**Purpose:** Represent exclusively an ongoing Delivery execution. It is not a planning or prioritization backlog — it is the record of the current iteration.

**Contains:**
- Items chosen from the Iteration Backlog
- Execution strategy
- CI Sync journeys (Bootstrap → Hack → Sync → Finish)
- CI Async journeys (Ship → Validate → Promote)
- Implementation progress tracking
- Produced evidence
- Iteration exit criteria

**Does not contain:** Prioritization. Refinement. Icebox items. Items without Committed Local OBC.

**Canonical artifact:** `prodops/artifacts/governance/plans/iteration-plan.md`

---

## OBC as a permanent identifier

The Local OBC accompanies work throughout its entire life in the product — from the moment it is created by Partitioning (or by Owner Approval in the local flow) through to production operation. Each backlog transition above also represents a Local OBC state transition.

The Global OBC accompanies the business intention end-to-end — it survives decomposition and continues being refined during Operation.

→ **Full lifecycle, composition, and governance of the OBC:** [`obc.en.md`](obc.en.md)

---

## GitHub Issue as operational representation

A GitHub Issue is not the origin of work in the ProdOps Framework. It is an **operational representation** of a commitment already made.

**When an Issue is created:** Typically when a Local OBC enters the Iteration Backlog or Iteration Plan — the work is ready for execution.

**The Framework is tool-independent.** GitHub Issues, Jira Cards, Azure DevOps Work Items are operational representations of the same OBC in different tools. The OBC is the source of truth; the Issue is the execution instance.

---

## Diligence as guardian of the hierarchy

Diligence is the journey responsible for keeping backlogs synchronized at all levels — platform and product.

> **Principle:** Diligence ensures that the state of each OBC remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

**What Diligence keeps synchronized:**
- Local OBC state in each backlog (Product Intent, Icebox, Iteration Backlog, Iteration Plan)
- Global OBC state in the BIB and its traceability
- Operational representations in tools (GitHub Issues, Jira, Azure DevOps)
- Traceability Intent → Global OBC → Local OBC → Issue → PR → Release → Operation
- Consistency between ProdOps artifacts and external tools

→ [Diligence Journey](../journeys/diligence/README.en.md)

---

## Responsibility per backlog

| Backlog / View | Question | Managed by |
|---|---|---|
| Global Tracking List | What deserves attention on the platform? | Portfolio |
| Business Intent Backlog | What deserves Discovery? (Global OBCs) | Portfolio |
| OBC Partitioning | How to decompose the Global OBC into Local OBCs? | Portfolio PM + Tech Leads |
| Roadmap | What is the strategic delivery sequence? | Portfolio |
| Platform Release | What composes this platform version? | Portfolio |
| Repository Tracking List | What deserves attention in this product? | Product Repository |
| Product Intent Backlog | What has been officially accepted by the Product Owner? (Local OBCs) | Product Owner |
| Icebox | What is still being prepared for Delivery? (Refining) | Product Owner + Tech Lead |
| Iteration Backlog | What is ready to be developed? (Committed) | Product Owner |
| Release | What composes this product version? | Product Owner |
| Iteration Plan | What is being executed in this iteration? | Delivery Team |

---

## References

- `prodops/artifacts/product/backlogs/tracking-list.md` — Repository Tracking List
- `prodops/artifacts/product/backlogs/icebox-backlog.md` — Icebox
- `prodops/artifacts/business/obcs/` — Committed OBCs
- `prodops/artifacts/product/backlogs/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/governance/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.en.md` — canonical definitions
- `prodops/journeys/diligence/README.en.md` — Diligence Journey
