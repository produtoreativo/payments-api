# EXP-015 Iteration 1 — `prodops_emit_event` Contract

## Tool Identity

| Field | Value |
|---|---|
| Name | `prodops_emit_event` |
| Spike path | `prodops/runtime/tools/emit-event/emit-event.sh` |
| Runtime version | 0.3.0 |
| Contract version | 1.0.0-spike |
| Date | 2026-07-28 |
| MCP | Not used (Iteration 1 scope) |

## Architecture Position

```
Canonical Delivery Skill
        ↓ semantic instruction ("emit Delivery.Bootstrap.Started")
Agent (Claude | Codex | Copilot)
        ↓ player-specific tool invocation
prodops_emit_event  ←  THIS CONTRACT
        ↓ CloudEvent 1.0
Runtime pipeline:
  1. producer/emit.sh        — constructs CloudEvent from catalog
  2. timeline/append.sh      — persists to issue timeline (append-only)
  3. consumer/derive-state.sh — computes current state from timeline
  4. datadog/send.sh         — emits runtime.event.received metric
  5. github/sync.sh          — updates oem-state + oem-last-event in Project
```

## Input Contract

Schema: `prodops/runtime/tools/emit-event/input.schema.json`

### Required fields

| Field | Type | Description |
|---|---|---|
| `event` | string | Logical event name from catalog (e.g. `Delivery.Bootstrap.Started`) |
| `work-item-id` | string (numeric) | GitHub issue number of the Feature |
| `correlation-id` | string (UUID) | Caller-generated; groups related events; used for idempotency |
| `actor.player` | enum | `claude`, `codex`, or `copilot` |
| `actor.agent` | string | Agent name within the player |

### Optional fields

| Field | Type | Description |
|---|---|---|
| `iteration-id` | string | Iteration Plan identifier (logged only, not forwarded) |
| `execution-id` | string (UUID) | Player-session execution identifier (logged only) |
| `payload` | object | Extra data to include in CloudEvent data block |

### Fields the agent MUST NOT provide

```
specversion, source, type, dataschema,
journey, cycle, phase, alters-state, new-state
```

These are resolved from the catalog by the tool.

## Output Contract

Schema: `prodops/runtime/tools/emit-event/output.schema.json`

### Success (status: accepted)

```json
{
  "status": "accepted",
  "event-id": "<uuid>",
  "event-type": "prodops.delivery.bootstrap.started",
  "correlation-id": "<input correlation-id>",
  "derived-state": "BOOTSTRAPPING",
  "github-sync": "success",
  "datadog-sync": "success",
  "errors": []
}
```

### Idempotent skip (status: skipped, exit 4)

Same `correlation-id` + `event-type` already in timeline. No side effects.

```json
{
  "status": "skipped",
  "event-id": "<original event-id>",
  "event-type": "prodops.delivery.bootstrap.started",
  "correlation-id": "<input correlation-id>",
  "derived-state": "BOOTSTRAPPING",
  "github-sync": "skipped",
  "datadog-sync": "skipped",
  "errors": []
}
```

### Error (status: error)

```json
{
  "status": "error",
  "event-id": null,
  "event-type": null,
  "correlation-id": null,
  "derived-state": null,
  "github-sync": "skipped",
  "datadog-sync": "skipped",
  "errors": ["<message>"]
}
```

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Accepted — pipeline complete |
| 1 | Invalid input — missing required fields |
| 2 | Unknown event — not in catalog |
| 3 | Pipeline error — a runtime step failed |
| 4 | Idempotent skip — already processed |

## Idempotency Rule

The tool checks the issue's timeline file for an existing entry where:
- `data.runtime-correlation-id == input["correlation-id"]`
- `type == catalog["event"]["cloud-event-type"]`

If found: returns `status: skipped`, exit 4, no side effects.

## Logging Contract

- **stderr**: tool-level diagnostic messages (`[prodops_emit_event] ...`)
- **stdout**: JSON output only (single object, no surrounding text)
- **Secret sanitization**: `DD_API_KEY` is never logged; GitHub token is never logged

## Conformance Rule

For the same `event` + `work-item-id` + `correlation-id`, all players must produce:
- Same `event-type`
- Same `derived-state`
- Same CloudEvent `data` structure (excluding `id`, `time`)
- Same `github-sync` result

Allowed to differ: `actor.player`, `execution-id`, `event-id` (UUID), `time`.

## Player Test Instructions

### Prerequisites

1. Clone/checkout `experiment/015-delivery-skills-event-producers`
2. Ensure `DD_API_KEY` and `GH_TOKEN` are set (or present in `api/.env` / `gh` CLI login)
3. `jq`, `python3`, `python3 -m yaml` must be available

### Invocation

```bash
# Generate UUIDs for your player
CORR_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
EXEC_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Write input file
cat > /tmp/<player>-emit-input.json <<EOF
{
  "event": "Delivery.Bootstrap.Started",
  "work-item-id": "76",
  "iteration-id": "EXP-015-I1",
  "correlation-id": "$CORR_ID",
  "execution-id": "$EXEC_ID",
  "actor": {
    "player": "<claude|codex|copilot>",
    "agent": "delivery-agent"
  },
  "payload": {}
}
EOF

# Run from repo root
cd <repo-root>
bash prodops/runtime/tools/emit-event/emit-event.sh \
  --input /tmp/<player>-emit-input.json
```

### Expected output

- Exit code: 0
- stdout: JSON with `status: accepted`, all five pipeline steps succeeded
- Timeline entry: new event in `prodops/artifacts/runtime/timelines/76.json`
- GitHub Project: `oem-state = BOOTSTRAPPING`, `oem-last-event = prodops.delivery.bootstrap.started`

### Evidence capture

After running, update `evidence/iteration-1/<player>-run.json`:

1. Replace `input` with the actual input JSON used
2. Replace `output` with the actual stdout JSON
3. Read the CloudEvent from timeline: `jq --arg cid "$CORR_ID" '.[] | select(.data["runtime-correlation-id"] == $cid)' prodops/artifacts/runtime/timelines/76.json`
4. Replace `cloudevent` with the timeline entry
5. Read derived state: `cat prodops/artifacts/runtime/derived-state-76.json`
6. Replace `derived-state` with the derived state JSON
7. Fill `pipeline-steps` with actual success/error per step
8. Run the same command again with the same input to verify idempotency (expect exit 4, status: skipped)
9. Fill `idempotency-check` with the result
