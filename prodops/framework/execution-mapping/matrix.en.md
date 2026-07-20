# Execution Mapping Matrix

Complete mapping of all Knowledge Space Artifacts against allowed operations, GitHub resources, journeys, execution modes, expected evidence, and responsible parties.

**Reading:** each row is an operation on an artifact. The "GitHub Resources" column indicates what the operation CAN generate — not what it must necessarily generate.

→ [Execution Mapping](README.en.md)
→ [Work Item Schema](work-item-schema.en.md)

---

## Legend

| Symbol | Meaning |
|---|---|
| Issue | GitHub Issue |
| PR | Pull Request |
| Disc | GitHub Discussion |
| Rel | GitHub Release |
| WF | GitHub Workflow (Actions) |
| Mile | GitHub Milestone |

**Responsible parties:**
- PO — Product Owner
- PCE — Product Context Engineer
- PRE — Product Reliability Engineer
- SE — Software Engineer
- PE — Platform Engineer
- Arch — Architecture
- TL — Tech Lead
- PPM — Portfolio PM

---

## Business Signal

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Capture` | Issue | Discovery, Diligence | N/A | Signal documented in Tracking List | PCE, PO |
| `Review` | Issue | Discovery | N/A | Assessment notes recorded in Signal | PCE, PO |
| `Promote → Business Intent` | Issue | Discovery | N/A | Business Intent created; Signal referenced | PO, PCE |
| `Discard` | Issue | Discovery, Diligence | N/A | Discard justification in Signal | PO |

**Never:** PR (Business Signal is not an agent-committable file), Release, Milestone

---

## Business Intent

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | Issue | Discovery | N/A | Intent document created in `artifacts/business/intents/` | PO, PCE |
| `Refine` | Issue, PR | Discovery | Upstream | OBC Draft updated; hypotheses recorded | PCE, TL |
| `Explore` | Issue, Disc | Discovery | Upstream | Exploration results in OBC | PCE, SE |
| `Review` | Issue, Disc | Discovery, Assessment | Upstream → Down | Review checklist; decision recorded | PO, TL |
| `Approve → Committed` | Issue | Assessment | Downstream | OBC in Committed state; minimums validated | PO, TL |
| `Prioritize` | Project Item | Discovery, Delivery | Both | Priority recorded in Project | PO |
| `Split → Local OBCs` | Issue | Discovery | N/A | N Local OBC documents created | PPM, TLs |
| `Promote → Product Backlog` | Issue | Discovery | N/A | Intent routed to Product Backlog | PPM, PO |
| `Archive` | PR | Operation | N/A | Closure note in Intent | PO |

**Never:** Release (the Intent is not a delivery; its artifacts are)

---

## Global OBC

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | PR | Discovery | Upstream | OBC Draft in portfolio repository | PPM, TL |
| `Refine` | PR, Issue | Discovery | Upstream | OBC evolved with new hypotheses and data | PPM, TL |
| `Review` | Issue, Disc | Discovery, Assessment | Upstream | Comments and decisions recorded | PPM, TLs |
| `Approve` | Issue | Assessment | Downstream | OBC in Committed state | PPM |
| `Update` | PR | Delivery, Operation | N/A | OBC updated with delivery/operation evidence | PPM, TL |
| `Split` | Issue | Discovery | N/A | N Local OBCs created; traceability table updated | PPM, TLs |
| `Archive` | PR | Operation | N/A | Closure note; Archived state | PPM |

**Never:** is an Issue; automated WF

---

## Local OBC

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | PR | Discovery | Upstream | `artifacts/business/obcs/<slug>.md` in Draft state | PM, TL |
| `Refine` | PR, Issue | Discovery, Assessment | Upstream | OBC in Refining state; criteria emerging | PM, TL, SE |
| `Review` (Assessment) | Issue, Disc | Assessment | Upstream → Down | Assessment checklist completed | PM, TL |
| `Approve` (→ Committed) | Issue | Assessment | Downstream | OBC in Committed state; minimums validated | PM, TL |
| `Implement` | PR | Delivery | Downstream | Code; BDD executed; PR approved | SE |
| `Update` | PR | Delivery, Operation | Both | OBC updated with real evidence | SE, PM |
| `Validate` | WF, Issue | Delivery | Downstream | CI pass; acceptance tests green | SE, PRE |
| `Archive` | PR | Operation | N/A | Archived state; closure note | PM |

**Never:** is an Issue; Release (Release references the delivery, not the OBC directly)

---

## BDD Feature

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | PR | Discovery, Delivery | Upstream | `.feature` file in `artifacts/business/bdd/` | PCE, SE |
| `Refine` | PR | Discovery | Upstream | `.feature` updated with new scenarios | PCE, SE |
| `Review` | PR review | Assessment, Delivery | Downstream | PR approved; comments resolved | PM, TL |
| `Validate` | WF | Delivery | Downstream | CI pass; all scenarios green | SE |
| `Update` | PR | Delivery, Operation | Downstream | `.feature` updated with edge case or regression scenario | SE, PCE |
| `Deprecate` | PR | Operation | N/A | Scenario marked as deprecated in file | SE, PCE |

**Never:** standalone Issue; Discussion; Release

---

## Architecture

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Register` | PR | Delivery | Both | `artifacts/product/architecture/overview.md` updated | SE, Arch |
| `Review` | Issue, Disc | Delivery, Assessment | Both | Comments and decisions recorded | Arch, TL |
| `Update` | PR | Delivery | Both | Diagram updated; new component/route/table registered | SE, Arch |
| `Deprecate` | PR | Operation | N/A | Component marked as deprecated in diagram | Arch |

