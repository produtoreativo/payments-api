# Backlog Hierarchy

The ProdOps Framework organizes work in two hierarchical flows: a **platform** flow (Portfolio) and a **product** flow (Product Repository). Each backlog answers a single question and has well-defined responsibilities.

Work never skips levels without explicit justification recorded in the OBC.

---

## Global Flow — Platform → Product

```
Global Tracking List       ← What deserves attention on the platform?
          ↓
Business Intent Backlog    ← What deserves Discovery? (OBC Draft is born here)
          ↓
Roadmap                    ← What is the strategic delivery sequence?
          ↓
Platform Release           ← What composes this platform version?
          ↓
Product Intent Backlog     ← What has been officially accepted by the Product Owner?
          ↓
Icebox                     ← What is still being prepared for Delivery?
          ↓
Iteration Backlog          ← What is ready to be developed?
          ↓
Iteration Plan             ← What is being executed in this iteration?
          ↓
Delivery
```

---

## Local Flow — Product

```
Repository Tracking List   ← What deserves attention in this product?
          ↓
Premortem + Preliminary Risk Analysis
          ↓
Owner Approval
          ↓
Product Intent Backlog     ← What has been officially accepted by the Product Owner?
          ↓
[continues in the common flow above]
```

> **Note on Reliability Plan in the local flow:** The pre-PIB step requires a **Premortem** and a preliminary risk analysis — not the formal Reliability Plan artifact at `reliability-plans/`. The formal Reliability Plan is produced by the Assessment journey during the Icebox, after the Product Owner's commitment. The Premortem is sufficient for the PIB entry decision. The formal Reliability Plan is **recommended** before Delivery, not mandatory.

After entering the **Product Intent Backlog**, the item's origin no longer matters. All items follow exactly the same journey — regardless of whether they came from the Portfolio or the local flow.

---

## Platform Backlogs

### Global Tracking List

**Question:** What deserves attention on the platform?

**Purpose:** Capture any platform-level signal not yet understood enough to be treated as a formal Intent.

**Contains:** Ideas, opportunities, problems, demands, compliance, improvements, risks, technology — any signal that has not yet received enough attention.

**Does not contain:** OBC. Commitment. Permanent identifier.

**Commitment:** None. The goal is to investigate whether the item represents a valid Intent for the platform.

**When to advance:** When the item has been understood enough to be recognized as an Intent and enter the Business Intent Backlog.

**Managed by:** Portfolio.

---

### Business Intent Backlog

**Question:** What deserves Discovery?

**Purpose:** Represent Intents accepted for Discovery at the platform level. This is where the OBC is born as a Draft in the global flow.

**What happens when an item enters this backlog:**
- The Intent receives a permanent identifier.
- An OBC Draft is created — captures the Intent and initial hypotheses.
- The lifecycle of the work begins.
- The Product Owner defines the execution mode: Upstream or Downstream.

**Commitment:** The Intent is accepted for Discovery. No implementation commitment yet.

**When to advance:** When the Intent has enough evidence to enter the Roadmap.

**Managed by:** Portfolio.

---

### Roadmap

**Question:** What is the strategic delivery sequence for the platform?

**Purpose:** Organize Platform Releases, Milestones, priorities, and dependencies. The Roadmap coordinates platform versions — it does not contain technical tasks.

**Contains:** Releases, Milestones, priorities, cross-product dependencies.

**Does not contain:** Technical tasks, product OBCs, BDD Features.

**Commitment:** Strategic commitment — the platform intends to deliver this within a defined horizon.

**Managed by:** Portfolio. Lives in external strategic management tools.

---

### Platform Release

**Question:** What composes this platform version?

**Purpose:** Represent a combination of Product Repository versions that form a coherent platform delivery.

**Example:**
- payments-api v3 + webshop-api v8 + order-api v2

**Responsibility:** Product Repositories do not control the Platform Release. Responsibility belongs exclusively to the Portfolio.

**Managed by:** Portfolio.

---

## Product Backlogs

### Repository Tracking List

**Question:** What deserves attention in this product?

**Purpose:** Capture any local product signal not yet understood enough to be treated as a formal commitment.

**Contains:** Bugs, technical debt, architecture, observability, performance, security, costs, internal improvements.

**Does not contain:** OBC. Commitment. Permanent identifier.

**Commitment:** None. Not every item needs to become a global Intent — some can be resolved locally via the Premortem + Preliminary Risk Analysis flow.

**When to advance:** Via Premortem + Preliminary Risk Analysis + Owner Approval → Product Intent Backlog.

**Canonical artifact:** `prodops/artifacts/product/tracking-list.md`

---

### Product Intent Backlog

**Question:** What has been officially accepted by the Product Owner?

**Purpose:** Represent all work formally accepted by the product's Product Owner. Single entry point for the product's Delivery cycle — regardless of where the item came from.

**Two entry paths:**

| Origin | Entry path |
|---|---|
| Platform | Business Intent from Portfolio, after Platform Release coordinates delivery |
| Local | Repository Tracking Item promoted via Premortem + Preliminary Risk Analysis with Owner Approval |

