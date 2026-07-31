[Português](README.md)

# Diligence — Cross-cutting Journey

## Definition

> **Diligence is the cross-cutting journey responsible for continuously guaranteeing the consistency of the ProdOps work system, verifying coherence, completeness, traceability, and conformance between knowledge, decisions, execution, and evidence.**

---

## Purpose

Diligence ensures that what was decided, produced, and executed across every journey remains coherent, traceable, and conformant throughout the entire product lifecycle. It does not evaluate, does not decide, does not implement — it verifies, synchronizes, reconciles, and preserves.

---

## Main question

> **Are knowledge, decisions, execution, and evidence still coherent and traceable?**

---

## Cross-cutting nature

Diligence is not a linear step at the end of a flow. It is cross-cutting: it verifies consistency, traceability, completeness, and conformance across all journeys simultaneously.

```
                    DISCOVERY
                        │
                        ▼
                    ASSESSMENT
                        │
                        ▼
                     DELIVERY
                        │
                        ▼
                    OPERATION
                        │
                        └──────────┐
                                   │
DILIGENCE ─────────────────────────┤
                                   │
verifies consistency,              │
traceability, completeness         │
and conformance across             │
all journeys                       │
                                   ▼
                              new signals,
                              decisions and work
```

Diligence accompanies the product as long as it exists. It has no beginning and end per cycle. It is not a weekly meeting or a sprint ritual. It is continuous verification that occurs every time the system state changes — or when periodic scanning detects drift.

---

## The five journeys

| Journey | Central question |
|---|---|
| Discovery | What do we need to understand before making a commitment? |
| Assessment | What is the situation and what must be decided or prepared? |
| Delivery | How do we transform the commitment into verifiable change? |
| Operation | Is the product producing the expected results and behaviors? |
| **Diligence** | **Are knowledge, decisions, execution, and evidence still coherent and traceable?** |

---

## Scope

Diligence governs the consistency of the **ProdOps work system**: artifacts, backlogs, management tools, operational representations, decision trails, and evidence. It does not govern product code or production behavior — those belong to Delivery and Operation.

**The work system includes:**
- Knowledge Space artifacts: Business Signals, Business Intents, OBCs, BDD Features, Reliability Plans, Iteration Plans, Roadmap, Tracking Lists
- Execution Space operational representations: Work Items, Views, GitHub Projects, Labels, Custom Fields
- Decision trails: trails, session records, artifact history
- Traceability relations between artifacts and operations

---

## Limits

### What Diligence CAN do

- Detect divergences between Knowledge Space and Execution Space
- Verify relations between artifacts and Work Items
- Validate transition pre-conditions before a flow advances
- Reconcile Knowledge Space and Execution Space
- Register decisions already legitimized by competent journeys
- Materialize Work Items when there is an active authorized operation
- Verify whether a promotion satisfies existing criteria
- Update derived operational representations
- Produce consistency reports
- Request or register corrections
- Verify that corrections were completely applied
- Preserve historical traceability
- Identify structural or documental drift

### What Diligence CANNOT do

- Decide product strategy
- Prioritize the Product Backlog instead of the Product Owner
- Invent Business Signal, Business Intent, or OBC content
- Approve an OBC on its own
- Substitute Discovery
- Execute Assessment
- Implement product code
- Declare an operational result without evidence
- Transform GitHub Project into the source of truth for the Knowledge Space
- Create an Issue for each artifact by default
- Silently correct canonical content without authorization
- Rewrite historical trails to match current vocabulary

---

## Five consistency dimensions

| # | Dimension | What it verifies |
|---|---|---|
| 1 | **Conceptual** | Documents use compatible ontology, vocabulary, states, relations, and responsibilities |
| 2 | **Structural** | Actual file, directory, index, link, and schema structure matches the documented model |
| 3 | **Traceability** | The chain Signal → Intent → OBC → BDD → plans → risks → decisions → Work Items → PRs → Releases → evidence can be reconstructed |
| 4 | **Operational** | GitHub operations respect schema, state, ownership, dependencies, entry/exit criteria, closure, and evidence |
| 5 | **Temporal** | The system preserves history, trails, past decisions, and observed state at each moment. A historical trail with old vocabulary is **not automatically** an inconsistency — only when used as a current normative instruction |

