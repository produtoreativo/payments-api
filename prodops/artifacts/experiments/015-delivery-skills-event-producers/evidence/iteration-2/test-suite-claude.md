# EXP-015 Iteration 2 — Test Suite Results: Claude

Date: 2026-07-28. Tool version: 1.0.0.

## Invocation

```bash
PLAYER=claude bash prodops/runtime/tools/emit-event/tests/run-all.sh
```

## Results

```
prodops_emit_event — Test Suite
player=claude  shared-corr-id=<generated per run>
────────────────────────────────────────────────
✓ PASS: 01 valid-input (full pipeline)
✓ PASS: 02 missing-required-fields
✓ PASS: 03 unknown-event
✓ PASS: 04 catalog-field-rejection
✓ PASS: 05 partial-runtime-failure (datadog)
✓ PASS: 06 idempotency (same correlation-id)
────────────────────────────────────────────────
Results: 6 passed, 0 failed
All tests passed.
```

## Test Coverage Summary

| Test | Scenario | Exit Expected | Exit Got | Pass? |
|---|---|---|---|---|
| 01 | Valid input — full 5-step pipeline | 0 | 0 | ✓ |
| 02 | Missing `event`, `work-item-id`, `correlation-id` | 1 | 1 | ✓ |
| 03 | Event `Delivery.NonExistent.Started` not in catalog | 2 | 2 | ✓ |
| 04 | Caller provides `new-state` and `type` (catalog-owned) | 1 | 1 | ✓ |
| 05 | Datadog API key invalid → pipeline continues, `datadog-sync:error` | 0 | 0 | ✓ |
| 06 | Same `correlation-id` re-submitted → `status:skipped` | 4 | 4 | ✓ |

## Evidence Run

See `claude-run.json` for the canonical evidence of the full pipeline execution with `--evidence-file`.

## Instructions for Codex and Copilot

```bash
# Codex
PLAYER=codex bash prodops/runtime/tools/emit-event/tests/run-all.sh

# Copilot
PLAYER=copilot bash prodops/runtime/tools/emit-event/tests/run-all.sh
```

Expected: identical test results (6/6 pass). Differences permitted only in `actor.player`, UUIDs, and timestamps.

After the test suite passes, capture the canonical run:

```bash
CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
EXEC=$(uuidgen | tr '[:upper:]' '[:lower:]')
echo "{
  \"event\": \"Delivery.Bootstrap.Started\",
  \"work-item-id\": \"76\",
  \"iteration-id\": \"EXP-015-I2\",
  \"correlation-id\": \"$CORR\",
  \"execution-id\": \"$EXEC\",
  \"actor\": {\"player\": \"<codex|copilot>\", \"agent\": \"delivery-agent\"},
  \"payload\": {}
}" | bash prodops/runtime/tools/emit-event/scripts/emit-event \
  --evidence-file prodops/artifacts/experiments/015-delivery-skills-event-producers/evidence/iteration-2/<player>-run.json
```
