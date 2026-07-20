# Backlog Hierarchy

The ProdOps Framework organizes work in two hierarchical flows: a **platform** flow (Portfolio) and a **product** flow (Product Repository). Each backlog answers a single question and has well-defined responsibilities.

Work never skips levels without explicit justification recorded in the OBC.

---

## Entity → backlog model

| Entity | Where it lives | GitHub representation |
|---|---|---|
| **Business Signal** | Portfolio Tracking List (platform) or Product Tracking List (product) | Business Signal Issue |
| **Business Intent** | Business Intent Backlog and Product Backlog | Business Intent Issue |

> **Note:** A Business Intent exists in both the Business Intent Backlog and the Product Backlog (after OBC Partitioning). Each Intent owns a Local OBC as its contract document. The OBC is a Markdown document — it does not have an Issue representation.

**Critical rule:** Entities never change identity. A Business Signal **generates** Business Intents — it does not become one. A Business Intent can be created directly in the BIB without passing through the Tracking List. When originating from a Business Signal, it stores an optional back-reference to the originating Signal.

---

## Global Flow — Platform → Product

```
Portfolio Tracking List    ← Business Signals for the platform (What deserves attention?)
          ↓ (Business Signal generates Business Intent (1:N))
Business Intent Backlog    ← Business Intents (What deserves Discovery?)
    │         │              Global OBC Draft born here
    │         │
    │         ├─ Roadmap          [VIEW over BIB: in which strategic horizon?]
    │         └─ Platform Release [VIEW over BIB: in which platform version?]
    │
    │   (Discovery in the BIB)
          ↓
OBC Partitioning           ← Business Intent → Local OBCs (one per product)
          ↓
Product Backlog            ← Product OBCs (source of truth)
    │         │
    │         ├─ Icebox           [VIEW over Product Backlog: Refining state]
    │         ├─ Iteration Backlog [VIEW over Product Backlog: Committed state]
    │         └─ Release          [VIEW over Product Backlog: grouped by version]
    │
    │   (item with Committed Local OBC + BDD + criteria satisfied)
          ↓
Iteration Plan             ← current iteration execution
          ↓
Delivery
          ↓
Operation                  ← Continuous OBC Refinement
```

> **Roadmap and Platform Release are VIEWs over the BIB** — not separate backlogs.
> **Icebox, Iteration Backlog, and Release are VIEWs over the Product Backlog** — not separate queues. An item does not leave the Product Backlog when entering one of these views; it remains in the Product Backlog and receives a state that determines which view represents it.

---

## Local Flow — Product

```
Product Tracking List      ← Business Signals for the product (What deserves attention?)
          ↓ (Business Signal generates Business Intent (1:N) + Local OBC)
Premortem + Preliminary Risk Analysis
          ↓
Owner Approval
          ↓
Product Backlog            ← Product OBCs (Local OBC born here in local flow)
[continues in the common flow — Icebox/Iteration Backlog/Release as VIEWs]
```

> **Note on Reliability Plan in the local flow:** The pre-Product Backlog step requires a Premortem and preliminary risk analysis. The formal Reliability Plan is produced by Assessment during the Icebox and becomes a Delivery gate when there is money movement, an external integration, an SLO change, high/critical risk, or a persistence or security change.

After entering the **Product Backlog**, the item's origin no longer matters. All items follow exactly the same journey — regardless of whether they came from the Portfolio or the local flow.

---

## Platform Backlogs

### Portfolio Tracking List

**Question:** What Business Signals deserve attention on the platform?

**Contains:** ONLY Business Signals. Never Business Intents. Never OBCs.

**Purpose:** Capture Business Signals whose scope is undefined or spans more than one product. The signal belongs to the platform — it is not yet clear which product or team will resolve it.

**When to use:** The signal involves business, value chain, multiple products, or the entire platform. Problem ownership is not yet clear. Examples: market opportunities without a defined product, regulatory changes affecting multiple systems, cross-cutting platform initiatives.

**When not to use:** The signal already has a clear destination — a specific product or team that clearly owns the resolution. In that case, the signal belongs in that product's Product Tracking List.

