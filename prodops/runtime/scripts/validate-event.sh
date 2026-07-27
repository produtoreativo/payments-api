#!/usr/bin/env bash
# CloudEvent Validator — verifies a JSON object conforms to CloudEvents 1.0
# Usage: validate-event.sh --event-json <json>
# Exit 0 = PASS; Exit 1 = FAIL

set -euo pipefail

EVENT_JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-json) EVENT_JSON="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$EVENT_JSON" ]] && { echo "Error: --event-json required" >&2; exit 1; }

FAIL=0

check_field() {
  local field="$1"
  local val
  val=$(echo "$EVENT_JSON" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null)
  if [[ -z "$val" ]]; then
    echo "  [FAIL] missing required field: $field"
    FAIL=1
  fi
}

# Check all required CloudEvents 1.0 fields
for field in specversion id source type subject time datacontenttype dataschema; do
  check_field "$field"
done

# Check data is present and is an object
DATA_TYPE=$(echo "$EVENT_JSON" | jq -r 'if .data then (.data | type) else empty end' 2>/dev/null)
if [[ -z "$DATA_TYPE" ]]; then
  echo "  [FAIL] missing required field: data"
  FAIL=1
elif [[ "$DATA_TYPE" != "object" ]]; then
  echo "  [FAIL] data must be a JSON object, got: $DATA_TYPE"
  FAIL=1
fi

# Check specversion is exactly "1.0"
SPECVERSION=$(echo "$EVENT_JSON" | jq -r '.specversion // empty' 2>/dev/null)
if [[ -n "$SPECVERSION" && "$SPECVERSION" != "1.0" ]]; then
  echo "  [FAIL] specversion must be '1.0', got: '$SPECVERSION'"
  FAIL=1
fi

if (( FAIL == 0 )); then
  echo "  [PASS] CloudEvent is valid (specversion=1.0 type=$(echo "$EVENT_JSON" | jq -r '.type'))"
  exit 0
else
  echo "  [FAIL] CloudEvent validation failed"
  exit 1
fi
