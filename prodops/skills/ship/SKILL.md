---
name: ship
description: Prepare deploy, pull request, or release readiness. Emits Ship.Started and Ship.Completed via prodops_emit_event.
---

# SHIP

Use this skill to prepare completed work for delivery.

For detailed Codex submission mechanics, read `references/workflow.md`.

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

## Phase: Ship.Started

**Moment**: after input context is verified, before any ship preparation work begins.

Emit:

```json
{
  "event": "Delivery.Ship.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Ship.Completed

**Moment**: after all ship steps complete and PR/deploy notes are prepared — before reporting success.

Emit using the **same `correlation-id`** as Ship.Started:

```json
{
  "event": "Delivery.Ship.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

Do not emit `Ship.Completed` if security checks, quality gates, or PR preparation is incomplete.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- Current branch diff and validation evidence

## Flow

1. Confirm the change maps to the current Reliability Plan or documented
   follow-up.
2. Confirm the branch and diff against the intended base.
3. Verify TDD evidence for behavior changes.
4. Run final quality gates: format, lint, build and tests appropriate to the
   changed files.
5. Run security checks for secrets, unsafe config, dependency changes and
   accidental environment leakage.
6. Review the diff as if doing code review.
7. Summarize changed behavior, impacted artifacts and deployment risk.
8. Identify rollback, monitoring and operational notes when applicable.
9. Prepare PR or deploy notes.
10. Append shipping evidence to the Release Trail.

## Guardrails

- Do not ship undocumented behavior changes.
- Do not present missing evidence as complete.
- Do not change business scope during ship preparation.
- Do not include unrelated changes in the PR or deployment package.
- Do not commit secrets, real tokens, personal credentials or local-only paths.
- Tests must cover changed behavior or the residual test gap must be explicit.
- Behavior changes must show TDD evidence or explain why TDD was not applicable.
- PR or deploy notes must explain behavior, validation and risk.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/workflow.md`](../references/engineering/tdd-prodops/workflow.md) | TDD evidence standards (what counts as red/green/refactor proof) |
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Delivery gates checklist before creating a PR |
