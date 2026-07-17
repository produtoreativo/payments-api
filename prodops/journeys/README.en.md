# Journeys

The ProdOps Framework has five journeys organized in two groups.

---

## Fundamental separation

**Execution modes are not journeys.**

| Concept | What it is | Example |
|---|---|---|
| **Mode** | Determines the level of commitment and quality gates applied | Upstream, Downstream |
| **Journey** | Describes the work path within a mode | Discovery, Delivery, Operation |
| **Backlog** | Organizes work before and during execution | Product Intent Backlog, Icebox, Iteration Backlog |
| **Plan** | Records the execution of an iteration | Iteration Plan |

Upstream and Downstream are modes, not journeys. Discovery is the journey — it exists in both modes with different responsibilities.

---

## Responsibility of each journey

| Journey | Sole responsibility |
|---|---|
| [Discovery](discovery/) | Reduce uncertainty and prepare the work |
| [Delivery](delivery/) | Build, validate and promote the solution |
| [Operation](operation/) | Operate and evolve the product in production |
| [Assessment](assessment/) | Produce analyses to support decisions |
| [Diligence](diligence/) | Ensure adherence to the operational model |

---

## Upstream flow

```
Intent
  ↓
Upstream
  ↓
Discovery (exploratory)
  ↓
Learnings / Prototypes / Experiments
  ↓
(Eventually) → Downstream
```

No delivery commitment. The goal is to reduce uncertainty. An Intent may remain indefinitely in Upstream, be discarded, return to the Portfolio, or proceed to Downstream.

---

## Downstream flow

```
Intent
  ↓
Product Intent Backlog
  ↓
Icebox (preparatory Discovery)
  ↓
Iteration Backlog
  ↓
Iteration Plan
  ↓
Delivery (CI Sync → CI Async)
  ↓
Operation
```

There is a delivery commitment, validation, governance, and reliability.

---

## Relationship between journeys and backlogs

| Backlog | Responsible journey |
|---|---|
| Repository Tracking List / Global Tracking List | Assessment (signals) |
| Product Intent Backlog | Diligence (synchronizes) |
| Icebox | Discovery (Downstream) — preparation |
| Iteration Backlog | Diligence + Assessment |
| Iteration Plan | Delivery — execution |

Discovery in Downstream operates within the Icebox.
Delivery begins only when an item enters the Iteration Plan.

---

## Cross-cutting journeys

Assessment and Diligence continuously accompany the other journeys. They do not represent only documentation — they represent active Framework behavior.

Assessment can occur in both Upstream and Downstream.

→ [Execution Model](../execution-model/README.md)
→ [Backlog hierarchy](../framework/backlogs.en.md)
