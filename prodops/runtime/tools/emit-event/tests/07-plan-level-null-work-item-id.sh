#!/usr/bin/env bash
# Test 07: plan-level events — work-item-id null falls back to iteration-id
# Guards against Plan.Bootstrap.* arriving at Datadog as issue:null.

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"
CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
EXEC=$(uuidgen | tr '[:upper:]' '[:lower:]')
ITERATION="v0.11.0"

# Case A: work-item-id is JSON null
INPUT_NULL=$(jq -n \
  --arg event          "Delivery.Plan.Bootstrap.Started" \
  --arg iteration_id   "$ITERATION" \
  --arg correlation_id "$CORR" \
  --arg execution_id   "$EXEC" \
  --arg player         "$PLAYER" \
  --arg agent          "downstream-agent" \
  '{"event":$event,"work-item-id":null,"iteration-id":$iteration_id,
    "correlation-id":$correlation_id,"execution-id":$execution_id,
    "actor":{"player":$player,"agent":$agent},"payload":{}}')

set +e
OUTPUT=$(echo "$INPUT_NULL" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

[[ "$EXIT_CODE" == "0" ]] || { echo "FAIL (null case) exit=$EXIT_CODE (expected 0); output=$OUTPUT"; exit 1; }

STATUS=$(echo "$OUTPUT" | jq -r '.status')
[[ "$STATUS" == "accepted" ]] || { echo "FAIL (null case) status=$STATUS (expected accepted)"; exit 1; }

# Case B: work-item-id is the string "null" (agent serialization error)
CORR2=$(uuidgen | tr '[:upper:]' '[:lower:]')
INPUT_STR=$(jq -n \
  --arg event          "Delivery.Plan.Bootstrap.Completed" \
  --arg work_item_id   "null" \
  --arg iteration_id   "$ITERATION" \
  --arg correlation_id "$CORR2" \
  --arg execution_id   "$EXEC" \
  --arg player         "$PLAYER" \
  --arg agent          "downstream-agent" \
  '{"event":$event,"work-item-id":$work_item_id,"iteration-id":$iteration_id,
    "correlation-id":$correlation_id,"execution-id":$execution_id,
    "actor":{"player":$player,"agent":$agent},"payload":{}}')

set +e
OUTPUT2=$(echo "$INPUT_STR" | bash "$TOOL" 2>/dev/null)
EXIT_CODE2=$?
set -e

[[ "$EXIT_CODE2" == "0" ]] || { echo "FAIL (string-null case) exit=$EXIT_CODE2 (expected 0); output=$OUTPUT2"; exit 1; }

STATUS2=$(echo "$OUTPUT2" | jq -r '.status')
[[ "$STATUS2" == "accepted" ]] || { echo "FAIL (string-null case) status=$STATUS2 (expected accepted)"; exit 1; }

echo "PASS: plan-level null work-item-id falls back to iteration-id (both null and string-null cases)"
