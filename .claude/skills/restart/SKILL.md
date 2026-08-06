---
name: restart
description: Non-destructive restart of a Delivery Journey. Preserves the existing timeline, assigns a new correlation-id, and emits Restart.Requested → Restart.Started → Restart.Completed. Use when a feature needs to re-run Bootstrap from scratch without losing audit history.
---
<!-- MATERIALIZED FILE — DO NOT EDIT MANUALLY
     Source:    prodops/skills/restart/SKILL.md
     Player:    claude
     Generator: prodops/scripts/agents/materialize-skills.sh
     Generated: 2026-08-06T13:38:35Z
     To update: bash prodops/scripts/agents/materialize-skills.sh --skill restart
-->

# RESTART

Use this skill when a Feature's Delivery Journey is stuck or needs to re-run from Bootstrap, but the existing timeline and audit history must be preserved.

Restart is **non-destructive**: all previous events remain in the timeline. A new `correlation-id` is assigned. The feature re-enters the CI Sync flow from Bootstrap using the new correlation-id.

## When to use

| Situation | Use Restart? |
|---|---|
| Feature is BLOCKED and cannot recover with Block.Resolved | ✅ Yes |
| Bootstrap completed but environment was corrupted | ✅ Yes |
| Wrong branch or scope was used — work must restart | ✅ Yes |
| Simple blocker resolved (external dependency unblocked) | ❌ No — use Block.Resolved instead |
| Agent interrupted mid-phase without state change | ❌ No — resume from current state |

**Prefer Block.Resolved over Restart** when the blocker can be resolved without re-running Bootstrap. Restart is the last resort when the current execution context cannot be recovered.

## Required input context

Before starting, the agent must have:

- `work-item-id` — the GitHub issue number of the Feature
- `iteration-id` — the Iteration Plan identifier
- `reason` — why the restart is necessary (recorded in the restart artifact)
- `actor.player` — the current player (`claude`, `codex`, or `copilot`)
- `correlation-id` — the current (soon-to-be previous) correlation-id

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.
3. The restart tool is available at `prodops/runtime/tools/restart-feature/scripts/restart-feature`.
4. A timeline exists for the issue at `prodops/artifacts/runtime/timelines/<work-item-id>.json`.

## Phase: Restart.Requested + Restart.Started

**Moment**: before any Bootstrap work begins. Invoke the restart-feature tool — it emits both events atomically and returns a new `correlation-id`.

```bash
prodops/runtime/tools/restart-feature/scripts/restart-feature \
  --work-item-id "<work-item-id>" \
  --reason "<reason>" \
  --scope "full" \
  --player "<player>"
```

The tool emits:
1. `Delivery.Restart.Requested` — records intent to restart with the previous `correlation-id`
2. `Delivery.Restart.Started` — records the new `correlation-id` as the active one

Capture the output:
```json
{
  "status": "accepted",
  "restart-id": "RST-<issue>-<uuid>",
  "new-correlation-id": "<new-uuid>",
  "previous-correlation-id": "<previous-uuid>"
}
```

If the tool returns `status: error`: report the error to the caller and do not proceed.

If the tool returns `status: skipped` (exit 4): a restart with the same context was already recorded — use the existing `new-correlation-id` and continue.

## Phase: Restart.Completed

**Moment**: after Bootstrap.Completed is successfully emitted with the new `correlation-id`. This marks that the restart is fully initialized and the new execution has begun.

Emit using the **new `correlation-id`** from the restart-feature output:

```json
{
  "event": "Delivery.Restart.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<new-correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "restart-agent" },
  "payload": {
    "previous-correlation-id": "<previous-uuid>",
    "restart-id": "<RST-id>",
    "reason": "<reason>"
  }
}
```

Do not emit `Restart.Completed` before Bootstrap.Completed is accepted.

## Flow

1. Invoke `restart-feature` tool — emits Restart.Requested + Restart.Started, returns `new-correlation-id`.
2. Use the `new-correlation-id` for all subsequent events in this execution.
3. Execute the full Bootstrap flow (`/bootstrap`) using the new `correlation-id`.
4. After Bootstrap.Completed is accepted: emit `Restart.Completed`.
5. Continue with `/hack` using the new `correlation-id`.

## Post-conditions

- The timeline contains Restart.Requested, Restart.Started, Bootstrap.Started, Bootstrap.Completed, Restart.Completed in this sequence.
- A restart artifact exists at `prodops/artifacts/runtime/restarts/<issue>/RST-<issue>-<uuid>.json`.
- The new `correlation-id` is the active one for all subsequent CI Sync and CI Async events.
- The previous `correlation-id` is recorded in the restart artifact and in the Restart.Requested event payload.

## Guardrails

- Do not delete or modify existing timeline events — the timeline is append-only.
- Do not reuse the previous `correlation-id` after restart — all new events must use the new one.
- Do not emit `Restart.Completed` before `Bootstrap.Completed` is confirmed.
- Do not restart if `Block.Resolved` is sufficient — prefer the lighter-weight recovery path.
- Do not invoke restart more than once per execution without a new `reason` — idempotency exit (4) will occur.
