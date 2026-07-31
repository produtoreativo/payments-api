# prodops_emit_event

Player-neutral Delivery event emission tool for the ProdOps Runtime.

## Summary

A single bash CLI that any agent (Claude, Codex, Copilot) can call with the same input and receive the same output. The tool encapsulates the full 5-step Runtime pipeline behind a JSON-in / JSON-out interface.

## Structure

```
emit-event/
├── README.md                  this file
├── contract/
│   ├── input.schema.json      JSON Schema for the tool input
│   └── output.schema.json     JSON Schema for the tool output
├── scripts/
│   └── emit-event             canonical executable (no .sh extension)
├── tests/
│   ├── run-all.sh             test runner
│   ├── 01-valid-input.sh      full pipeline — exit 0
│   ├── 02-missing-required.sh missing required fields — exit 1
│   ├── 03-unknown-event.sh    event not in catalog — exit 2
│   ├── 04-catalog-field-rejection.sh  caller provides catalog-owned fields — exit 1
│   ├── 05-partial-runtime-failure.sh  Datadog fails, pipeline continues — exit 0
│   └── 06-idempotency.sh      same correlation-id → skip — exit 4
├── examples/
│   └── bootstrap-started.json example input for Delivery.Bootstrap.Started
└── emit-event.sh              spike from Iteration 1 (historical reference)
```

## Usage

```bash
# From a file
bash scripts/emit-event --input examples/bootstrap-started.json

# From stdin
echo '{"event":"Delivery.Bootstrap.Started", ...}' | bash scripts/emit-event

# Dry run — validate + construct CE, no side effects
bash scripts/emit-event --input examples/bootstrap-started.json --dry-run

# With automatic evidence capture
bash scripts/emit-event --input input.json --evidence-file /path/to/run.json
```

## Input

Required fields:

| Field | Type | Description |
|---|---|---|
| `event` | string | Logical name from `events.yaml` (e.g. `Delivery.Bootstrap.Started`) |
| `work-item-id` | string | GitHub issue number of the Feature |
| `correlation-id` | UUID string | Caller-generated; used for idempotency |
| `actor.player` | `claude\|codex\|copilot` | The AI player |
| `actor.agent` | string | Agent name |

Optional: `iteration-id`, `execution-id`, `payload`.

**Forbidden**: `specversion`, `source`, `type`, `dataschema`, `journey`, `cycle`, `phase`, `alters-state`, `new-state` — these are catalog-owned. The tool rejects inputs that include them (exit 1).

## Output

All responses are a single JSON object on stdout:

```json
{
  "status": "accepted",
  "event-id": "<uuid>",
  "event-type": "prodops.delivery.bootstrap.started",
  "correlation-id": "<input correlation-id>",
  "derived-state": "BOOTSTRAPPING",
  "github-sync": "success",
  "datadog-sync": "success",
  "cloudevent": null,
  "errors": []
}
```

`status` values: `accepted`, `skipped`, `dry-run`, `error`.

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Accepted (or dry-run) |
| 1 | Invalid input (missing fields, forbidden fields) |
| 2 | Unknown event (not in catalog) |
| 3 | Pipeline error (fatal step failed) |
| 4 | Idempotent skip (already processed) |

## Pipeline

```
scripts/emit-event
  ↓ 1. producer/emit.sh        constructs CloudEvent 1.0 from catalog
  ↓ 2. timeline/append.sh      persists to prodops/artifacts/runtime/timelines/<issue>.json
  ↓ 3. consumer/derive-state.sh computes derived state from full timeline
  ↓ 4. datadog/send.sh         emits runtime.event.received metric (non-fatal)
  ↓ 5. github/sync.sh          updates oem-state + oem-last-event (non-fatal)
```

Steps 4 and 5 are non-fatal: failure sets the corresponding sync field to `"error"` in the output but the tool exits 0.

## Conformance

For the same scenario, Claude, Codex, and Copilot must produce identical:
- `event-type`
- `derived-state`
- CloudEvent `data` structure (excluding `id`, `time`)
- `github-sync` and `datadog-sync` results

Allowed to differ: `actor.player`, `execution-id`, `event-id` (UUID), `time`.

## Running Tests

```bash
# As Claude
PLAYER=claude bash tests/run-all.sh

# As Codex
PLAYER=codex bash tests/run-all.sh

# As Copilot
PLAYER=copilot bash tests/run-all.sh
```

## Prerequisites

- `bash`, `jq`, `python3` with `pyyaml` (`pip3 install pyyaml`)
- `DD_API_KEY` set (or in `api/.env`)
- `gh` CLI authenticated for GitHub Project sync
