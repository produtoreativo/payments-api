#!/usr/bin/env bash
# bootstrap-happy-path.sh — EXP-013 Iteration 4: Delivery Happy Path
# Runs all 15 events of the Delivery Happy Path for the pilot issue.
# Flow per event: Emit CloudEvent → Timeline → Derived State → Datadog
# GitHub sync only after state-altering events.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"
CATALOG="$RUNTIME_DIR/catalog/events.yaml"

yaml_get() {
  python3 - "$CONFIG" "$1" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
keys = sys.argv[2].split('.')
val = data
for k in keys:
    val = val[k]
print(val)
PYEOF
}

catalog_get() {
  python3 - "$CATALOG" "$1" "$2" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
event, field = sys.argv[2], sys.argv[3]
val = data['events'][event].get(field, '')
if isinstance(val, bool):
    print('true' if val else 'false')
else:
    print(val)
PYEOF
}

RUNTIME_VERSION=$(yaml_get "runtime-version")
PILOT_ISSUE=$(yaml_get "github.pilot-issue")
GH_OWNER=$(yaml_get "github.owner")
GH_REPO=$(yaml_get "github.repository")
GH_PROJECT=$(yaml_get "github.project-number")

ARTIFACTS_DIR="$PRODOPS_DIR/artifacts/runtime"
LOG_FILE="$ARTIFACTS_DIR/runtime.log"

mkdir -p "$ARTIFACTS_DIR/timelines"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

echo ""
echo "┌──────────────────────────────────────────────────────┐"
echo "│  EXP-013 — Iteration 4: Delivery Happy Path          │"
echo "│  runtime-version: ${RUNTIME_VERSION}                          │"
echo "│  Pilot issue: #${PILOT_ISSUE} (FTR-001: Invoice PIX)         │"
echo "│  Events: 15 │ Journey: Delivery → DONE               │"
echo "└──────────────────────────────────────────────────────┘"
echo ""

log "=== bootstrap-happy-path.sh v${RUNTIME_VERSION} started ==="
log "Pilot issue: #${PILOT_ISSUE} | Repo: ${GH_OWNER}/${GH_REPO} | Project: #${GH_PROJECT}"

# ── Doctor ──────────────────────────────────────────────────────────────────
echo "Running Runtime Doctor..."
if ! bash "$SCRIPT_DIR/runtime-doctor.sh"; then
  echo ""
  echo "  Doctor reported FAIL. Aborting happy path."
  exit 1
fi

CORRELATION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
log "Correlation ID: $CORRELATION_ID"
echo "Correlation ID: $CORRELATION_ID"
echo ""

# ── Happy Path Event Sequence ────────────────────────────────────────────────
EVENTS=(
  "Delivery.Bootstrap.Started"
  "Delivery.Bootstrap.Completed"
  "Delivery.Hack.Started"
  "Delivery.Hack.Completed"
  "Delivery.Sync.Started"
  "Delivery.Sync.Completed"
  "Delivery.Finish.Started"
  "Delivery.Finish.Completed"
  "Delivery.Ship.Started"
  "Delivery.Ship.Completed"
  "Delivery.Validate.Started"
  "Shared.Gate.Passed"
  "Delivery.Validate.Completed"
  "Delivery.Promote.Started"
  "Delivery.Promote.Completed"
)