---

## Inputs (what triggers Diligence)

Diligence can be triggered by any of the following events. **Not every event results in creating an Issue or Work Item** — the event starts an evaluation of whether a traceable operation is needed.

- New Business Signal or Business Intent
- OBC creation or update
- Assessment decision
- Artifact state change
- Backlog or View entry
- Active operation without Work Item
- Work Item without valid reference
- Pull Request
- Release
- Change in normative documentation
- Operational evidence
- Incident, risk, or detected divergence
- Periodic execution
- Human request
- Bootstrap execution
- Structural workspace change

---

## Output classes

Output classes that Diligence can produce (without formal schema implementation in this version):

- Synchronization completed
- Operational representation created or updated
- Divergence detected
- Inconsistency reconciled
- Pre-condition validated
- Promotion authorized by existing rules
- Promotion blocked
- Evidence registered
- Consistency report
- Correction recommendation
- Need for Assessment identified
- Need for human decision identified
- Need for new operation identified
- Impossibility of automatic reconciliation

> **Note:** The formal classes Check, Finding, Evidence, Remediation, and Waiver are implemented. See section "Operational entity model" for canonical model references and instance storage location.

---

## Cycles

Diligence operates in exactly **two** complementary cycles. Workspace Reconciliation is a Capability invoked by the cycles — it is not a third cycle.

### diligence-sync — Synchronous and reactive

Triggered by an event or ongoing operation. Contextual: tied to a specific operation or transition. Can block a flow transition when canonical criteria are not satisfied. Not periodic.

```
diligence-sync: Capture → Attach → Promote → Close
```

→ [diligence-sync.md](diligence-sync.md)

### diligence-async — Asynchronous and proactive

Started by periodic scanning or suspected drift. Does not depend on a specific ongoing transaction. Detects accumulated drift and reconciles the system without waiting for an external event.

```
diligence-async: Scan → Flag → Repair
```

→ [diligence-async.md](diligence-async.md)

---

## Phases per cycle

| Cycle | Phase | What it does | What it does NOT do |
|---|---|---|---|
| diligence-sync | **Capture** | Creates or updates the OBC with the canonical state of the decision that triggered the cycle | Does not create Work Items; does not invent content |
| | **Attach** | Verifies if an active Work Item exists; creates one if there is an active operation without tracking | Does not create Issues for passive artifacts |
| | **Promote** | Moves the item through the hierarchy verifying pre-conditions of each transition; blocks when criteria are not met | Does not promote without criteria; does not decide the backlog |
| | **Close** | Closes the Work Item when the OBC reaches Operational and the Release Trail records the delivery | Does not close prematurely; does not erase history |
| diligence-async | **Scan** | Reads all active OBCs; compares with external backlogs; identifies gaps; distinguishes legitimate absence from incomplete relation | Does not repair during Scan; does not create artifacts |
| | **Flag** | Classifies divergences with severity and suggested action; marks as BLOCKED when product decision is required | Does not execute repairs; does not decide on its own |
| | **Repair** | Executes identified corrections; invokes diligence-sync steps for repairable gaps | Does not modify product code; does not silently alter canonical artifacts; does not correct historical trails |

---

## Capabilities

Capabilities are reusable competencies consumed by cycles and by Bootstrap. **They are not independent cycles.**

| Capability | Purpose | Invoked by |
|---|---|---|
| Backlog Synchronization | Keep OBC state consistent across all levels of the backlog hierarchy | Capture, Promote, Repair |
| Work Item Management | Create, update, and close Work Items correctly referencing OBCs, operations, and journeys | Attach, Close, Repair |
| Readiness Verification | Verify pre-requisites before an item advances or enters Delivery | Promote, Scan |
| Divergence Detection | Proactively identify gaps between canonical artifacts and external tools | Scan, Flag |
| Artifact Evolution | Update management artifacts when decisions change the state of the work | Capture, Repair, Close |
| Workspace Reconciliation | Align GitHub Workspace to Canonical Specification via Inspect → Reconcile → Verify | Bootstrap, Diligence Async, Diligence Sync |

