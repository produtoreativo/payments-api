[Português](ontology.md)

# ProdOps Ontology

Canonical definitions of the structural concepts in the ProdOps Framework.

This document is the **single source of truth** for the concept hierarchy. All other documents that describe or reference these concepts should link to this document rather than redefining the terms.

→ For the full vocabulary, see [glossary.en.md](glossary.en.md).
→ For the operational flow, see [operating-model.en.md](operating-model.en.md).

---

## Concept hierarchy

ProdOps is organized along two orthogonal dimensions:

**Structural dimension** — organizes work:

```
Framework
  └── Journey (5 journeys)
        └── Cycle (groupings within a journey)
              └── Phase (individual stages within a cycle)
```

**Transversal dimension** — defines how and with what work is executed:

```
Execution Model  ←  defines the commitment level applied to a Journey
Capability       ←  reusable mechanism consumed by a Phase
Skill            ←  executable implementation of a Phase or Journey
  └── Step       ←  sub-unit within a Skill
```

Full relationship diagram:

```
Framework
├── Execution Model (Upstream | Downstream)
│     applies to ↓ any Journey
├── Journey
│     ├── Discovery
│     ├── Delivery
│     │     ├── Cycle: CI Sync   →  Phase: Bootstrap → Hack → Sync → Finish
│     │     └── Cycle: CI Async  →  Phase: Ship → Validate → Promote
│     ├── Operation
│     ├── Assessment
│     └── Diligence
│           ├── Cycle: diligence-sync          →  Phase: Capture → Attach → Promote → Close
│           ├── Cycle: diligence-async         →  Phase: Scan → Flag → Repair
│           └── Cycle: workspace-reconciliation →  Phase: Inspect → Reconcile → Verify
│
├── Capability (consumed by Phases)
│     ├── Delivery Capabilities  (Commit Workflow, Contract Management, Evidence Management, Observability, Reliability)
│     └── Diligence Capabilities (Backlog Synchronization, Work Item Management, Divergence Detection, Workspace Reconciliation, …)
│
└── Skill (implements Phase, Cycle, or Journey)
      └── Step (sub-unit within a Skill)
```

---

## Canonical definitions

### Framework

**What it is:** The canonical system of principles, vocabulary, operating model, journeys, capabilities, and skills that defines how ProdOps works.

**Responsibility:** Be the single source of truth about how to work with ProdOps — regardless of which product, portfolio, or workspace is using it.

**Abstraction level:** Meta-level. Defines the structure that all other levels (Portfolio, Workspace, Product Repository) adopt.

**Contains:** Principles, glossary, official flow, Execution Model, journeys, capabilities, skills, templates, Origin Streams.

**Lives in:** Dedicated reference repository; distributed to and adopted by Product Repositories.

**Never represents:** Product roadmaps, product backlogs, business intents, features, releases.

---

### Execution Model

**What it is:** The two commitment modes and quality criteria that define how any journey will be executed — Upstream (exploration) and Downstream (commitment).

**Responsibility:** Define the rigor level, quality gates, and delivery commitment applied when any journey executes.

**Abstraction level:** Transversal across all journeys. The mode is not the journey — it defines how the journey executes.

**Contains:** Upstream, Downstream, mode transition rules.

**Lives in:** Part of the Framework; applied by each journey.

**Never represents:** A specific journey, a cycle, or a phase.

→ [execution-model/README.en.md](../execution-model/README.en.md)

---

### Journey

**What it is:** A work path with a single responsibility, its own lifecycle, and defined entry and exit criteria. The 5 journeys are: Discovery, Delivery, Operation, Assessment, and Diligence.

**Responsibility:** Organize work by intent — what is being done — independently of the execution mode.

**Abstraction level:** Immediately below the Framework. The Execution Model applies over the journey; the journey is not inside the Execution Mode.

**The 5 journeys:**

| Journey | Type | Responsibility |
|---|---|---|
| Discovery | Classic | Reduce uncertainty and prepare work |
| Delivery | Classic | Build, validate, and promote the solution |
| Operation | Classic | Operate and evolve the product in production |
| Assessment | Transversal | Produce analyses to support decisions |
| Diligence | Transversal | Ensure adherence to the operating model |