**Guardrail rule (from AGENTS.md):** PR that adds a NestJS module, route, external dependency, DynamoDB table, event topic, or SQS queue MUST include an update to overview.md.

**Never:** standalone Issue without corresponding PR; Release

---

## Iteration Plan

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | Mile, PR | Delivery | Downstream | `artifacts/governance/plans/iteration-plan.md` created | PO |
| `Update` | PR | Delivery | Downstream | Plan updated with progress, decisions, blockers | PO, SE |
| `Close` | Rel, PR | Delivery | Downstream | Release Trail entry; item states recorded | PO, SE |

**Never:** Discussion; standalone Issue for the plan itself (Issues are for items within the plan)

---

## Reliability Plan

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | PR, Issue | Assessment | Downstream | Reliability Plan document created | PRE, TL |
| `Review` | Issue, Disc | Assessment | Downstream | Review checklist; gate decision | PRE, PM, TL |
| `Approve` | Issue | Assessment | Downstream | Reliability gate approved | PRE, PM |
| `Update` | PR | Delivery, Operation | Downstream | Plan updated with SLO results and incidents | PRE |
| `Validate` | WF, Issue | Delivery | Downstream | SLOs verified; thresholds within expected range | PRE |

**Conditional gate:** Reliability Plan required when there is money movement, external integration, SLO change, high/critical risk, or persistence/security change.

---

## Release Trail

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | Rel, PR | Delivery | Downstream | Entry in `artifacts/governance/trails/release-trail.md` | SE, PO |
| `Update` | PR | Operation | N/A | Trail updated with postmortem, incident, or review | SE, PRE |

**Never:** standalone Issue; Discussion; Milestone

---

## Experiment

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Define` | Issue, Disc | Discovery | Upstream | Experiment plan in `journeys/discovery/experiments/<slug>/` | PCE, SE |
| `Execute` | Branch, PR | Discovery | Upstream | Partial results in experiment directory | SE, PCE |
| `Evaluate` | Issue, Disc | Discovery | Upstream | Evaluation documented; hypothesis confirmed or refuted | PCE, PO |
| `Promote` | PR | Discovery | Upstream → Down | Artifact graduated to `prodops/artifacts/`; experiment archived | PCE, TL |
| `Discard` | Issue | Discovery | Upstream | Discard justification; experiment marked as discarded | PCE |

---

## Evidence

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Capture` | PR (within OBC or Trail update) | Operation, Delivery | Both | Evidence recorded in source artifact | SE, PRE |
| `Attach` | PR | Operation, Diligence | Both | Evidence link added to OBC or Trail | SE |
| `Review` | Issue | Diligence, Operation | Both | Evidence quality review recorded | PRE, PM |

**Note:** Evidence does not exist as a standalone artifact — it always belongs to an OBC, Trail, or Experiment. The Work Item references the artifact that contains the evidence.

---

## Context Capsule

**Classification:** Execution-generated — not a Knowledge Space artifact.

The Context Capsule (`prodops/exec/cards/<slug>/context.md`) is automatically generated by Downstream readiness from existing knowledge artifacts (OBC, BDD, Risks, Reliability Plan). It is an execution context document — ephemeral and derived.

**Has no Work Items of its own.** Work Items affecting a delivery's context reference the source artifacts (OBC, BDD, etc.), not the Context Capsule.

**Generated by:** `/downstream` skill during the Readiness gate.
**Location:** `prodops/exec/cards/<card-slug>/context.md`
**Survives:** only the current delivery — it is not long-term history.

---

## Risk Register

| Operation | GitHub Resources | Journeys | Mode | Expected Evidence | Responsible |
|---|---|---|---|---|---|
| `Create` | PR, Issue | Assessment | Downstream | `journeys/assessment/risks.md` updated | PRE, TL |
| `Update` | PR | Assessment, Delivery | Downstream | Risk revised (probability, impact, mitigation) | PRE |
| `Review` | Issue | Assessment | Downstream | Decision to accept, mitigate, or escalate the risk | PRE, PM, TL |
| `Close` | PR | Operation | N/A | Risk resolved; closure note | PRE |

---

## Summary by GitHub resource

| Resource | Artifacts it can reference |
|---|---|
| **Issue** | Business Signal, Business Intent, Local OBC, Global OBC, Experiment, Risk Register, Reliability Plan, Evidence |
| **Pull Request** | All artifacts that exist as Markdown files |
| **Discussion** | Business Intent, Global OBC, Local OBC, Architecture, Experiment |
| **Release** | Iteration Plan, Release Trail |
| **Workflow** | BDD Feature, Local OBC, Reliability Plan |
| **Milestone** | Iteration Plan |
| **Project Item** | Business Intent (prioritization) |

---

## Operations never allowed (for any artifact)

| Prohibited operation | Reason |
|---|---|
| Artifact **is** a GitHub Issue | Issue represents work; artifact is knowledge |
| GitHub Issue state synchronizes artifact state | States are independent |
| Closing Issue changes artifact state | The Issue closes because work ended; artifact state changes when its criteria are satisfied |
| Creating Issue without referencing an artifact | Issue without artifact reference is work without context |
| Artifact as `contains` in GitHub Project | Projects contain Work Items, not artifacts |

---

## References

→ [Execution Mapping](README.en.md)
→ [Work Item Schema](work-item-schema.en.md)
→ [Knowledge vs Execution](../knowledge-vs-execution.en.md)
→ [OBC](../obc.en.md)
→ [Artifact Governance](../artifact-governance.en.md)
