# OBC — Observable Business Contract

The **Observable Business Contract** is the living contract that represents a business intent throughout its entire lifecycle. It is the source of truth for the work — connecting business, product, architecture, engineering, operation, observability, and reliability. No other document should play this role.

→ [OBC Template](../templates/obcs/obc.en.md)
→ [Committed OBCs](../artifacts/obcs/)
→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)

---

## What it is

**Definition:** A product artifact that describes the expected behavior of a capability in observable terms: what the system must do, which events it emits, what service levels it offers, and how it responds to failures.

**Purpose:** To be the shared language between product, engineering, and operation throughout the entire life of the intent. The OBC does not end with Delivery — it continues evolving during Operation.

**Creation:** Born when an Intent is accepted. In the global flow, upon entry into the Business Intent Backlog. In the local flow, upon entry into the Product Intent Backlog. The OBC exists **before** Discovery, **before** Upstream, **before** Downstream.

**Historical note:** previously incorrectly defined as "Outcome-Based Criterion". The canonical definition is **Observable Business Contract**.

---

## Composition

An OBC is composed of seven sections. Sections marked as required for Minimum OBC must be present before entry into the Iteration Backlog.

| Section | Content | Required for Minimum OBC |
|---|---|---|
| **Status** | Current state (Draft / Minimum OBC / Active / Operational / Archived) and backlog location | Yes |
| **Business Outcome** | The business result the capability delivers, in product language | Yes |
| **Observable Events** | Table of events the system emits; each event has meaning and traceable dimensions | Yes |
| **Initial SLIs** | Initial service level indicators with declared targets | Yes |
| **Reliability Rules** | Reliability rules governing behavior in failures and edge cases | Yes |
| **Response Contract** | API or event response contract (expected payload, required fields) | Yes |
| **Related Artifacts** | Links to BDD Feature, Iteration Plan, Icebox, related OBCs | Recommended |

### Status

Indicates the current state of the OBC and where it is located in the backlog cycle. Must be updated at each transition.

### Business Outcome

Describes the result the system delivers from a business perspective — not the technical implementation. Must answer: *for whom, what, and with what guarantee*.

May contain an "In executive language" subsection with a jargon-free explanation, useful for alignment with non-technical stakeholders.

### Observable Events

Lists the events the system emits to signal each relevant outcome. Each event must have:
- **Canonical event name** (e.g., `invoice.created`)
- **Meaning** — what this event represents
- **Required dimensions** — fields the event must carry for traceability

Failure events are as important as success events. The absence of an event within an SLO window is itself an observable signal.

### Initial SLIs

Defines initial service level indicators with quantitative targets. Must be observable via the events declared above. The alignment between events and SLIs is what makes the OBC verifiable.

### Reliability Rules

Explicit rules governing system behavior in failure situations, retry, idempotency, and degradation. These are the invariants the implementation cannot violate.

### Response Contract

Defines the response contract of the capability — returned payload, required fields, conditional fields. Serves as the contract between the capability producer and its consumers.

### Related Artifacts

Lists artifacts directly related to the OBC: corresponding BDD Feature, position in the Iteration Plan, position in the Icebox, and OBCs with direct dependency.

---

## States

| State | When | Description |
|---|---|---|
| **Draft** | Business Intent Backlog / Product Intent Backlog | Created; may be incomplete; records initial intent, hypotheses, and learnings |
| **Minimum OBC** | Iteration Backlog | Minimum set of information required for Delivery entry; gate between Discovery and Delivery |
| **Active** | Iteration Plan → Delivery | In execution; tracks implementation, evidence, validations, and decisions |
| **Operational** | Operation | Feature in production; updated with operational information |
| **Archived** | — | No longer part of active evolution; history preserved |

---

## Lifecycle

