#!/usr/bin/env bash
# Test 06: idempotency — re-submit with same correlation-id as test 01 must exit 4

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"

CORR="${TEST_CORR_ID:-}"
if [[ -z "$CORR" ]]; then
  echo "SKIP: TEST_CORR_ID not set — run via run-all.sh for coordinated idempotency test"
  exit 0
fi

# iteration-id must match test 01 so both use the same iteration-scoped timeline directory
INPUT=$(jq -n \
  --arg player "$PLAYER" \
  --arg corr   "$CORR" \
  '{"event":"Delivery.Bootstrap.Started","work-item-id":"76","iteration-id":"EXP-015-I2",
    "correlation-id":$corr,
    "actor":{"player":$player,"agent":"delivery-agent"},"payload":{}}')

set +e
OUTPUT=$(echo "$INPUT" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT" | jq -r '.status')
GH=$(echo "$OUTPUT"     | jq -r '."github-sync"')
DD=$(echo "$OUTPUT"     | jq -r '."datadog-sync"')
ERRORS=$(echo "$OUTPUT" | jq -r '.errors | length')

[[ "$EXIT_CODE" == "4"      ]] || { echo "FAIL exit=$EXIT_CODE (expected 4)"; exit 1; }
[[ "$STATUS"    == "skipped" ]] || { echo "FAIL status=$STATUS (expected skipped)"; exit 1; }
[[ "$GH"        == "skipped" ]] || { echo "FAIL github-sync=$GH (expected skipped)"; exit 1; }
[[ "$DD"        == "skipped" ]] || { echo "FAIL datadog-sync=$DD (expected skipped)"; exit 1; }
[[ "$ERRORS"    == "0"       ]] || { echo "FAIL errors array not empty"; exit 1; }
