# Framework Flow

The official ProdOps Framework flow describes the path every change takes from its origin to continuous operation.

```
Origin Stream → Intent → Mode (Upstream or Downstream) → OBC draft (Business Intent Backlog / Product Intent Backlog) → Exploration + Assessment → Reliability Plan → Assessment Review → committed OBC/BDD → Iteration Plan → Delivery → Operation
```

This document is the canonical reference for understanding **what happens at each step**, **what is produced**, and **when to advance**.

→ [Origin Streams: the four possible origins](origin-streams.en.md)
→ [Operating model: Framework hierarchy](operating-model.en.md)
→ [Glossary: canonical definitions](glossary.en.md)

---

## Full diagram

```mermaid
flowchart TD
    OS["Origin Stream\n(Business | Enterprise | Team | Technology)"]
    I["Intent"]
    DRAFT["OBC draft\n(BIB or PIB)"]
    EX["Exploration\n(Journey: Discovery; rigor by mode)"]
    AS["Assessment\n(transversal)"]
    RP["Reliability Plan\n(recommended)"]
    REV["Assessment Review\n(PM + Tech Lead)"]
    OBC["OBC + BDD\ncommitted"]
    IP["Iteration Plan\n(status: Entrou)"]
    D["Delivery\n(Journey: Delivery, Mode: Downstream)"]
    OP["Operation\n(Journey: Operation)"]

    OS --> I
    I --> DRAFT
    DRAFT --> EX
    EX --> REV
    DRAFT -.-> AS
    EX -.-> AS
    AS -.-> RP
    RP -.-> REV
    REV --> OBC
    OBC --> IP
    IP --> D
    D --> OP

    EX -.->|"Discard (sufficient learning)"| X[Close without advancing]
    EX -.->|"Requires further exploration"| EX

    style OS fill:#e2e3e5,stroke:#6c757d
    style OBC fill:#cce5ff,stroke:#004085
    style D fill:#d4edda,stroke:#155724
    style X fill:#f8d7da,stroke:#721c24
```

---

## Flow steps

### 1. Origin Stream

**Objective:** Classify the origin of the change to establish the correct context.

**What happens:** A contributor, stakeholder, or process identifies a need. The need is classified into one of the four Origin Streams: Business, Enterprise, Team, or Technology.

**What is produced:** The raw need, not yet formalized as an Intent.

**When to advance:** As soon as the origin is clear and Intent registration can begin.

→ [Definition of each Origin Stream](origin-streams.en.md)

---

### 2. Intent

**Objective:** Formalize the need as an explicit intention, without implementation commitment.

**What happens:** The raw need is registered as an Intent. The Intent documents: the value intended to be generated, the context that motivated the need, the initial hypotheses, and the open questions. No solution is defined at this point.

**What is produced:**
- Intent document in `prodops/business-intents/<slug>.md`
- Declared Origin Stream
- Listed hypotheses and open questions
- Suggested execution mode (Upstream or Downstream)

**When to advance:** As soon as the Intent is registered and there is a decision to continue (not discard).

> The OBC Draft is born automatically when a Business Intent enters the **Business Intent Backlog** (global flow) or the **Product Intent Backlog** (local flow) — **before** Discovery, before Upstream, before Downstream. During Upstream it remains in Draft. In Downstream, it is refined in the Icebox until reaching Minimum OBC, then controls the entire Delivery evolution.

→ [Intent template](../templates/business-intents/intent.en.md)

---

### 3. Exploration

**Objective:** Transform the Intent into validated knowledge, reducing uncertainty before any formal delivery commitment.

**What happens:** The Discovery Journey explores the Intent with the rigor defined by the execution mode. In Upstream there is no delivery commitment and maturity may vary; in Downstream all current gates apply. Hypotheses may be tested through experiments, spikes, prototypes, and Event Storming.

**What is produced:**
- Experiment in `prodops/journeys/discovery/experiments/<NNN-slug>/`
- Decision Package (hypothesis answered, clear recommendation, learnings)
- OBC draft refined
- BDD Feature draft
- Risk and opportunity updates

**When to advance:** When the central hypothesis has been answered, the expected behavior is sufficiently understood, and the remaining uncertainty is acceptable to enter Downstream. The decision to advance is explicit (PM + Tech Lead).

**When not to advance:** If the hypothesis was refuted, uncertainty is still too high, or an external business decision is missing. In these cases: record the learning and close the experiment without promoting.

