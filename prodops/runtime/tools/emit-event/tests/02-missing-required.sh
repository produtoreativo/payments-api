#!/usr/bin/env bash
# Test 02: missing required fields — must exit 1 with descriptive errors

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"

INPUT='{"actor":{"player":"claude","agent":"delivery-agent"},"payload":{}}'

set +e
OUTPUT=$(echo "$INPUT" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT" | jq -r '.status')
ERRORS=$(echo "$OUTPUT" | jq -r '[.errors[]] | join(" | ")')

[[ "$EXIT_CODE" == "1"    ]] || { echo "FAIL exit=$EXIT_CODE (expected 1)"; exit 1; }
[[ "$STATUS"    == "error" ]] || { echo "FAIL status=$STATUS (expected error)"; exit 1; }

echo "$ERRORS" | grep -q "missing required field: event"          || { echo "FAIL: 'event' error not reported; errors=$ERRORS"; exit 1; }
echo "$ERRORS" | grep -q "missing required field: work-item-id"   || { echo "FAIL: 'work-item-id' error not reported"; exit 1; }
echo "$ERRORS" | grep -q "missing required field: correlation-id" || { echo "FAIL: 'correlation-id' error not reported"; exit 1; }