**Independence:** Business Signals in the Portfolio Tracking List are not copied to candidate products' Product Tracking Lists. The item stays here until triaged and routed. There is no duplication between the two flows.

**Does not contain:** OBC. Commitment. Permanent identifier. Business Intents.

**When to advance:** When the Business Signal has been understood enough to be recognized as strategic — at that point it **generates** a new Business Intent that enters the Business Intent Backlog.

**Managed by:** Portfolio.

---

### Business Intent Backlog

**Question:** What deserves Discovery?

**Purpose:** Represent Business Intents accepted for Discovery at the platform level. This is where the **Global OBC** is born as a Draft. The BIB contains only Business Intents (and their associated Global OBCs) — never Local OBCs, never Business Signals.

**Contains:** ONLY Business Intents.

**What happens when an item enters this backlog:**
- The Business Intent receives a permanent identifier.
- A **Global OBC Draft** is created — captures the Business Intent and initial business hypotheses.
- The lifecycle of the work begins.

**Commitment:** The Business Intent is accepted for Discovery. No implementation commitment yet. Products, repositories, and the number of Local OBCs are still unknown at this point.

**Dimensions over the BIB:** Items in the BIB can receive strategic dimensions without leaving it:
- **Roadmap** — positions the item in a delivery horizon (now, next, later).
- **Platform Release** — associates the item with the platform version it belongs to.

An item can be in the BIB, associated with a Roadmap, and linked to a Platform Release simultaneously. These dimensions are projections — not queues the item passes through sequentially.

**When the item leaves the BIB:** After Discovery in the BIB and OBC Partitioning, the Portfolio routes the created Local OBCs to the Product Backlogs of the involved products.

**Managed by:** Portfolio.

---

### OBC Partitioning

**What it is:** Capability responsible for transforming the Global OBC into Local OBCs — one per involved product. Occurs after Discovery in the BIB, before creating items in the products' Product Backlogs.

**Responsibilities:**
- Identify the products involved in the implementation
- Identify the corresponding repositories
- Identify the Bounded Contexts
- Decompose the Global OBC into responsibility partitions
- Create the Local OBCs with reference to the Global OBC
- Maintain the traceability table in the Global OBC

**Result:** each product receives a Local OBC in its Product Backlog. The Global OBC records the traceability of all Local OBCs.

**Who executes:** Portfolio PM + Tech Leads of the involved products.

---

### Roadmap

**Nature:** Strategic view over the Business Intent Backlog — not a queue. Items do not "enter" the Roadmap; they remain in the BIB and receive a position in the strategic horizon.

**Question:** In which delivery horizon does this item fit?

**Purpose:** Organize the strategic sequence of BIB items by horizon (now / next / later), Milestones, and cross-product dependencies. Allows the Portfolio to communicate intent without committing to delivery.

**What it represents:** A temporal projection of BIB items — which will be addressed in which time window.

**Is not:** A task list. Items on the Roadmap still live in the BIB and can be removed, reprioritized, or redirected without a formal removal process.

**Commitment:** Strategic intent, not delivery commitment. Delivery only becomes a commitment when the item enters a product's Product Backlog.

**Managed by:** Portfolio. Lives in external strategic management tools.

---

### Platform Release

**Nature:** Grouping view over the Business Intent Backlog — not a queue. Items do not "pass through" the Platform Release; they remain in the BIB and are associated with a platform version.

**Question:** Which BIB items compose this platform version?

**Purpose:** Group BIB items that form a coherent platform delivery — a combination of Product Repository versions to be released together.

**Example:**
- Platform Release 3.0 = payments-api v3 + webshop-api v8 + order-api v2

**What it represents:** A strategic grouping of BIB items by platform version. It is the Portfolio's decision of which products and versions will be coordinated in the same delivery.

**Relationship with Product Backlog:** Associating an item with a Platform Release may precede or accompany routing to a product's Product Backlog — but does not replace it. The item only enters the product flow when the Portfolio explicitly routes it to the Product Backlog.

**Responsibility:** Product Repositories do not control the Platform Release. Responsibility belongs exclusively to the Portfolio.

**Managed by:** Portfolio.

---

## Product Backlogs

### Product Tracking List