**Contains:** One or more Cycles.

**Lives in:** The Framework defines the 5 journeys; Product Repositories execute them.

**Never represents:** An execution mode. Upstream and Downstream are not journeys.

→ [journeys/README.en.md](../journeys/README.en.md)

---

### Cycle

**What it is:** An ordered grouping of phases within a journey, with distinct purpose, trigger, and nature.

**Responsibility:** Separate sets of phases with different operational nature within the same journey — for example, synchronous vs. asynchronous work, or reactive vs. proactive.

**Abstraction level:** Between Journey and Phase — groups phases with a common purpose, but does not replace the journey.

**Cycles by journey:**

| Journey | Cycle | Nature |
|---|---|---|
| Delivery | CI Sync | Synchronous — local, engineer-driven work |
| Delivery | CI Async | Asynchronous — platform-driven work |
| Diligence | diligence-sync | Reactive — triggered by an external event |
| Diligence | diligence-async | Proactive — initiated by periodic scan |
| Diligence | workspace-reconciliation | On-demand — Inspect → Reconcile → Verify |

**Note:** Discovery, Operation, and Assessment have no formal cycles — they operate as a fluid sequence of phases without explicit grouping.

**Contains:** An ordered set of Phases.

**Lives in:** Inside a Journey.

**Never represents:** A journey, an individual phase, or a capability.

---

### Phase

**What it is:** An individual, ordered stage within a Cycle, with unique entry conditions, output, and responsibility.

**Responsibility:** Execute an atomic and verifiable step within a cycle. Each phase has clear entry preconditions and verifiable exit postconditions.

**Abstraction level:** The smallest structural unit in the conceptual model. Below the Phase, only Steps exist — implementation units within Skills.

**Phases by cycle:**

| Cycle | Phases |
|---|---|
| CI Sync | Bootstrap → Hack → Sync → Finish |
| CI Async | Ship → Validate → Promote |
| diligence-sync | Capture → Attach → Promote → Close |
| diligence-async | Scan → Flag → Repair |
| workspace-reconciliation | Inspect → Reconcile → Verify |

**Contains:** No formal sub-concepts — a Phase's implementation is done by a Skill and its Steps.

**Lives in:** Inside a Cycle.

**Never represents:** A journey, a cycle, a capability, or an artifact.

> **Required distinction — Lifecycle Stage vs. Delivery Phase:**
>
> The document [`phases.en.md`](phases.en.md) describes **Conception** and **Inception** — lifecycle stages of a Business Intent **before** the Delivery journey. These are **Lifecycle Stages**, conceptually distinct from **Delivery Phases** (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) and **Diligence Phases** (Capture, Attach, etc.).
>
> When ambiguity exists, use the qualifier: "Lifecycle Stage", "Delivery Phase", or "Diligence Phase".

---

### Capability

**What it is:** A reusable technical competency consumed by one or more Phases. It has no trigger of its own — it is invoked when the Phase requires it.

**Responsibility:** Provide a specific technical mechanism that multiple phases can use without duplicating its definition.

**Abstraction level:** Transversal to phases — not hierarchically below them, but consumed by them.

**Three distinct families:**

| Family | Scope | Examples |
|---|---|---|
| **Delivery Capability** | Framework mechanism consumed by Delivery journey phases | Commit Workflow, Contract Management, Evidence Management, Observability, Reliability |
| **Diligence Capability** | Mechanism consumed by Diligence journey phases | Backlog Synchronization, Work Item Management, Divergence Detection, Artifact Evolution, Workspace Reconciliation |
| **Product Capability** | The product feature being built — the object of work, not the mechanism | Split payment, Pix, webhook confirmation |

**Critical rule:** When context is ambiguous, use the full qualifier: "Delivery Capability", "Diligence Capability", or "Product Capability". Never use "Capability" alone when confusion between the three types is possible.

**Lives in:** `journeys/delivery/capabilities/` (Delivery) and `journeys/diligence/capabilities/` (Diligence).

**Never represents:** A phase, a cycle, a journey, or a skill. Product Capability is not a Framework mechanism — it is the object of work.

---

### Skill

