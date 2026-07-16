# Intent Phases: Conception and Inception

The lifecycle of an Intent before Delivery is organized into two distinct phases: **Conception** and **Inception**. They differ in commitment, governance, OBC state, and what can happen to the work.

---

## Conception

**Period:** from the emergence of the signal to entry into the Product Intent Backlog.

**Backlogs involved:**
- Global flow: Global Tracking List → Business Intent Backlog
- Local flow: Repository Tracking List (no OBC yet)

**Central question:** Is there real value here?

**Governance:** Portfolio PM (global flow) or the local signal owner. The Product Owner has not yet made a commitment.

**OBC state:** Does not exist in the Tracking Lists. Born as a Draft when the Intent enters the Business Intent Backlog (global flow). In the local flow, the OBC is born as a Draft only upon entry into the Product Intent Backlog.

**Commitment:** None. The Intent may be discarded, reformulated, or indefinitely deferred without any formal record of learning.

**What ends Conception:** Entry into the Product Intent Backlog after Owner Approval.

---

## Inception

**Period:** from entry into the Product Intent Backlog until the OBC reaches the Minimum OBC state (Iteration Backlog).

**Backlogs involved:**
- Product Intent Backlog → Icebox → Assessment Review → Iteration Backlog

**Central question:** Is the Product Owner committing attention and capacity to investigate this now?

**Governance:** Product Owner (formal acceptance and execution mode) and Tech Lead (Assessment Review).

**OBC state:** Draft → Draft under refinement (Icebox) → Minimum OBC (Iteration Backlog).

**Commitment:** Formal. The Product Owner has committed to investigate. Any closure from this point forward requires an explicit learning record in the OBC.

**Execution mode:** Upstream (high uncertainty, disposable code) or Downstream (sufficient clarity, mandatory gates). The mode is defined by the Product Owner when accepting the Intent into the PIB.

**What ends Inception:** Assessment Review approved, OBC in Minimum OBC state, BDD Feature committed — entry into the Iteration Backlog.

---

## The boundary

The boundary between Conception and Inception is entry into the **Product Intent Backlog** with **Owner Approval**.

```
CONCEPTION
  Global Tracking List / Repository Tracking List
    ↓  (signal investigated, value recognized)
  Business Intent Backlog  ← OBC born as Draft (global flow)
    ↓  (Roadmap / Platform Release — Portfolio decision)
────────────── BOUNDARY: Owner Approval ──────────────
INCEPTION
  Product Intent Backlog  ← Product Owner accepts, mode defined
    ↓  (Discovery: Upstream or Downstream)
  Icebox
    ↓  (Assessment Review: PM + Tech Lead)
  Iteration Backlog  ← OBC reaches Minimum OBC
    ↓
DELIVERY
```

**What changes at the boundary:**

| Dimension | Conception | Inception |
|---|---|---|
| Backlogs | Tracking Lists, Business Intent Backlog | Product Intent Backlog, Icebox, Iteration Backlog |
| Governance | Portfolio PM | Product Owner + Tech Lead |
| OBC | Does not exist → Draft (BIB) | Draft → Draft under refinement → Minimum OBC |
| Discarding | No formal record required | Requires a learning record in the OBC |
| Execution mode | N/A | Upstream or Downstream |

**In the local flow**, the boundary into Inception is Owner Approval after the Premortem and Preliminary Risk Analysis. The formal Reliability Plan is not required at this point — it is produced during the Icebox.

---

## References

→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)
→ [Glossary](glossary.en.md)
→ [Execution Model](../execution-model/README.md)