→ [Discovery Journey](../journeys/discovery/README.en.md)
→ [Execution Mode Upstream](../execution-model/upstream.en.md)

---

### 4. Observable Business Contract (OBC)

**Objective:** Transform the knowledge validated by Exploration into an observable and verifiable contract.

**What happens:** The OBC draft produced in Exploration is reviewed, refined, and promoted to `prodops/artifacts/obcs/`. The OBC defines measurable success criteria that anchor all subsequent implementation. Without a committed OBC, there is no Downstream.

**What is produced:**
- OBC committed in `prodops/artifacts/obcs/<slug>.md`
- BDD Feature committed in `prodops/artifacts/bdd/<slug>.feature`

**When to advance:** OBC is in `prodops/artifacts/obcs/`, BDD Feature is in `prodops/artifacts/bdd/`, both reviewed and approved.

→ [OBC artifacts](../artifacts/obcs/)
→ [Promotion process](../journeys/discovery/README.en.md#promotion-to-downstream-process)

---

### 5. Reliability Plan

**Objective:** Define, through the transversal Assessment journey, the reliability conditions required before commitment in the Iteration Plan.

**What happens:** Identified risks are transformed into a reliability plan. SLOs, mitigation actions, rollback criteria, and failure points are explicitly documented. Assessment runs in parallel with other journeys.

**What is produced:**
- Entry in the Reliability Plan in `prodops/journeys/assessment/reliability-plans/`
- Risks updated in `prodops/journeys/assessment/risks.md`

**When to advance:** Reliability Plan updated and Assessment Review completed for the item.

→ [Reliability Plans](../journeys/assessment/reliability-plans/)

---

### 6. Iteration Plan

**Objective:** Formally commit the capability to the next delivery iteration after Assessment Review.

**What happens:** The approved set — OBC, BDD Feature, risks, and Reliability Plan — enters the Iteration Plan with status `In`. This represents the formal delivery commitment; it is not, in isolation, proof of readiness.

**What is produced:**
- Entry in the Iteration Plan in `prodops/artifacts/plans/iteration-plan.md` with status `In`
- Repository Tracking List update if the item was there

**When to advance:** All Downstream readiness gates are satisfied.

→ [Iteration Plan](../artifacts/plans/iteration-plan.en.md)

---

### 7. Delivery

**Objective:** Implement the capability with traceability, verifiable acceptance criteria, and evidence recorded at each step.

**What happens:** Downstream work follows the mandatory sequence `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`, divided into CI Sync (local work) and CI Async (platform and pipelines).

**What is produced:**
- Delivered and promoted software
- Updated Release Trail
- Recorded evidence
- Validated OBC

**When to advance:** Promote completed, Release Trail updated, OBC validated in production.

→ [Delivery Journey](../journeys/delivery/README.en.md)
→ [Execution Mode Downstream](../execution-model/downstream.en.md)

---

### 8. Operation

**Objective:** Continuously operate and monitor the delivered software, ensuring that OBC criteria are maintained over time.

**What happens:** Runbooks, SLO monitoring, alerts, incident response, postmortems, operational trail updates. Operation feeds Continuous Assessment, which can generate new Intents.

**What is produced:**
- Updated Operational Trail
- Documented incidents
- Postmortems when relevant
- New Intents (via Continuous Assessment)

**When to advance:** Operation is continuous — it has no defined end point. The cycle restarts with new Intents generated by operational learning.

→ [Operation Journey](../journeys/operation/)

---

## Naming notes

**Exploration vs Discovery vs Upstream**

These three terms describe different aspects of the same phase of the flow:

| Term | Level | Meaning |
|---|---|---|
| **Exploration** | Flow step | What happens between Intent and OBC: uncertainty reduction |
| **Discovery** | Journey | The name of the Framework journey that implements Exploration |
| **Upstream** | Execution Mode | The execution mode (low commitment) used during Discovery |

When describing the macro flow, use **Exploration**. When referencing the specific journey, use **Discovery**. When referencing the execution mode, use **Upstream**.

---

## References

→ [Origin Streams](origin-streams.en.md)
→ [Glossary](glossary.en.md)
→ [Operating model](operating-model.en.md)
→ [Execution Model](../execution-model/README.en.md)
→ [Journeys](../journeys/README.en.md)
