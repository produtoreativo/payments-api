#!/usr/bin/env bash
# bootstrap-non-uniform.sh — EXP-013 Iteration 6: Operational Validation
# Runs three Features to different points in the Happy Path simultaneously,
# demonstrating that GitHub, Timeline, Derived State and Datadog remain consistent
# when Features are at different operational stages.
#
# Final states:
#   FTR-001 (#76) → DONE        (15 events — full happy path)
#   FTR-002 (#77) → VALIDATING  (11 events — stopped after Validate.Started)
#   FTR-003 (#78) → HACKING     ( 3 events — stopped after Hack.Started)

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

echo ""
echo "┌────────────────────────────────────────────────────────────────┐"
echo "│  EXP-013 — Iteration 6: Operational Validation                │"
echo "│  runtime-version: ${RUNTIME_VERSION}                                   │"
echo "│  Scenario: Non-Uniform — DONE / VALIDATING / HACKING          │"
echo "│  FTR-001 (#76) → 15 events → DONE                            │"
echo "│  FTR-002 (#77) → 11 events → VALIDATING                      │"
echo "│  FTR-003 (#78) →  3 events → HACKING                         │"
echo "└────────────────────────────────────────────────────────────────┘"
echo ""

log "=== bootstrap-non-uniform.sh v${RUNTIME_VERSION} started ==="

# ── Doctor ──────────────────────────────────────────────────────────────────
echo "Running Runtime Doctor..."
if ! bash "$SCRIPT_DIR/runtime-doctor.sh"; then
  echo "  Doctor reported FAIL. Aborting."
  exit 1
fi

# ── Per-Feature configuration ────────────────────────────────────────────────
# Each feature has: issue, name, correlation-id, event sequence
ISSUES=(76 77 78)
FEATURE_NAMES=("FTR-001: Invoice PIX" "FTR-002: Invoice Cartão" "FTR-003: Confirmação Pagamento")
TARGET_STATES=("DONE" "VALIDATING" "HACKING")

