---
name: upstream
description: Execute ProdOps exploratory engineering. Use when exploring, experimenting, implementing disposable code, creating endpoints or integrations, updating contracts, building prototypes, validating hypotheses, refining OBCs, preparing BDDs, updating Reliability Plan or Event Storming, updating the Validation Workbench, or turning uncertainty into Downstream-ready work.
---

# Upstream Skill

## Steps

When invoked with a step argument (`/upstream <step>`), execute only that step
instead of the full flow. Read the corresponding step file and follow it
exclusively — do not run the rest of the flow.

| Step | File | When to use |
|---|---|---|
| `move-to-downstream` | [steps/move-to-downstream/SKILL.md](steps/move-to-downstream/SKILL.md) | Promote a completed experiment to the Downstream delivery flow |
| `deploy-to-sandbox` | [steps/deploy-to-sandbox/SKILL.md](steps/deploy-to-sandbox/SKILL.md) | Deploy experiment branch to real AWS sandbox for provider validation |

If the requested step is not listed, run the full flow.

---

## Purpose

Use this skill for exploratory engineering before committing work to the Downstream delivery flow.

Upstream exists to reduce uncertainty.

It can produce code, prototypes, BDD scenarios, contracts, Validation Workbench changes and updated ProdOps artifacts, but it does not represent a delivery commitment.

## When to Use

Use Upstream when the work is:

- exploratory;
- uncertain;
- experimental;
- a spike;
- a prototype;
- a technical investigation;
- a business flow validation;
- preparation for an OBC;
- preparation for the Reliability Plan;
- not yet ready for Downstream.

## Required Reading

Before starting, read:

- `prodops/artifacts/product/`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/journeys/discovery/README.md`
- `prodops/journeys/discovery/experiments.md`
- `prodops/templates/discovery/experiment.md`
- `prodops/templates/discovery/trail.md`

## Repository Scope Gate

Before creating or updating an experiment, BDD Feature, OBC, prototype,
Validation Workbench flow, or code artifact, verify whether the capability can
be developed or validated in this repository.

Proceed with Upstream execution artifacts only when this repository owns or can
directly exercise at least one of:

- Payments API behavior;
- Payments domain logic;
- provider integration;
- webhook handling;
- persistence;
- API/event contract owned by Payments;
- Validation Workbench behavior;
- local tests or executable evidence.

If the request belongs primarily to another repository or system, do not create
Features, experiments, prototypes, or implementation artifacts here. Capture it
only as an external dependency, release risk, Repository Tracking List item, Reliability
Plan note, or required evidence from the owning team.

Out-of-repository examples:

- Checkout Feature Flag implementation or rollout targeting;
- Notification Service delivery behavior;
- Order Management fulfillment behavior;
- corporate ITSM integration not implemented by Payments API.

## Operating Rules

Every Upstream experiment must:

1. Apply the Repository Scope Gate.
2. Start with explicit questions.
3. Define a hypothesis.
4. Produce executable artifacts only when this repository can validate them.
5. Update the Validation Workbench only for flows this repository can exercise.
6. Stop when the hypothesis is answered.
7. Avoid expanding into unrelated or out-of-repository capabilities.
8. Update impacted ProdOps artifacts.
9. Register progress in the active experiment trail at `prodops/journeys/discovery/experiments/<NNN-slug>/upstream-trail.md`.
10. Register reusable findings in `prodops/journeys/discovery/learnings.md`.
11. Finish with a recommendation.

## Expected Outputs

An experiment may produce:

- code;
- prototypes;
- Validation Workbench updates;
- BDD scenarios;
- OpenAPI updates;
- AsyncAPI updates;
- OBC drafts;
- Event Storming updates;
- Reliability Plan updates;
- Repository Tracking List items;
- architecture findings.

Documentation alone is acceptable only when the experiment is explicitly documentation-only.

## Artifact Updates

Whenever new knowledge is produced, update impacted artifacts.

Possible targets:

- `prodops/artifacts/product/context/product-deck.md`
- `prodops/artifacts/product/context/service-decks/`
- `prodops/artifacts/product/backlogs/tracking-list.md`
- `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (BDD Features — stay here until move-to-downstream)
- `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` (OBC drafts — stay here until move-to-downstream)
- `prodops/journeys/assessment/event-storming/`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/artifacts/business/obcs/` (committed OBCs — only after move-to-downstream)
- `prodops/artifacts/business/bdd/` (committed BDD Features — only after move-to-downstream)
- `prodops/journeys/discovery/learnings.md`
- `prodops/journeys/discovery/experiments/<NNN-slug>/upstream-trail.md`
- `prodops/journeys/discovery/upstream-trail.md` only for global milestones, promotions, migrations, or repository-wide Upstream process changes

Do not update unrelated artifacts.

## Experiment Completion

An experiment is complete when:

- the original hypothesis has been validated or rejected;
- all questions have been classified as answered, partially answered or still unknown;
- code or executable evidence has been produced when useful;
- architecture impact has been documented;
- impacted artifacts have been updated;
- new backlog items have been classified;
- a recommendation has been produced;
- the Decision Package is complete.

## Recommendation Options

Every experiment must end with one recommendation:

- Move downstream.
- Run another upstream experiment.
- Discard the capability.
- Wait for business decision.
- Wait for external dependency.

## Golden Rule

Upstream produces learning.

Code is a vehicle for learning.

Do not continue implementation after the experiment question has been answered.

## Guardrails

- Do not create GitHub Issues, PRs, or Discussions without declaring artifact_type, artifact_id, operation, and journey. Follow the Work Item schema: `prodops/framework/execution-mapping/work-item-schema.md`.
- Use the canonical Work Item title pattern: `[Operation] — [Artifact Type] [Artifact ID]: description`.

## References

→ [Execution Mapping](../framework/execution-mapping/README.md)
→ [Work Item Schema](../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../framework/execution-mapping/matrix.md)
