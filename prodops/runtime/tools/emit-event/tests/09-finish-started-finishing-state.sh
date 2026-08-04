#!/usr/bin/env bash
# Test 09: Delivery.Finish.Started → oem-state FINISHING
#
# BDD: Scenario "oem-state FINISHING transitado ao emitir Finish.Started"
#   Verifies that emitting Delivery.Finish.Started results in derived-state=FINISHING
#   and that emit-event does NOT return "skipped" for github-sync.

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"
ITERATION="v0.12.0-test09"
ISSUE="146"

emit_event() {
  local event="$1"
  local corr="$2"
  jq -n \
    --arg event          "$event" \
    --arg work_item_id   "$ISSUE" \
    --arg iteration_id   "$ITERATION" \
    --arg correlation_id "$corr" \
    --arg execution_id   "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
    --arg player         "$PLAYER" \
    --arg agent          "test-agent-09" \
    '{"event":$event,"work-item-id":$work_item_id,"iteration-id":$iteration_id,
      "correlation-id":$correlation_id,"execution-id":$execution_id,
      "actor":{"player":$player,"agent":$agent},"payload":{}}'
}

# Anchor with Bootstrap.Started → BOOTSTRAPPING, then Hack.Started → HACKING
for EVT in "Delivery.Bootstrap.Started" "Delivery.Hack.Started"; do
  CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
  set +e
  OUT=$(emit_event "$EVT" "$CORR" | bash "$TOOL" 2>/dev/null)
  EXIT=$?
  set -e
  [[ "$EXIT" == "0" ]] || { echo "FAIL: $EVT exit=$EXIT"; exit 1; }
done

# Now emit Finish.Started — must derive FINISHING
CORR_FINISH=$(uuidgen | tr '[:upper:]' '[:lower:]')
set +e
OUTPUT=$(emit_event "Delivery.Finish.Started" "$CORR_FINISH" | bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT"        | jq -r '.status')
DERIVED=$(echo "$OUTPUT"       | jq -r '."derived-state"')
GH=$(echo "$OUTPUT"            | jq -r '."github-sync"')
ERRORS=$(echo "$OUTPUT"        | jq -r '.errors | length')

[[ "$EXIT_CODE" == "0"        ]] || { echo "FAIL exit=$EXIT_CODE (expected 0)"; exit 1; }
[[ "$STATUS"    == "accepted"  ]] || { echo "FAIL status=$STATUS (expected accepted)"; exit 1; }
[[ "$DERIVED"   == "FINISHING" ]] || { echo "FAIL derived-state=$DERIVED (expected FINISHING)"; exit 1; }
[[ "$GH"        != "skipped"   ]] || { echo "FAIL github-sync=skipped (must not be skipped)"; exit 1; }
[[ "$ERRORS"    == "0"         ]] || { echo "FAIL errors=$ERRORS (expected 0)"; exit 1; }