**What it is:** Executable behavior implemented by an agent. Corresponds to a Phase, Cycle, or Journey and describes exactly what the agent must do, when to enter, what to read, and what to produce.

**Responsibility:** Be the executable implementation of a Phase or Journey entry point. It is the bridge between the conceptual model and execution by the agent.

**Abstraction level:** Implementation — not conceptual documentation. A Skill implements a Phase; it does not replace the Phase's definition. Conceptual documentation lives in `journeys/`; executable Skills live in `skills/`.

**Contains:** Steps (ordered sub-units within a Skill).

**Lives in:** `prodops/skills/` — separate from conceptual documentation.

**Never represents:** Conceptual documentation, templates, artifacts, or capabilities.

→ [skills/README.en.md](../skills/README.en.md)

---

### Step

**What it is:** An ordered sub-unit within a Skill, with its own input and output.

**Responsibility:** Implement a specific step within a Skill in a self-contained, isolated way. A Step can be invoked individually when needed.

**Abstraction level:** Implementation — below Skill. A Step does not exist in the conceptual model above the Skill level; it belongs exclusively to the implementation dimension.

**Contains:** Executable instructions, references to input and output artifacts.

**Lives in:** `prodops/skills/<skill>/steps/<step>/SKILL.md` or `prodops/skills/<skill>/<cycle>/steps/<step>/SKILL.md`.

**Never represents:** A Phase, a Capability, or a conceptual artifact.

---

## Concept relationships

| Relationship | Description |
|---|---|
| Framework contains → Journey | The Framework defines the 5 journeys; journeys do not exist outside the Framework |
| Execution Model applies over → Journey | The mode (Upstream/Downstream) defines how the Journey executes; it is not the Journey |
| Journey contains → Cycle | A Journey has one or more Cycles with distinct nature |
| Cycle contains → Phase | A Cycle is the ordered sequence of its Phases |
| Phase consumes → Capability | A Phase invokes Capabilities to execute reusable mechanisms |
| Skill implements → Phase | A Skill is the executable implementation of a Phase (or Cycle/Journey routing) |
| Skill contains → Step | A Step is a sub-unit of the Skill, invocable individually |
| Capability ≠ Skill | Capability is a conceptual mechanism; Skill is agent-executable behavior |
| Cycle ≠ Journey | A Cycle groups Phases; it does not replace or represent the Journey |
| Step ≠ Phase | Step is implementation; Phase is structural concept |

---

## Disambiguation notes

### Upstream and Downstream are not journeys

Upstream and Downstream are **execution modes** — they define commitment level and quality criteria. Any journey can operate in any mode.

> Wrong: "The item is in Upstream" as a synonym for "it is in Discovery."
> Correct: "The item is in Discovery, in Upstream mode."

### Cycles vs. Groupings

In some earlier ProdOps documents, "CI Sync" and "CI Async" are called "groupings" (agrupamentos). The canonical term is **Cycle**. Grouping is informal description; Cycle is the formal concept.

### Capability is not hierarchically below Phase

Capability is consumed by Phase, but is not "inside" Phase in the hierarchy. It is transversal — the same mechanism (e.g., Evidence Management) is consumed by multiple phases across different journeys.

### OBC Partitioning is a process, not a Capability

Some ProdOps documents refer to "OBC Partitioning" as a "capability". In the ProdOps ontology, OBC Partitioning is a **governance process** (owned by Portfolio PM + Tech Leads) executed between Discovery in the BIB and the creation of Local OBCs in Product Backlogs. It is neither a Delivery Capability nor a Diligence Capability. See [obc.en.md](obc.en.md).

---

## Canonical source

This document (`ontology.en.md`) is the canonical source of the ProdOps concept hierarchy.

| Document | Role in relation to the ontology |
|---|---|
| `glossary.en.md` | Full lexical definitions of terms — references this ontology for hierarchy |
| `operating-model.en.md` | Operational model with work flow — references this ontology for concepts |
| `execution-model/README.en.md` | Upstream and Downstream detail — subset of this ontology |
| `journeys/*/README.en.md` | Each journey's detail — references Cycle and Phase from this ontology |
| `skills/README.en.md` | Skills catalog — references this ontology for Skill and Step positioning |