**Question:** What Business Signals deserve attention in this product?

**Contains:** ONLY Business Signals. Never Business Intents. Never OBCs.

**Purpose:** Capture Business Signals already directed at this specific product or team. Ownership is defined — it is known that the problem belongs here.

**When to use:** The signal has a clear destination: this product, this team. No platform triage needed. Examples: bug identified in this service, internal technical debt, performance improvement opportunity in this domain, signal from this product's postmortem or operation.

**When not to use:** The signal is too broad, involves multiple products, or ownership is not yet clear. In that case, the signal belongs in the Portfolio Tracking List.

**Independence:** The Product Tracking List is autonomous — it does not depend on the Portfolio Tracking List and does not receive copies from it. A Business Signal that arrives here already has a defined destination and follows directly through the local flow (Premortem + Owner Approval → Product Backlog), without going through the Portfolio.

**Does not contain:** OBC. Commitment. Permanent identifier. Business Intents.

**When to advance:** Via Premortem + Preliminary Risk Analysis + Owner Approval → Product Backlog.

**Canonical artifact:** `prodops/artifacts/product/backlogs/tracking-list.md`

---

### Product Backlog

**Nature:** Backlog — source of truth for all work accepted by the product. Items live here from acceptance through delivery. Icebox, Iteration Backlog, and Release are VIEWs over these items, not separate destinations.

**Question:** What has been officially accepted by the Product Owner?

**Contains exclusively:** Business Intents. Each Intent owns a Local OBC as its contract document. The Product Backlog never contains isolated Business Signals or Global OBCs.

**Two entry paths:**

| Origin | Entry path |
|---|---|
| Platform | Local OBC created by OBC Partitioning (from a Business Intent), routed by Portfolio after Discovery in BIB |
| Local | Product Tracking Item (Business Signal) promoted via Premortem + Preliminary Risk Analysis with Owner Approval — generates Business Intent + Local OBC Draft |

**What happens when an item enters:**
- The Product Owner formalizes acceptance.
- If it didn't exist yet (local path), a **Business Intent** + **Local OBC Draft** are created.
- The item begins its traceable lifecycle in the product.
- The item receives the initial state **Draft**. When active Discovery starts, it transitions to **Refining** and is represented in the Icebox VIEW.

**After entry, the origin no longer matters.** The item evolves in state within the Product Backlog: Draft → Refining (VIEW Icebox) → Committed (VIEW Iteration Backlog) → In Delivery (Iteration Plan) → Operational.

> **Upstream promotion:** An item promoted from Upstream that satisfies the Committed criteria skips Icebox refinement and appears in the Iteration Backlog VIEW. The Product Owner must still select it explicitly for the Iteration Plan.

**Commitment:** The Product Owner has committed to investigating and delivering this item.

---

### Icebox

**Nature:** VIEW over the Product Backlog — not a separate queue. Represents Product Backlog items that are still in refinement: incomplete Local OBC, open decisions, Discovery in progress.

**Question:** Which Product Backlog items are still being refined for Delivery?

**What it represents:** An item is in the Icebox VIEW while its Local OBC has not yet reached Committed state. The necessary Discovery happens in this state. The Local OBC state is **Refining**.

**Discovery in the Icebox state can be:**
- **Functional** — understand what must be built
- **Technical** — understand how to build with confidence
- **Operational** — understand how to operate and monitor

**State transition:** The item leaves the Icebox VIEW when the Local OBC reaches the Committed state — it is then represented in the Iteration Backlog VIEW.

**Canonical artifact:** `prodops/artifacts/product/backlogs/icebox-backlog.md`

---

### Iteration Backlog

**Nature:** VIEW over the Product Backlog — not a separate queue. Represents Product Backlog items that are committed and ready to start Delivery: Local OBC in Committed state, Discovery complete, delivery decision made.

**Question:** Which Product Backlog items are ready to be developed?

**What it represents:** An item is in the Iteration Backlog VIEW when it satisfies all readiness criteria. The Local OBC state is **Committed**. The only remaining decision is the Product Owner's priority for the next iteration.

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

**Nature:** VIEW over the Product Backlog — not a separate queue. Represents Product Backlog items grouped by product release version.

