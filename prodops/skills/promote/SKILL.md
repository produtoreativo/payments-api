---
name: promote
description: Approve and close a release stage. Emits Promote.Started and Promote.Completed via prodops_emit_event.
---

# PROMOTE

Use this skill to move a release to the next stage or close it.

## Required input context

Before starting, the agent must have:

- `work-item-id` — the GitHub issue number of the Feature
- `iteration-id` — the Iteration Plan identifier
- `actor.player` — the current player (`claude`, `codex`, or `copilot`)
- `correlation-id` — the Delivery-flow UUID provided by the chain runner. If
  invoked standalone, generate a new UUID.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

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

## Guardrails

- Do not promote when required evidence is missing.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
