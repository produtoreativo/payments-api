---
name: prodops-emit-event
description: Emit a ProdOps Delivery lifecycle event via the player-neutral prodops_emit_event tool. Use this capability whenever a Delivery Skill requires recording a Started or Completed lifecycle moment.
tool: prodops/runtime/tools/emit-event/scripts/emit-event
schema-version: "1"
---

# PRODOPS EMIT EVENT

This skill defines how an agent emits a ProdOps lifecycle event. It does not define WHEN to emit — that is the responsibility of the calling Delivery Skill. This skill defines HOW to call the tool, interpret the result, and handle errors.

The agent never constructs a CloudEvent, never calls GitHub, never calls Datadog, and never reads `events.yaml` directly. All of that is handled by the tool.

## Tool location

```
prodops/runtime/tools/emit-event/scripts/emit-event
```

Run from the repository root.

## Invocation

Pipe a JSON object to the tool via stdin, or pass it via `--input <file>`:

```bash
echo '<input-json>' | bash prodops/runtime/tools/emit-event/scripts/emit-event
# or
bash prodops/runtime/tools/emit-event/scripts/emit-event --input <path-to-input.json>
```

For validation without side effects:

```bash
bash prodops/runtime/tools/emit-event/scripts/emit-event --dry-run --input <file>
```

## Input

Provide exactly these fields. Do not add `specversion`, `source`, `type`, `dataschema`, `journey`, `cycle`, `phase`, `alters-state`, or `new-state` — those belong to the event catalog and will be rejected.

```json
{
  "event": "<logical-event-name>",
  "work-item-id": "<github-issue-number>",
  "iteration-id": "<iteration-plan-id>",
  "correlation-id": "<uuid>",
  "execution-id": "<uuid>",
  "actor": {
    "player": "<claude|codex|copilot>",
    "agent": "<agent-name>"
  },
  "payload": {}
}
```

### Field rules

| Field | Required | Rule |
|---|---|---|
| `event` | yes | Logical name from catalog, e.g. `Delivery.Bootstrap.Started` |
| `work-item-id` | yes | GitHub issue number as string |
| `correlation-id` | yes | UUID; same value for Started and Completed of the same phase |
| `actor.player` | yes | Literal: `claude`, `codex`, or `copilot` |
| `actor.agent` | yes | Agent identifier, e.g. `delivery-agent` |
| `iteration-id` | no | Iteration Plan ID for tracing |
| `execution-id` | no | Distinct UUID per tool invocation |
| `payload` | no | Extra key-value pairs; never override catalog fields |

### Correlation ID lifecycle

- Generate one UUID when the Delivery phase begins (before Started).
- Use the **same** UUID for both the Started and Completed events of that phase.
- Never reuse a correlation ID across different phases.

## Output

The tool writes a single JSON object to stdout:

```json
{
  "status": "accepted",
  "event-id": "<uuid>",
  "event-type": "prodops.delivery.bootstrap.started",
  "correlation-id": "<echoed>",
  "derived-state": "BOOTSTRAPPING",
  "github-sync": "success",
  "datadog-sync": "success",
  "cloudevent": null,
  "errors": []
}
```

### Status values

| Status | Exit code | Meaning |
|---|---|---|
| `accepted` | 0 | Event processed; full pipeline complete |
| `skipped` | 4 | Same correlation-id + event-type already in timeline; no side effects |
| `dry-run` | 0 | Validation + CE only; no side effects; `cloudevent` field populated |
| `error` | 1, 2, or 3 | Processing failed; see `errors` array |

### Non-fatal fields

`github-sync` and `datadog-sync` may be `"error"` while `status` is `"accepted"` and exit code is 0. This means the event was persisted to the timeline and derived state was computed, but the external sync encountered a transient failure.

## Error handling

| Exit code | Cause | Agent action |
|---|---|---|
| 0 | Success or idempotent skip | Continue |
| 1 | Invalid input or forbidden field | Fix the input; do not retry with the same payload |
| 2 | Event not in catalog | Verify the event name against `prodops/runtime/catalog/events.yaml` |
| 3 | Pipeline error | Inspect stderr; do not fabricate the missing result |
| 4 | Idempotent skip | No action; the event is already recorded |

If the tool exits 3 (pipeline error), the agent must **not**:
- assume the event was emitted
- fabricate a derived state
- proceed to the next step as if the phase completed

The agent should report the pipeline error and halt.

## Evidence

To capture full run evidence automatically, use `--evidence-file`:

```bash
bash prodops/runtime/tools/emit-event/scripts/emit-event \
  --input input.json \
  --evidence-file prodops/artifacts/experiments/<exp>/evidence/<iter>/<player>-run.json
```

## Conformance rule

For the same `event` + `work-item-id` + `correlation-id`, all players must produce the same `event-type`, `derived-state`, and CloudEvent `data` content. Only `actor.player`, `event-id` (UUID), `time`, and `execution-id` are allowed to differ.
