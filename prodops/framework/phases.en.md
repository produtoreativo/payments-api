# Business Intent Phases: Conception and Inception

The lifecycle of a Business Intent before Delivery is organized into two distinct phases: **Conception** and **Inception**. They differ in commitment, governance, OBC state, and what can happen to the work.

---

## Conception

**Period:** from the emergence of the Business Signal to entry into the Product Backlog.

**Two independent flows — choose one:**

| Flow | When to use | Backlogs |
|---|---|---|
| **Global** | Business Signal of uncertain scope; it is not known which product or team will resolve it. Involves business, value chain, or the entire platform. | Portfolio Tracking List → Business Intent Backlog |
| **Local** | Business Signal already directed; known destination — this product, this team. No platform triage needed. | Product Tracking List → (direct to Product Backlog) |

The two flows are independent. A signal does not need to go through the global flow before entering the local one. There is no duplication between the two tracking lists.

**Central question:** Is there real value here?

**Governance:** Portfolio PM (global flow) or Product Owner / local owner (local flow). The Product Owner has not yet made a formal commitment in either flow.

**OBC state:** Does not exist in the Tracking Lists. In the global flow, the **Global OBC** is born as a Draft upon entry into the Business Intent Backlog. In the local flow, the **Local OBC** is born as a Draft directly upon entry into the Product Backlog.

**Commitment:** None. The Business Intent may be discarded, reformulated, or indefinitely deferred without any formal record of learning.

**What ends Conception:** Entry into the Product Backlog after Owner Approval — regardless of which flow originated the Business Signal.

---

## Inception

**Period:** from entry into the Product Backlog until the Local OBC reaches the Committed state (Iteration Backlog).

**Backlogs involved:**
- Product Backlog (source of truth) — with views: Icebox (Refining) → Iteration Backlog (Committed)

**Central question:** Is the Product Owner committing attention and capacity to investigate this now?

**Governance:** Product Owner (formal acceptance and execution mode) and Tech Lead (Assessment Review).

**OBC state (Local OBC):** Draft → Refining (Icebox) → Committed (Iteration Backlog).

**Commitment:** Formal. The Product Owner has committed to investigate. Any closure from this point forward requires an explicit learning record in the OBC.

**Execution mode:** Upstream or Downstream — they are **modes**, not phases. The mode is defined by the Product Owner when accepting the Business Intent into the Product Backlog and may change throughout Inception. Upstream is used for high uncertainty; Downstream for sufficient clarity with mandatory gates. An item may start Upstream and, after reducing uncertainty, transition to Downstream without changing phases.

**What ends Inception:** Assessment Review approved, Local OBC in Committed state, BDD Feature committed — item reaches the "ready" state in the Product Backlog (Iteration Backlog view).

---

## The boundary

The boundary between Conception and Inception is entry into the **Product Backlog** with **Owner Approval**.

```
CONCEPTION

  [Signal of uncertain scope]        [Signal already directed]
  business / platform /              specific product / team
  multiple products                  destination already known
         │                                    │
         ▼                                    ▼
  Portfolio Tracking List         Product Tracking List
  (Portfolio governs)            (Product Owner / team governs)
         │                                    │
         ▼                                    │
  Business Intent Backlog                     │
  (Global OBC born as Draft)                  │
  ├─ Roadmap [view: horizon]                 │
  └─ Platform Release [view: version]        │
         │                                    │
         ▼ Discovery in BIB                   │
  OBC Partitioning                            │
  (Global OBC → Local OBCs)                  │
         │                                    │
         │  (Portfolio routes to product)     │
         │                                    │
         └──────────────┬─────────────────────┘
                        │ Premortem + Risk Analysis + Owner Approval
                        ▼
══════════════ BOUNDARY ═══════════════════════════════════

INCEPTION

  Product Backlog  ← product source of truth
  (Local OBC born as Draft if it doesn't exist yet — local flow)
    │              │
    │  [view]      ├─ Icebox [Refining]
    │              └─ Iteration Backlog [Committed]
    │  (Assessment Review: PM + Tech Lead validates the transition)
         │
         ▼
  DELIVERY
```

**What changes at the boundary:**

| Dimension | Conception | Inception |
|---|---|---|
| Backlogs | Tracking Lists, Business Intent Backlog | Product Backlog, Icebox (VIEW), Iteration Backlog (VIEW) |
| Governance | Portfolio PM (global) / local owner | Product Owner + Tech Lead |
| OBC | Does not exist → Global OBC Draft (BIB) / Local OBC Draft (Product Backlog) | Draft → Refining → Committed |
| Discarding | No formal record required | Requires a learning record in the OBC |
| Execution mode | N/A | Upstream or Downstream (modes, not phases) |

**In the local flow**, the Business Signal goes directly from the Product Tracking List to the Product Backlog via Premortem + Preliminary Risk Analysis + Owner Approval — without going through the Portfolio, without going through the Business Intent Backlog. The Local OBC is born directly in the Product Backlog. The formal Reliability Plan is not required at this point — it is produced during the Icebox.

---

## References

→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)
→ [Glossary](glossary.en.md)
→ [Execution Model](../execution-model/README.md)
