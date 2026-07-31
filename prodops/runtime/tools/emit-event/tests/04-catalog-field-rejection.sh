#!/usr/bin/env bash
# Test 04: caller provides catalog-owned fields — must be rejected with exit 1

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"

INPUT=$(jq -n '{
  "event": "Delivery.Bootstrap.Started",
  "work-item-id": "76",
  "correlation-id": "test-04-catalog-reject",
  "new-state": "CUSTOM_STATE",
  "type": "prodops.fake.event",
  "actor": {"player": "claude", "agent": "test-agent"},
  "payload": {}
}')

set +e
OUTPUT=$(echo "$INPUT" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT" | jq -r '.status')
ERROR=$(echo "$OUTPUT"  | jq -r '.errors[0]')

[[ "$EXIT_CODE" == "1"    ]] || { echo "FAIL exit=$EXIT_CODE (expected 1)"; exit 1; }
[[ "$STATUS"    == "error" ]] || { echo "FAIL status=$STATUS (expected error)"; exit 1; }
echo "$ERROR" | grep -q "forbidden fields" || { echo "FAIL error does not mention forbidden fields: $ERROR"; exit 1; }
echo "$ERROR" | grep -q "new-state"        || { echo "FAIL error does not name new-state: $ERROR"; exit 1; }
