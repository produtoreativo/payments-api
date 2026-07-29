#!/usr/bin/env bash
# Test 03: unknown event — event not in catalog must exit 2

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"

INPUT=$(jq -n '{
  "event": "Delivery.NonExistent.Started",
  "work-item-id": "76",
  "correlation-id": "test-03-unknown-event",
  "actor": {"player": "claude", "agent": "test-agent"},
  "payload": {}
}')

set +e
OUTPUT=$(echo "$INPUT" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT" | jq -r '.status')
ERROR=$(echo "$OUTPUT"  | jq -r '.errors[0]')

[[ "$EXIT_CODE" == "2"    ]] || { echo "FAIL exit=$EXIT_CODE (expected 2)"; exit 1; }
[[ "$STATUS"    == "error" ]] || { echo "FAIL status=$STATUS (expected error)"; exit 1; }
echo "$ERROR" | grep -q "not in catalog" || { echo "FAIL error does not mention catalog: $ERROR"; exit 1; }
