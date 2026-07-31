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

Ship observes — it does not execute the merge. The merge is performed
automatically by GitHub once all CI checks pass (auto-merge was enabled during
Finish). Ship's job is to confirm the merge happened and the staging deploy
succeeded.

1. Confirm `Finish.Completed` was emitted for this work item (check timeline).
2. Confirm the PR has auto-merge enabled:
   ```bash
   gh pr view <number> --json autoMergeRequest
   ```
   If auto-merge is not enabled, re-enable it:
   ```bash
   gh pr merge <number> --auto --squash
   ```
3. Poll until the PR is merged:
   ```bash
   gh pr view <number> --json state,mergedAt
   ```
   Check every 30 seconds; timeout after 20 minutes. If CI fails, surface the
   failing check and stop — do not force-merge.
4. Once the PR is merged, confirm the staging deploy workflow started:
   ```bash
   gh run list --workflow staging-deploy.yml --limit 3
   ```
5. Wait for the staging deploy to complete:
   ```bash
   gh run watch <run-id>
   ```
6. Confirm the staging environment is responsive after deploy.
7. Record the merge SHA, deploy run ID and result in the Release Trail.
8. Append shipping evidence to the Release Trail.

## Guardrails

- Do not merge manually. The only authorized merge path is GitHub auto-merge
  triggered by CI passing.
- Do not emit `Ship.Completed` if CI checks failed or the staging deploy failed.
- Do not force-push or bypass branch protection to unblock a failing CI check.
- Do not change business scope during ship observation.
- Do not commit secrets, real tokens, personal credentials or local-only paths.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/workflow.md`](../references/engineering/tdd-prodops/workflow.md) | TDD evidence standards (what counts as red/green/refactor proof) |
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Delivery gates checklist before creating a PR |