→ [Full Capabilities catalog](capabilities/README.md)
→ [Workspace Reconciliation — specification](workspace-reconciliation.md)

---

## Participants and responsibilities

| Role | Decides | Executes | Verifies | Escalate when |
|---|---|---|---|---|
| Product Owner | Backlog priorities, OBC approvals | — | Business alignment | Divergence requires backlog reprioritization |
| Portfolio PM | Portfolio-level decisions | — | Cross-product consistency | Portfolio-level conflict |
| Product Context Engineer | — | Diligence operations | Artifact consistency | OBC content requires business clarification |
| Product Reliability Engineer | — | Reliability checks | Reliability criteria | Reliability Plan missing for qualifying item |
| Tech Lead | Technical decisions | Technical repairs | Technical consistency | Technical risk unresolvable by Diligence |
| AI Agent (authorized) | — | Automated Diligence steps | — | Confidence below threshold or ambiguous source of truth |

---

## Triggers

| Trigger | Cycle typically activated |
|---|---|
| External event (decision, concluded experiment, Operation signal) | diligence-sync |
| Bootstrap execution | Workspace Reconciliation (Capability) |
| Scheduled periodic scan | diligence-async |
| Drift suspected by another agent | diligence-async |
| OBC state transition | diligence-sync (Promote) |
| PR or Release registered | diligence-sync (Attach or Close) |
| Change in normative documentation | diligence-async (Scan) |
| Explicit human request | Any cycle or Capability as appropriate |

---

## Relationship with the other four journeys

### Discovery

Diligence verifies that experiments and learnings from Discovery were registered as artifacts; that Business Signals and Intents were adequately documented; that the mode transition Upstream → Downstream was formally recorded.

**Diligence does not execute Discovery.**

### Assessment

Assessment evaluates, diagnoses, identifies risk/opportunity, recommends, prepares plans, produces or sustains a decision.

Diligence verifies that the decision was registered; synchronizes its operational representation; validates that derived criteria continue to be met; detects divergences; preserves traceability. **Diligence does not redo Assessment.**

**Canonical example:** Assessment concludes "This item requires a Reliability Plan."
Diligence verifies: (1) the decision was registered; (2) the Reliability Plan exists; (3) the item did not advance without the plan; (4) the Execution Space reflects the decision. Diligence does not evaluate whether the decision was correct — only that it was followed.

### Delivery

Diligence ensures that Work Items, BDD Features, Reliability Plans, and other pre-conditions are satisfied before an item enters Delivery. Verifies that Pull Requests reference canonical Work Items. Verifies that the Release Trail correctly records the delivery.

**Diligence does not implement code, does not create implementation PRs, and does not execute Delivery phases.**

### Operation

Diligence receives signals of incidents, risks, and operational evidence; verifies that they were registered in the corresponding artifacts; verifies that OBC state reflects the actual operational state.

**Diligence does not monitor production or declare operational results without evidence.**

---

## Knowledge Space ↔ Execution Space

```
Knowledge Space
    ↓ provides intention, contract, decision and context
Diligence
    ↓ verifies, relates, synchronizes and reconciles
Execution Space
    ↓ executes operations and produces evidence
Diligence
    ↓ verifies results and returns traceable learning
Knowledge Space
```

### Fundamental principles

- **Synchronization is not necessarily bidirectional field-by-field.** Each data point has a single source of truth — synchronization moves data from the source to the derived representation.
- **Each data point has a single source of truth.** The canonical state of an OBC lives in the Markdown file. The operational state of a Work Item lives in the GitHub Issue.
- **GitHub Project CAN:** display, group, filter, derive, and organize work.
- **GitHub Project does NOT replace** canonical Markdown artifact content.

