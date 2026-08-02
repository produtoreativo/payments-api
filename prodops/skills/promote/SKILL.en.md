---
name: promote
description: Approve and close a release stage. Emits Promote.Started and Promote.Completed via prodops_emit_event.
---

# PROMOTE

Use this skill to move a release to the next stage or close it.

## Required input context

Read the context capsule at `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
All fields below must be available in the capsule:

- `work-item-id` — capsule field `work-item-id` (issue for the current iteration)
- `iteration-id` — capsule field `iteration-id`
- `correlation-id` — capsule field `correlation-id` (generated at `Delivery.Plan.Bootstrap.Issue.Entered`)
- `actor-player` — capsule field `actor-player`
- `plan-bootstrap-path` — capsule field `plan-bootstrap-path`
- `plan-validate-path` — capsule field `plan-validate-path`
- `timeline-path` — capsule field `timeline-path` (used for lead-time calculation)
- `reliability-path` — capsule field `reliability-path` (optional; consult risks if `!= "none"`)

If invoked standalone (without a capsule), generate a new `correlation-id`.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Plan Promote gate — verify before Promote.Started

If `plan-bootstrap-path` from the capsule exists with `"status": "completed"` (execution inside an Iteration Plan):

1. Read `plan-validate-path` from the capsule.
2. If the file does not exist or `status != "all-validated"`: **block**. Do not emit `Promote.Started`. Report which issues in the plan have not yet completed Validate and wait.
3. If `status == "all-validated"`: proceed with the flow below normally.

If the plan-bootstrap file does not exist (standalone execution): proceed without plan verification.

## Phase: Promote.Started

**Moment**: after input context is verified, before any promotion work begins.

Emit:

```json
{
  "event": "Delivery.Promote.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "promote-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Promote.Completed

**Moment**: after all promotion steps complete and Release Trail is updated — before reporting success.

Emit using the **same `correlation-id`** as Promote.Started:

```json
{
  "event": "Delivery.Promote.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "promote-agent" },
  "payload": {}
}
```

Do not emit `Promote.Completed` if evidence is missing, risks are unresolved, or operational readiness is not confirmed.

## Automatic lead-time

When emitting `Promote.Completed`, the `emit-event` tool automatically calculates the feature's lead-time and sends the metric `runtime.delivery.lead_time_days` to Datadog — no manual action required.

How it works:
1. Locates the first `Bootstrap.Started` in the issue's timeline (`timelines/<issue>.json`)
2. Calculates `delta = Promote.Completed.timestamp − Bootstrap.Started.timestamp` in days
3. Emits gauge `runtime.delivery.lead_time_days` via Datadog sync (non-fatal — silent failure)

The agent does not need to calculate or send this metric manually. Simply ensure that `Bootstrap.Started` is present in the timeline (correctly emitted by the Bootstrap skill). If absent, the calculation is skipped and a warning is logged.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/framework/journeys/operation/`

## Flow

1. Confirm required validation and quality gates are complete.
2. Confirm unresolved risks are accepted, mitigated, or moved to follow-up.
3. Check operational readiness: incidents, runbooks, postmortems, and
   operational trail.
4. Record approval, evidence, and remaining next steps.
5. Append promotion or closure notes to the Release Trail.
6. Close the GitHub Issue:
   ```bash
   gh issue close <work-item-id> --comment "Delivery complete — Promote.Completed emitted. PR #<pr-number> merged into master."
   ```
   This is the canonical close point. The issue must have remained open through
   Ship and Validate — closing here signals full delivery, not just code merge.

## Guardrails

- Do not promote when required evidence is missing.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
