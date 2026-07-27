#!/usr/bin/env bash
# bootstrap-multi-feature.sh — EXP-013 Iteration 5: Multi-Feature Runtime Validation
# Runs the Delivery Happy Path for three Features in interleaved fashion.
# Each Feature has its own correlation-id and timeline.
# Demonstrates independent Timeline, Derived State, GitHub, and Datadog per Feature.

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
GH_OWNER=$(yaml_get "github.owner")
GH_REPO=$(yaml_get "github.repository")
GH_PROJECT=$(yaml_get "github.project-number")

ARTIFACTS_DIR="$PRODOPS_DIR/artifacts/runtime"
LOG_FILE="$ARTIFACTS_DIR/runtime.log"

mkdir -p "$ARTIFACTS_DIR/timelines"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

# ── Features ────────────────────────────────────────────────────────────────
ISSUES=(76 77 78)
FEATURE_NAMES=("FTR-001: Invoice PIX" "FTR-002: Invoice Cartão" "FTR-003: Confirmação Pagamento")

echo ""
echo "┌────────────────────────────────────────────────────────────┐"
echo "│  EXP-013 — Iteration 5: Multi-Feature Runtime Validation   │"
echo "│  runtime-version: ${RUNTIME_VERSION}                               │"
echo "│  Features: 3 │ Events per Feature: 15 │ Total: 45          │"
echo "│  Execution: interleaved across all three Features          │"
echo "└────────────────────────────────────────────────────────────┘"
echo ""

log "=== bootstrap-multi-feature.sh v${RUNTIME_VERSION} started ==="

# ── Doctor ──────────────────────────────────────────────────────────────────
echo "Running Runtime Doctor..."
if ! bash "$SCRIPT_DIR/runtime-doctor.sh"; then
  echo ""
  echo "  Doctor reported FAIL. Aborting multi-feature run."
  exit 1
fi

# ── Generate one correlation-id per Feature ──────────────────────────────────
declare -a CORR_IDS
declare -a PREV_STATES

for i in "${!ISSUES[@]}"; do
  CORR_IDS[$i]=$(uuidgen | tr '[:upper:]' '[:lower:]')
  PREV_STATES[$i]=""
  ISSUE="${ISSUES[$i]}"
  echo "[]" > "$ARTIFACTS_DIR/timelines/${ISSUE}.json"
  log "${FEATURE_NAMES[$i]} | issue=#${ISSUE} | correlation-id=${CORR_IDS[$i]}"
done

echo ""
echo "Correlation IDs:"
for i in "${!ISSUES[@]}"; do
  echo "  Issue #${ISSUES[$i]} ${FEATURE_NAMES[$i]}: ${CORR_IDS[$i]}"
done
echo ""

# ── Event Sequence ───────────────────────────────────────────────────────────
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

TOTAL_EVENTS=${#EVENTS[@]}
STEP=0

for EVENT in "${EVENTS[@]}"; do
  ((STEP++)) || true
  ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")
  CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")

  echo "══ Step ${STEP}/${TOTAL_EVENTS}: ${EVENT}"

  for i in "${!ISSUES[@]}"; do
    ISSUE="${ISSUES[$i]}"
    CORR="${CORR_IDS[$i]}"
    FNAME="${FEATURE_NAMES[$i]}"
    PREV="${PREV_STATES[$i]}"

    # A: Emit
    CE_JSON=$(bash "$RUNTIME_DIR/producer/emit.sh" \
      --issue          "$ISSUE" \
      --event          "$EVENT" \
      --correlation-id "$CORR")

    log "#${ISSUE} | $CE_TYPE | id=$(echo "$CE_JSON" | jq -r '.id')"

    # B: Append to this Feature's Timeline
    TIMELINE_FILE=$(bash "$RUNTIME_DIR/timeline/append.sh" \
      --issue      "$ISSUE" \
      --event-json "$CE_JSON")

    EVCOUNT=$(jq 'length' "$TIMELINE_FILE")

    # C: Derive State (per-issue)
    DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" --issue "$ISSUE")
    CURRENT_STATE=$(echo "$DERIVED" | jq -r '.state')
    LAST_EVENT_TYPE=$(echo "$DERIVED" | jq -r '.["last-event-type"]')

    # D: Datadog
    bash "$RUNTIME_DIR/datadog/send.sh" \
      --issue          "$ISSUE" \
      --event          "$CE_TYPE" \
      --state          "$CURRENT_STATE" \
      --correlation-id "$CORR" >> "$LOG_FILE" 2>&1

    # E: GitHub sync (only on state-altering events)
    if [[ "$ALTERS_STATE" == "true" ]]; then
      bash "$RUNTIME_DIR/github/sync.sh" \
        --issue          "$ISSUE" \
        --state          "$CURRENT_STATE" \
        --last-event     "$LAST_EVENT_TYPE" \
        --correlation-id "$CORR" >> "$LOG_FILE" 2>&1
      STATE_MARKER="→ ${CURRENT_STATE}"
    else
      STATE_MARKER="(${CURRENT_STATE})"
    fi

    echo "   #${ISSUE} ${FNAME}: ${STATE_MARKER} | ${EVCOUNT} event(s) | Datadog ✓"
    PREV_STATES[$i]="$CURRENT_STATE"
  done

  echo ""
done

# ── Final Summary ─────────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Multi-Feature Validation — COMPLETE"
echo ""

ALL_DONE=true
for i in "${!ISSUES[@]}"; do
  ISSUE="${ISSUES[$i]}"
  FNAME="${FEATURE_NAMES[$i]}"
  CORR="${CORR_IDS[$i]}"
  DERIVED_FILE="$ARTIFACTS_DIR/derived-state-${ISSUE}.json"
  FINAL_STATE=$(jq -r '.state' "$DERIVED_FILE")
  FINAL_COUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/${ISSUE}.json")

  if [[ "$FINAL_STATE" != "DONE" ]]; then
    ALL_DONE=false
  fi

  STATUS_ICON="✅"
  [[ "$FINAL_STATE" != "DONE" ]] && STATUS_ICON="❌"

  echo "  ${STATUS_ICON} Issue #${ISSUE} — ${FNAME}"
  echo "     State:         ${FINAL_STATE}"
  echo "     Events:        ${FINAL_COUNT}"
  echo "     Correlation:   ${CORR}"
  echo "     Timeline:      $ARTIFACTS_DIR/timelines/${ISSUE}.json"
  echo "     Derived state: ${DERIVED_FILE}"
  echo ""
done

echo "  GitHub Project:  https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}"
echo "  Datadog metric:  runtime.event.received | filter: issue, correlation-id"
echo ""

if $ALL_DONE; then
  echo "  Result: ALL THREE FEATURES REACHED DONE ✅"
else
  echo "  Result: NOT ALL FEATURES REACHED DONE ❌ — check logs"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

log "=== bootstrap-multi-feature.sh v${RUNTIME_VERSION} complete ==="
for i in "${!ISSUES[@]}"; do
  ISSUE="${ISSUES[$i]}"
  FINAL_STATE=$(jq -r '.state' "$ARTIFACTS_DIR/derived-state-${ISSUE}.json")
  log "#${ISSUES[$i]} ${FEATURE_NAMES[$i]} | final-state: $FINAL_STATE | correlation-id: ${CORR_IDS[$i]}"
done