**What happens when an item enters this backlog:**
- The Product Owner formalizes acceptance.
- If it didn't exist yet (local path), an OBC Draft is created for the item.
- The item begins its traceable lifecycle in the product.

**After entry, the origin no longer matters.** All items follow the same journey: Icebox → Iteration Backlog → Iteration Plan → Delivery.

> **Exception — Upstream promotion:** An item promoted from Upstream to Downstream already has an OBC, BDD Feature, and documented risks. It enters **directly into the Iteration Plan** (status `In`), skipping the Iteration Backlog. The Iteration Backlog is the queue for items not yet ready to start Delivery — items promoted from Upstream already satisfy that criterion.

**Commitment:** The Product Owner has committed to investigating and eventually delivering this item.

**When to advance:** When the Intent has enough evidence to enter the Icebox (preparation for Delivery).

---

### Icebox

**Question:** What is still being prepared for Delivery?

**Purpose:** Represent committed items still being prepared to start Delivery. During this phase, the product-level Discovery required for Delivery takes place.

**Discovery in the Icebox can be:**
- **Functional** — understand what must be built
- **Technical** — understand how to build with confidence
- **Operational** — understand how to operate and monitor

**Goal:** Produce a minimum acceptable OBC. Until that happens, the item stays in the Icebox.

**Commitment:** The item will be delivered — but is not yet ready to start.

**When to advance:** When the item has a validated minimum OBC and is ready to enter the Iteration Backlog.

**Canonical artifact:** `prodops/artifacts/product/icebox-backlog.md`

---

### Iteration Backlog

**Question:** What is ready to be developed?

**Purpose:** Represent all items with a validated minimum OBC that are ready for immediate Delivery. The only remaining decision is priority, defined by the Product Owner.

**This backlog is not for refinement.** Refinement happens in the Icebox. The Iteration Backlog represents exclusively work ready to be implemented.

**Prerequisites to enter:** Minimum validated OBC.

**Prerequisites to exit (enter Delivery via Iteration Plan):**
- OBC committed in `prodops/artifacts/obcs/`
- BDD Feature committed in `prodops/artifacts/bdd/`
- Iteration Plan entry with status `In`
- Risks documented in `prodops/journeys/assessment/risks.md`
- *(Recommended)* Reliability Plan entry in `prodops/journeys/assessment/reliability-plans/` — not a mandatory gate, but strongly recommended for items with relevant operational risk

**Canonical artifact:** `prodops/artifacts/plans/iteration-backlog.md`

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

**Does not contain:** Prioritization. Refinement. Icebox items. Items without committed OBC.

**Canonical artifact:** `prodops/artifacts/plans/iteration-plan.md`

---

## OBC as a permanent identifier

The OBC accompanies work throughout its entire life — from the moment the Intent is accepted through to production operation. Each backlog transition above also represents an OBC state transition.

→ **Full lifecycle, composition, and governance:** [`obc.en.md`](obc.en.md)

---

## GitHub Issue as operational representation

A GitHub Issue is not the origin of work in the ProdOps Framework. It is an **operational representation** of a commitment already made.

**When an Issue is created:** Typically when an OBC enters the Iteration Backlog or Iteration Plan — the work is ready for execution.

**The Framework is tool-independent.** GitHub Issues, Jira Cards, Azure DevOps Work Items are operational representations of the same OBC in different tools. The OBC is the source of truth; the Issue is the execution instance.

---

## Diligence as guardian of the hierarchy

Diligence is the journey responsible for keeping backlogs synchronized at all levels — platform and product.

> **Principle:** Diligence ensures that the state of each OBC remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

**What Diligence keeps synchronized:**
- OBC state in each backlog (Product Intent, Icebox, Iteration Backlog, Iteration Plan)
- Operational representations in tools (GitHub Issues, Jira, Azure DevOps)
- Traceability Intent → OBC → Issue → PR → Release → Operation
- Consistency between ProdOps artifacts and external tools

→ [Diligence Journey](../journeys/diligence/README.en.md)

---

## Responsibility per backlog

| Backlog | Question | Managed by |
|---|---|---|
| Global Tracking List | What deserves attention on the platform? | Portfolio |
| Business Intent Backlog | What deserves Discovery? | Portfolio |
| Roadmap | What is the strategic delivery sequence? | Portfolio |
| Platform Release | What composes this platform version? | Portfolio |
| Repository Tracking List | What deserves attention in this product? | Product Repository |
| Product Intent Backlog | What has been officially accepted by the Product Owner? | Product Owner |
| Icebox | What is still being prepared for Delivery? | Product Owner + Tech Lead |
| Iteration Backlog | What is ready to be developed? | Product Owner |
| Iteration Plan | What is being executed in this iteration? | Delivery Team |

---

## References

- `prodops/artifacts/product/tracking-list.md` — Repository Tracking List
- `prodops/artifacts/product/icebox-backlog.md` — Icebox
- `prodops/artifacts/obcs/` — Committed OBCs
- `prodops/artifacts/plans/iteration-backlog.md` — Iteration Backlog
- `prodops/artifacts/plans/iteration-plan.md` — Iteration Plan
- `prodops/framework/glossary.en.md` — canonical definitions
- `prodops/journeys/diligence/README.en.md` — Diligence Journey