TOTAL=${#EVENTS[@]}
STEP=0
PREV_STATE=""

for EVENT in "${EVENTS[@]}"; do
  ((STEP++)) || true

  ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")
  CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")

  echo "── Event ${STEP}/${TOTAL}: ${EVENT}"

  # Step A: Emit CloudEvent
  CE_JSON=$(bash "$RUNTIME_DIR/producer/emit.sh" \
    --issue          "$PILOT_ISSUE" \
    --event          "$EVENT" \
    --correlation-id "$CORRELATION_ID")

  log "Emitted: $CE_TYPE | id=$(echo "$CE_JSON" | jq -r '.id')"

  # Step B: Persist in Timeline
  TIMELINE_FILE=$(bash "$RUNTIME_DIR/timeline/append.sh" \
    --issue      "$PILOT_ISSUE" \
    --event-json "$CE_JSON")

  EVENT_COUNT=$(jq 'length' "$TIMELINE_FILE")

  # Step C: Derive State
  DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" \
    --issue "$PILOT_ISSUE")

  CURRENT_STATE=$(echo "$DERIVED" | jq -r '.state')
  LAST_EVENT_TYPE=$(echo "$DERIVED" | jq -r '.["last-event-type"]')

  # Step D: Send to Datadog
  bash "$RUNTIME_DIR/datadog/send.sh" \
    --issue          "$PILOT_ISSUE" \
    --event          "$CE_TYPE" \
    --state          "$CURRENT_STATE" \
    --correlation-id "$CORRELATION_ID" >> "$LOG_FILE" 2>&1

  # Step E: Sync GitHub (only when state changes)
  if [[ "$ALTERS_STATE" == "true" ]]; then
    bash "$RUNTIME_DIR/github/sync.sh" \
      --issue          "$PILOT_ISSUE" \
      --state          "$CURRENT_STATE" \
      --last-event     "$LAST_EVENT_TYPE" \
      --correlation-id "$CORRELATION_ID" >> "$LOG_FILE" 2>&1
    STATE_INDICATOR=" → ${CURRENT_STATE}"
  else
    STATE_INDICATOR=" (state: ${CURRENT_STATE})"
  fi

  if [[ "$CURRENT_STATE" != "$PREV_STATE" && "$ALTERS_STATE" == "true" ]]; then
    echo "   ✓ CloudEvent:   $CE_TYPE"
    echo "   ✓ State change: ${PREV_STATE:-—} → ${CURRENT_STATE}"
    echo "   ✓ Timeline:     $EVENT_COUNT event(s)"
    echo "   ✓ GitHub:       oem-state=$CURRENT_STATE"
    echo "   ✓ Datadog:      metric sent"
  else
    echo "   ✓ CloudEvent:   $CE_TYPE${STATE_INDICATOR}"
    echo "   ✓ Timeline:     $EVENT_COUNT event(s)"
    echo "   ✓ Datadog:      metric sent"
  fi

  PREV_STATE="$CURRENT_STATE"
  echo ""
done

# ── Final Derived State ───────────────────────────────────────────────────────
FINAL_DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" --issue "$PILOT_ISSUE")
FINAL_STATE=$(echo "$FINAL_DERIVED" | jq -r '.state')
FINAL_EVENT_TYPE=$(echo "$FINAL_DERIVED" | jq -r '.["last-event-type"]')
FINAL_EVENT_COUNT=$(jq 'length' "$TIMELINE_FILE")

# ── Summary ───────────────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════"
echo ""
echo "  Delivery Happy Path — COMPLETE"
echo ""
echo "  Issue:              #${PILOT_ISSUE} — FTR-001: Invoice PIX — Happy Path Completo"
echo "  Final state:        ${FINAL_STATE}"
echo "  Last event type:    ${FINAL_EVENT_TYPE}"
echo "  Total events:       ${FINAL_EVENT_COUNT}"
echo "  Correlation ID:     $CORRELATION_ID"
echo "  Timeline:           $TIMELINE_FILE"
echo "  Derived state:      $ARTIFACTS_DIR/derived-state.json"
echo "  Project:            https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}"
echo "  Datadog metric:     runtime.event.received | issue:${PILOT_ISSUE}"
echo ""
echo "════════════════════════════════════════════════"
echo ""

log "=== bootstrap-happy-path.sh v${RUNTIME_VERSION} complete | correlation-id: $CORRELATION_ID | final-state: $FINAL_STATE | events: $FINAL_EVENT_COUNT ==="