**Question:** Which Product Backlog items are part of this release version?

**What it represents:** An organized view of Local OBCs grouped by the release version they contribute to. Facilitates planning, communication, and version tracking.

**Do not confuse with:** Platform Release (which is a VIEW on the BIB, under Portfolio responsibility). The Product Backlog Release VIEW is the Product Owner's responsibility.

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

## GitHub in the Execution Space

GitHub is the canonical tool for tracking the **execution of work** on ProdOps artifacts. Artifacts (OBCs, BDD, Intents, etc.) live as Markdown files in the repository — never as GitHub Issues.

**Two Work Item types in the Framework:**
- **Business Signal Work Item** — represents work on a Business Signal in the Portfolio Tracking List or Product Tracking List
- **Business Intent Work Item** — represents work on a Business Intent in the BIB and the Product Backlog

**GitHub Projects as management domains:** The Portfolio GitHub Project **tracks work** on Business Signals and Business Intents. The Product Repository GitHub Project **tracks work** on Business Intents, OBCs, BDD, and product Plans. The OBC is a Markdown document — it does not have an Issue representation.

**Jira, ADO, Linear are optional sync tools.** External tools may receive synchronized data from GitHub, but they are not the source of truth for work state. The OBC `.md` file is the source of truth for content and state. GitHub Issues track the work performed on the OBC — they are not representations of the OBC. External tools are convenience mirrors.

→ [Work Item Schema](execution-mapping/work-item-schema.en.md)
→ [Execution Mapping](execution-mapping/README.en.md)

---

## Diligence as guardian of the hierarchy

Diligence is the journey responsible for keeping backlogs synchronized at all levels — platform and product.

> **Principle:** Diligence ensures that the state of each OBC remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

**What Diligence keeps synchronized:**
- Local OBC state in each backlog (Product Backlog, Icebox, Iteration Backlog, Iteration Plan)
- Global OBC state in the BIB and its traceability
- Operational representations in tools (GitHub Issues, Jira, Azure DevOps)
- Traceability:
  - Knowledge: Business Signal → Business Intent → Global OBC → Local OBC
  - Execution: Work Item (references artifact) → PR → Release → Operation

  The two spaces are independent. An artifact does not "generate" Issues sequentially — Issues represent work initiated on it when needed.
- Consistency between ProdOps artifacts and external tools

→ [Diligence Journey](../journeys/diligence/README.en.md)

---

## Responsibility per backlog

| Backlog / View | Entity | Question | Managed by |
|---|---|---|---|
| Portfolio Tracking List | Business Signals | What Business Signals deserve attention on the platform? | Portfolio |
| Business Intent Backlog | Business Intents | What deserves Discovery? | Portfolio |
| Roadmap (VIEW over BIB) | Business Intents | What is the strategic delivery sequence? | Portfolio |
| Platform Release (VIEW over BIB) | Business Intents | What composes this platform version? | Portfolio |
| OBC Partitioning | — | How to decompose the Global OBC into Local OBCs? | Portfolio PM + Tech Leads |
| Product Tracking List | Business Signals | What Business Signals deserve attention in this product? | Product Repository |
| Product Backlog | Business Intents | What has been officially accepted by the Product Owner? | Product Owner |
| Icebox (VIEW over Product Backlog) | Business Intents | What is still being prepared for Delivery? (Refining) | Product Owner + Tech Lead |
| Iteration Backlog (VIEW over Product Backlog) | Business Intents | What is ready to be developed? (Committed) | Product Owner |
| Release (VIEW over Product Backlog) | Business Intents | What composes this product version? | Product Owner |
| Iteration Plan | Business Intents | What is being executed in this iteration? | Delivery Team |

---

## References

- `prodops/artifacts/product/backlogs/tracking-list.md` — Product Tracking List
- `prodops/artifacts/product/backlogs/icebox-backlog.md` — Icebox
- `prodops/artifacts/business/obcs/` — Committed OBCs
- `prodops/artifacts/product/backlogs/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/governance/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.en.md` — canonical definitions
- `prodops/journeys/diligence/README.en.md` — Diligence Journey
