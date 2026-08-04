#!/usr/bin/env bash
# Test 08: Bootstrap intermediate events flow through the pipeline without drops
#
# BDD: Scenario "Todos os eventos de Bootstrap chegam ao Datadog"
#   Emits Dependencies.Installed, Services.Ready, Smoke.Passed and verifies
#   each is accepted by the pipeline (exit 0, status accepted, no errors).
#   Relies on a Bootstrap.Started emitted first to anchor the derived state.

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"
CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
EXEC=$(uuidgen | tr '[:upper:]' '[:lower:]')
ITERATION="v0.12.0-test08"
ISSUE="146"

emit_event() {
  local event="$1"
  local extra_corr="${2:-$CORR}"
  jq -n \
    --arg event          "$event" \
    --arg work_item_id   "$ISSUE" \
    --arg iteration_id   "$ITERATION" \
    --arg correlation_id "$extra_corr" \
    --arg execution_id   "$EXEC" \
    --arg player         "$PLAYER" \
    --arg agent          "test-agent-08" \
    '{"event":$event,"work-item-id":$work_item_id,"iteration-id":$iteration_id,
      "correlation-id":$correlation_id,"execution-id":$execution_id,
      "actor":{"player":$player,"agent":$agent},"payload":{}}'
}

# Step 1: Bootstrap.Started — anchors state to BOOTSTRAPPING
CORR_START=$(uuidgen | tr '[:upper:]' '[:lower:]')
set +e
OUT=$(emit_event "Delivery.Bootstrap.Started" "$CORR_START" | GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" 2>/dev/null)
EXIT=$?
set -e
[[ "$EXIT" == "0" ]] || { echo "FAIL: Bootstrap.Started exit=$EXIT"; exit 1; }
[[ "$(echo "$OUT" | jq -r '.status')" == "accepted" ]] || { echo "FAIL: Bootstrap.Started not accepted"; exit 1; }

# Step 2: Each intermediate event — must be accepted, no errors
for EVT in \
  "Delivery.Bootstrap.Dependencies.Installed" \
  "Delivery.Bootstrap.Services.Ready" \
  "Delivery.Bootstrap.Smoke.Passed"; do

  CORR_EVT=$(uuidgen | tr '[:upper:]' '[:lower:]')
  set +e
  OUT=$(emit_event "$EVT" "$CORR_EVT" | GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" 2>/dev/null)
  EXIT=$?
  set -e

  STATUS=$(echo "$OUT" | jq -r '.status')
  ERRORS=$(echo "$OUT" | jq -r '.errors | length')

  [[ "$EXIT"   == "0"        ]] || { echo "FAIL: $EVT exit=$EXIT (expected 0)"; exit 1; }
  [[ "$STATUS" == "accepted" ]] || { echo "FAIL: $EVT status=$STATUS (expected accepted)"; exit 1; }
  [[ "$ERRORS" == "0"        ]] || { echo "FAIL: $EVT errors=$ERRORS (expected 0)"; exit 1; }
done