EVENTS_76=(
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

EVENTS_77=(
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
)

EVENTS_78=(
  "Delivery.Bootstrap.Started"
  "Delivery.Bootstrap.Completed"
  "Delivery.Hack.Started"
)

declare -a CORR_IDS

for i in "${!ISSUES[@]}"; do
  CORR_IDS[$i]=$(uuidgen | tr '[:upper:]' '[:lower:]')
  echo "[]" > "$ARTIFACTS_DIR/timelines/${ISSUES[$i]}.json"
  log "${FEATURE_NAMES[$i]} | issue=#${ISSUES[$i]} | target=${TARGET_STATES[$i]} | correlation-id=${CORR_IDS[$i]}"
done

echo ""
echo "Correlation IDs:"
for i in "${!ISSUES[@]}"; do
  echo "  Issue #${ISSUES[$i]} (→ ${TARGET_STATES[$i]}): ${CORR_IDS[$i]}"
done
echo ""

# ── Helper: emit one event for one feature ──────────────────────────────────
emit_event() {
  local ISSUE="$1"
  local EVENT="$2"
  local CORR="$3"

  local ALTERS_STATE
  ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")
  local CE_TYPE
  CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")

  local CE_JSON
  CE_JSON=$(bash "$RUNTIME_DIR/producer/emit.sh" \
    --issue          "$ISSUE" \
    --event          "$EVENT" \
    --correlation-id "$CORR")

  log "#${ISSUE} | $CE_TYPE | id=$(echo "$CE_JSON" | jq -r '.id')"

  local TIMELINE_FILE
  TIMELINE_FILE=$(bash "$RUNTIME_DIR/timeline/append.sh" \
    --issue      "$ISSUE" \
    --event-json "$CE_JSON")

  local EVCOUNT
  EVCOUNT=$(jq 'length' "$TIMELINE_FILE")

  local DERIVED
  DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" --issue "$ISSUE")
  local CURRENT_STATE
  CURRENT_STATE=$(echo "$DERIVED" | jq -r '.state')
  local LAST_EVENT_TYPE
  LAST_EVENT_TYPE=$(echo "$DERIVED" | jq -r '.["last-event-type"]')

  bash "$RUNTIME_DIR/datadog/send.sh" \
    --issue          "$ISSUE" \
    --event          "$CE_TYPE" \
    --state          "$CURRENT_STATE" \
    --correlation-id "$CORR" >> "$LOG_FILE" 2>&1

  if [[ "$ALTERS_STATE" == "true" ]]; then
    bash "$RUNTIME_DIR/github/sync.sh" \
      --issue          "$ISSUE" \
      --state          "$CURRENT_STATE" \
      --last-event     "$LAST_EVENT_TYPE" \
      --correlation-id "$CORR" >> "$LOG_FILE" 2>&1
    echo "   #${ISSUE} ${CE_TYPE} → ${CURRENT_STATE} | ${EVCOUNT} events | GitHub ✓ | Datadog ✓"
  else
    echo "   #${ISSUE} ${CE_TYPE} (${CURRENT_STATE}) | ${EVCOUNT} events | Datadog ✓"
  fi
}

# ── FTR-001: Full Happy Path → DONE ─────────────────────────────────────────
echo "── FTR-001 (#76) — Full Happy Path → DONE"
for EVENT in "${EVENTS_76[@]}"; do
  emit_event "76" "$EVENT" "${CORR_IDS[0]}"
done
echo ""

# ── FTR-002: Partial → VALIDATING ───────────────────────────────────────────
echo "── FTR-002 (#77) — Partial Happy Path → VALIDATING"
for EVENT in "${EVENTS_77[@]}"; do
  emit_event "77" "$EVENT" "${CORR_IDS[1]}"
done
echo ""

# ── FTR-003: Early stop → HACKING ───────────────────────────────────────────
echo "── FTR-003 (#78) — Early Stop → HACKING"
for EVENT in "${EVENTS_78[@]}"; do
  emit_event "78" "$EVENT" "${CORR_IDS[2]}"
done
echo ""

# ── Final State Comparison ────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  Operational Snapshot — Non-Uniform State"
echo ""

ALL_CORRECT=true
for i in "${!ISSUES[@]}"; do
  ISSUE="${ISSUES[$i]}"
  FNAME="${FEATURE_NAMES[$i]}"
  TARGET="${TARGET_STATES[$i]}"
  CORR="${CORR_IDS[$i]}"
  DERIVED_FILE="$ARTIFACTS_DIR/derived-state-${ISSUE}.json"
  FINAL_STATE=$(jq -r '.state' "$DERIVED_FILE")
  FINAL_COUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/${ISSUE}.json")

  if [[ "$FINAL_STATE" == "$TARGET" ]]; then
    STATUS="✅"
  else
    STATUS="❌"
    ALL_CORRECT=false
  fi

  echo "  ${STATUS} Issue #${ISSUE} — ${FNAME}"
  echo "     State:        ${FINAL_STATE} (expected: ${TARGET})"
  echo "     Events:       ${FINAL_COUNT}"
  echo "     Correlation:  ${CORR}"
  echo ""
done

echo "  GitHub Project:  https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}"
echo ""

if $ALL_CORRECT; then
  echo "  Result: NON-UNIFORM STATES CONFIRMED ✅"
  echo "  Three Features are simultaneously at different operational stages."
else
  echo "  Result: STATE MISMATCH ❌ — check logs"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

log "=== bootstrap-non-uniform.sh v${RUNTIME_VERSION} complete ==="
for i in "${!ISSUES[@]}"; do
  FINAL_STATE=$(jq -r '.state' "$ARTIFACTS_DIR/derived-state-${ISSUES[$i]}.json")
  log "#${ISSUES[$i]} ${FEATURE_NAMES[$i]} | final-state: $FINAL_STATE | correlation-id: ${CORR_IDS[$i]}"
done
