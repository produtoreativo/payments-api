---
name: validate
description: Validate release behavior with evidence, metrics, SLOs, and operational signals. Emits Validate.Started, Shared.Gate.Passed, and Validate.Completed via prodops_emit_event.
---

# VALIDATE

Use this skill to prove release readiness with evidence.

## Required input context

Read the context capsule at `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
All fields below must be available:

- `work-item-id` — capsule field `work-item-id`
- `iteration-id` — capsule field `iteration-id`
- `correlation-id` — capsule field `correlation-id`
- `actor-player` — capsule field `actor-player`
- `obc-path` — capsule field `obc-path` (acceptance criteria for validation)
- `bdd-path` — capsule field `bdd-path` (BDD scenarios for validation in the target environment)
- `plan-bootstrap-path` — capsule field `plan-bootstrap-path`
- `plan-validate-path` — capsule field `plan-validate-path`
- `reliability-path` — capsule field `reliability-path` (optional; use SLOs if `!= "none"`)

If invoked standalone (without a capsule), generate a new `correlation-id`.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Phase: Validate.Started

**Moment**: after input context is verified, before any validation work begins.

Emit:

```json
{
  "event": "Delivery.Validate.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Shared.Gate.Passed

**Moment**: after acceptance evidence is collected and all quality gates pass — before emitting `Validate.Completed`.

Emit using the **same `correlation-id`**:

```json
{
  "event": "Shared.Gate.Passed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

## Phase: Validate.Completed

**Moment**: after `Shared.Gate.Passed` is accepted, before reporting success.

Emit using the **same `correlation-id`**:

```json
{
  "event": "Delivery.Validate.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "validate-agent" },
  "payload": {}
}
```

Do not emit `Validate.Completed` if evidence is incomplete or any quality gate fails.

## Plan Validate gate — after Validate.Completed

After emitting `Validate.Completed` successfully, check if there is an Iteration Plan context:

1. Read `plan-bootstrap-path` from the capsule — if it does not exist, skip this block (standalone execution).
2. Read or create `plan-validate-path` from the capsule:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "issues": {
       "<work-item-id>": "validated"
     }
   }
   ```
4. Mark `issues.<work-item-id>: "validated"` and save the file.
5. Check if **all** `issues` from plan-bootstrap are marked `"validated"`.
6. If yes — all validated:
   - Emit `Delivery.Plan.Validated` with `subject: <iteration-id>` and `work-item-id: null` in the payload, listing the issues in the `"issues"` field.
   - Update `plan-validate.json` with `"status": "all-validated"` and `"all-validated-at": <timestamp>`.
   - Commit the file.
   - Report to caller: `Plan Validated — all items approved; Promote unblocked.`
7. If no — some issues still pending:
   - Commit the updated file.
   - Report to caller which issues have not yet validated (pending list).
   - **Do not emit** `Delivery.Plan.Validated`.
   - The Promote for this issue remains blocked until the plan gate passes.

## Inputs

- `AGENTS.md`
- Relevant OBCs under `prodops/`
- Relevant BDD Features in `prodops/artifacts/bdd/` (committed) or `prodops/artifacts/experiments/<NNN-slug>/features/` (exploratory)
- `prodops/artifacts/plans/reliability/`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`

## Flow

1. Identify the capability, OBC, or risk being validated.
2. Select tests, metrics, logs, events, or SLO evidence that prove it.
3. Run validation commands or inspect existing evidence.
4. Record exact commands, observed result, and remaining risk.
5. Update only impacted validation or reliability artifacts.
6. Append evidence to the Release Trail.

## Guardrails

- Do not invent metrics or SLOs.
- If an SLO is absent, record the gap in the appropriate ProdOps artifact.
- Prefer executable evidence over narrative claims.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Evidence standards, Definition of Done, Test Quality Gates |
| [`../references/engineering/tdd-prodops/observability.md`](../references/engineering/tdd-prodops/observability.md) | What to verify in logs, traces, and correlation IDs |