### N:M cardinality

The relationship between Artifacts (Knowledge Space) and Work Items (Execution Space) is **N:M**:
- An artifact can have zero, one, or multiple Work Items throughout its life (one per active operation)
- A Work Item can reference multiple artifacts when the operation affects them jointly
- **Absence of a Work Item is not a divergence** when there is no active operation on the artifact

---

## Sources of truth

| Data | Canonical source of truth |
|---|---|
| OBC state | Markdown file in `prodops/artifacts/obcs/` |
| BDD Feature | `.feature` file in `prodops/artifacts/bdd/` |
| Reliability Plan | Markdown file in `prodops/artifacts/reliability-plans/` |
| Iteration Plan | Markdown file in `prodops/exec/iteration-plans/` |
| Work Item schema | `prodops/framework/execution-mapping/work-item-schema.md` |
| GitHub Workspace spec | `prodops/framework/github-workspace.md` |
| Tracking Lists | Corresponding Markdown files |
| ProdOps Ontology | `prodops/framework/ontology.md` |
| Glossary | `prodops/framework/glossary.md` |

---

## Escalation protocol

Diligence must escalate for human decision when:

- No source of truth is defined for a data point
- Two normative sources conflict
- The correction changes the business intent of the artifact
- The correction changes a state without a satisfied criterion
- Reconciliation requires backlog prioritization
- There is risk of historical data loss
- Automation may modify multiple artifacts without confirmation
- The decision belongs to Product Owner, Portfolio, Assessment, or Tech Lead
- Insufficient evidence to conclude
- The proposed correction violates a previously registered decision

**Escalation targets:** Product Owner, Portfolio PM, Assessment, Tech Lead, Reliability Owner, Framework Owner, Artifact Owner

---

## Anti-patterns

| Anti-pattern | Why it is wrong |
|---|---|
| Creating an Issue for each artifact | Violates the N:M model; pollutes the Execution Space with phantom work |
| Treating absence of Issue as automatic divergence | A passive artifact (no active operation) does not require a Work Item |
| Using Issue as source of truth for the OBC | The canonical OBC lives in the Markdown file — not in the Issue |
| Reusing the same Work Item indefinitely throughout the artifact's life | Each active operation must have its own traceable Work Item |
| Confusing artifact state with Work Item state | They are independent: the artifact can be Committed while the Work Item is Open |
| Promoting an item without satisfied criteria | Violates transition pre-requisites and breaks traceability |
| Inventing artifact content during synchronization | Artifact content is a business decision — Diligence synchronizes, does not invent |
| Executing Assessment inside Diligence | Diligence detects divergences; it does not evaluate or recommend strategy |
| Modifying historical trails to appear current | Historical trails preserve the actual state at the moment — they are not corrected retroactively |
| Silently correcting canonical content without authorization | All canonical content corrections require authorization from the competent journey |
| Classifying Workspace Reconciliation as a Cycle | It is a Capability invoked by cycles — it is not an independent cycle |
| Creating Views before defining schema and rules | Views are derived representations — schema and rules come first |
| Treating Diligence as a linear final step | Diligence is cross-cutting and continuous — it is not a phase that occurs after the others |

---

## Examples

### Example 1 — Passive Business Signal

A Business Signal was registered. No investigation is active.

**Expected state:** The artifact exists in the Knowledge Space (file in the tracking list); no Work Item is needed. The Scan does **not** flag the absence of an Issue as a divergence.

**Key learning:** Artifact without active operation = no Work Item = no divergence.

---

### Example 2 — Business Signal with active operation

An investigation was authorized on the Business Signal.

**Expected state:** Active operation identified; Work Item created or related with structured fields filled (artifact_id, operation, journey); reference to the Business Signal in the Work Item. Absence of Work Item in this situation **is** a divergence.

**Key learning:** Active operation without Work Item = divergence to repair.

---

### Example 3 — OBC promoted to Delivery

