#!/usr/bin/env bash
# Test 01: valid input — full pipeline run
# Uses TEST_CORR_ID (shared with test 06 for idempotency verification).

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"
CORR="${TEST_CORR_ID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
EXEC=$(uuidgen | tr '[:upper:]' '[:lower:]')

INPUT=$(jq -n \
  --arg event         "Delivery.Bootstrap.Started" \
  --arg work_item_id  "76" \
  --arg iteration_id  "EXP-015-I2" \
  --arg correlation_id "$CORR" \
  --arg execution_id  "$EXEC" \
  --arg player        "$PLAYER" \
  --arg agent         "delivery-agent" \
  '{"event":$event,"work-item-id":$work_item_id,"iteration-id":$iteration_id,
    "correlation-id":$correlation_id,"execution-id":$execution_id,
    "actor":{"player":$player,"agent":$agent},"payload":{}}')

set +e
OUTPUT=$(echo "$INPUT" | GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT"     | jq -r '.status')
EVENT_TYPE=$(echo "$OUTPUT" | jq -r '."event-type"')
DERIVED=$(echo "$OUTPUT"    | jq -r '."derived-state"')
GH=$(echo "$OUTPUT"         | jq -r '."github-sync"')
DD=$(echo "$OUTPUT"         | jq -r '."datadog-sync"')
ERRORS=$(echo "$OUTPUT"     | jq -r '.errors | length')

[[ "$EXIT_CODE"  == "0"                                  ]] || { echo "FAIL exit=$EXIT_CODE (expected 0)"; exit 1; }
[[ "$STATUS"     == "accepted"                           ]] || { echo "FAIL status=$STATUS (expected accepted)"; exit 1; }
[[ "$EVENT_TYPE" == "prodops.delivery.bootstrap.started" ]] || { echo "FAIL event-type=$EVENT_TYPE"; exit 1; }
[[ "$DERIVED"    == "BOOTSTRAPPING"                      ]] || { echo "FAIL derived-state=$DERIVED (expected BOOTSTRAPPING)"; exit 1; }
[[ "$GH"         == "success"                            ]] || { echo "FAIL github-sync=$GH (expected success)"; exit 1; }
[[ "$DD"         == "success"                            ]] || { echo "FAIL datadog-sync=$DD (expected success)"; exit 1; }
[[ "$ERRORS"     == "0"                                  ]] || { echo "FAIL errors not empty"; exit 1; }
