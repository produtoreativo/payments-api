# Execution Model

Upstream and Downstream are **execution modes** of the ProdOps Framework — they are not journeys, not phases, and they do not replace journeys.

## Canonical terminology

| Concept | Definition |
|---|---|
| **Upstream** | Exploration mode |
| **Downstream** | Commitment mode |
| **Discovery** | Journey present in both modes |
| **Delivery** | Journey present in both modes; only Downstream produces a promotable delivery |
| **Operation** | Journey present in both modes; Upstream is limited to sandbox/experiment operation |

Modes do not replace journeys. They define how journeys will be executed.

## Business Intent decision flow

Every Business Intent follows one of the two modes. In the BIB, Portfolio selects the global exploration mode; in the Product Backlog, the Product Owner selects the local mode. No transition happens automatically.

```
Business Intent
  ↓
Mode choice (Product Owner)
  ↓
Upstream                    Downstream
(exploration)               (commitment)
     │                           │
  Discovery                  Product Backlog
  Experiments                    → Icebox (VIEW — Discovery)
  Learnings                      → Iteration Backlog (VIEW)
     │                           → Iteration Plan
  (Eventually)                   → Delivery
  Downstream                     → Operation
```

There is no automatic transition between modes. A mode change must be an explicit decision.

Each mode uses the journeys differently. The difference is in commitment and applied rigor, not in the presence or absence of a journey.

## Upstream

Permissive, experimental mode with no delivery commitment.

**Characteristics:**
- No delivery commitment
- Freedom to select capabilities and practices as needed
- Code is disposable until promoted to Downstream
- Rapid artifact evolution
- Focus on learning, not delivery

Upstream transforms hypotheses into validated knowledge.

→ [Upstream mode details](upstream.md)

## Downstream

Delivery-commitment mode with complete application of current quality gates.

**Characteristics:**
- Formal commitment to acceptance criteria (OBC + BDD Feature)
- Complete governance and traceability
- Mandatory artifacts before start
- Evidence recorded at each step
- Full mandatory sequence

Downstream delivers software with knowledge validated by Discovery, performed directly in Downstream or promoted from Upstream.

→ [Downstream mode details](downstream.md)

## How to choose the mode

| Situation | Mode |
|---|---|
| Hypothesis to validate, high uncertainty | Upstream |
| Committed item being guided toward complete readiness | Downstream |
| Explore a new capability | Upstream |
| Execute an item with every readiness gate satisfied | Downstream |
| Prototype integration with a provider | Upstream |
| Deliver feature with commitment | Downstream |