Assessment or an authorized party declared OBC readiness.

**Expected state:** Diligence verifies criteria (OBC committed, BDD Feature committed, risks documented); Promote records the transition; an implementation Work Item may be created; OBC and Work Item maintain independent states (OBC can be Committed while the Work Item is Open and in progress).

**Key learning:** Artifact and Work Item states are independent — Diligence verifies them without confusing them.

---

### Example 4 — Drift in GitHub Project

A mandatory field was removed or renamed in the GitHub project.

**Expected state:** Diligence Async runs Scan; divergence flagged; Workspace Reconciliation (Capability) invoked; Inspect identifies current state without modifying anything; Reconcile applies the authorized correction respecting the hierarchy of sources of truth; Verify confirms the result.

**Key learning:** Workspace drift → Workspace Reconciliation (Capability, not Cycle) → Inspect → Reconcile → Verify.

---

## Operational entity model

The operational entities of Diligence — Finding, Check, Evidence, Remediation, and Waiver — are formally specified and implemented. The canonical model defines schemas, states, transitions, validation rules, deduplication, blocking policy, and integration with Diligence cycles.

### Canonical model (framework definitions)

→ [`model/`](model/) — overview, relations, cardinalities, deduplication, blocking policy, 16 anti-patterns
→ [`model/finding.md`](model/finding.md) — Finding: canonical definition, full schema, 5 dimensions, 13 categories, state flow
→ [`model/check.md`](model/check.md) — Check: canonical definition, ID format (DIL-CATEGORY-NNN), schema, 10 types, results
→ [`model/evidence.md`](model/evidence.md) — Evidence: canonical definition, 15 types, schema, immutability, expiration
→ [`model/remediation.md`](model/remediation.md) — Remediation: canonical definition, 8 strategies, schema, state flow
→ [`model/waiver.md`](model/waiver.md) — Waiver: canonical definition, 10 mandatory rules, schema, expiration policy
→ [`checks/`](checks/) — Check catalog directory (normative rule definitions for the framework)

### Instances (product-level records)

→ [`prodops/artifacts/diligence/`](../../../artifacts/diligence/) — actual Finding, Evidence, Remediation, and Waiver records for this product
→ [`prodops/artifacts/diligence/README.md`](../../../artifacts/diligence/README.md) — storage structure, ID policy, protocols, authority matrix, anti-patterns, examples
→ [`prodops/artifacts/diligence/registry.yaml`](../../../artifacts/diligence/registry.yaml) — structured index of all entities

### Templates

→ [`prodops/templates/diligence/`](../../../templates/diligence/) — templates for creating new Finding, Evidence, Remediation, and Waiver instances

### Entity summary

| Entity | ID Format | Role |
|---|---|---|
| **Finding** | `FND-YYYY-NNNN` | Persistent record of a divergence, absence, or relevant condition detected by Diligence |
| **Check** | `DIL-CATEGORY-NNN` | Declarative, reproducible, verifiable rule used to evaluate a condition |
| **Evidence** | `EVD-YYYY-NNNN` | Persistent, referenceable proof of detection, impact, correction, or verification |
| **Remediation** | `RMD-YYYY-NNNN` | Planned and traceable operation to remove, reduce, or control a Finding condition |
| **Waiver** | `WVR-YYYY-NNNN` | Explicit, justified, time-limited authorization to accept a Finding without immediate full remediation |

---

## References

→ [ProdOps Ontology](../../ontology.md)
→ [Glossary](../../glossary.en.md)
→ [Execution Mapping](../../execution-mapping/README.en.md)
→ [Work Item Schema](../../execution-mapping/work-item-schema.md)
→ [Knowledge Space vs. Execution Space](../../knowledge-vs-execution.md)
→ [Backlogs](../../backlogs.en.md)
→ [diligence-sync.md](diligence-sync.md)
→ [diligence-async.md](diligence-async.md)
→ [Capabilities](capabilities/README.md)
→ [Workspace Reconciliation](workspace-reconciliation.md)