| Backlog / Phase | OBC State | What happens |
|---|---|---|
| Global Tracking List / Repository Tracking List | Does not exist | The item is not yet a recognized Intent |
| Business Intent Backlog (global flow) | Draft | OBC created; captures the Intent and initial hypotheses |
| Product Intent Backlog (local flow) | Draft | OBC created upon acceptance by the Product Owner |
| Icebox (Discovery) | Draft in refinement | Discovery refines the OBC; criteria emerge; Upstream may occur |
| Assessment Review | Minimum OBC candidate | OBC reviewed by PM + Tech Lead; required sections validated |
| Iteration Backlog | Minimum OBC | Minimum OBC validated; Downstream can begin |
| Iteration Plan / Delivery | Active | Guides implementation; BDD Feature operationalizes it |
| Operation | Operational | In production; complemented with metrics, SLOs, incidents, postmortems |
| — | Archived | Intent closed; history preserved |

The OBC records the **living history of the work**: which backlogs it passed through, when, decisions made, how criteria evolved, references to experiments and risks.

---

## OBC in Upstream

During Upstream, the OBC remains in Draft. It can be freely modified, may be incomplete, and does not block experiments. It records learnings, hypotheses, and decisions produced by experiments. No Skill should require a complete OBC during Upstream.

OBCs produced within Upstream experiments remain in the experiment directory (`prodops/journeys/discovery/experiments/<NNN-slug>/obcs/`) until formal promotion to `prodops/artifacts/obcs/`.

---

## OBC in Downstream

Upon entering Downstream, the OBC ceases to be merely a record — it becomes the operational contract of the delivery. It is refined in the Icebox until reaching Minimum OBC, then controls the entire evolution of subsequent journeys.

The minimum set required to start Downstream:
- OBC committed in `prodops/artifacts/obcs/<slug>.md` with Minimum OBC state
- BDD Feature committed in `prodops/artifacts/bdd/<slug>.feature`
- Reliability Plan updated in `prodops/journeys/assessment/reliability-plans/`

---

## OBC and Skills

All Downstream Skills use the OBC as their primary source of context. Skills never generate parallel information that replaces the OBC. New artifacts produced by Skills complement or reference the OBC. The OBC remains the single source of truth for the intent.

---

## Governance

| Field | Value |
|---|---|
| **Owner** | Product Manager + Tech Lead of the item |
| **Where it's born** | Business Intent Backlog (global flow) or Product Intent Backlog (local flow) |
| **Canonical artifact** | `prodops/artifacts/obcs/<slug>.md` (when committed) |
| **Who modifies** | Product Manager, Tech Lead, engineers (with change record) |
| **Who approves** | Product Manager + Tech Lead (Assessment Review) |
| **Consumers** | Delivery, Reliability Plan, BDD Feature, Release Trail, Iteration Plan |
| **Lifecycle** | Draft → Minimum OBC → Active → Operational → Archived |
| **Journeys** | Discovery, Delivery, Operation, Assessment, Diligence |

---

## Artifact location

| Situation | Location |
|---|---|
| Exploratory OBC (in Upstream experiment) | `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` |
| Committed OBC (ready for Downstream) | `prodops/artifacts/obcs/<slug>.md` |

Every committed OBC must have its own file in `prodops/artifacts/obcs/`. Product Decks, Service Decks, BDD Features, Reliability Plans, and other artifacts must reference the corresponding OBC without duplicating its definition.

---

## When not to use

Do not use OBC as a substitute for an isolated technical task or bug ticket without a corresponding Intent. GitHub Issues, Jira Cards, and Azure DevOps Work Items are **operational representations** of an already-existing OBC — they are not the entry point for work.

---

## References

→ [OBC Template](../templates/obcs/obc.en.md)
→ [Committed OBCs](../artifacts/obcs/)
→ [Framework Flow](flow.en.md)
→ [Backlog Hierarchy](backlogs.en.md)
→ [Artifact Governance](artifact-governance.en.md)
→ [Phases: Conception and Inception](phases.en.md)
→ [Discovery Journey](../journeys/discovery/README.en.md)
→ [Reliability Plans](../journeys/assessment/reliability-plans/README.en.md)
