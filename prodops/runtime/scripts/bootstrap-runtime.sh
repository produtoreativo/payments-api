#!/usr/bin/env bash
# bootstrap-runtime.sh — EXP-013 Iteration 3: CloudEvents Foundation
# Runs the minimal operational cycle for the pilot issue:
#   Doctor → Emit CloudEvent → Timeline → Derived State → GitHub Project → Datadog

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"

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
echo "┌──────────────────────────────────────────────────┐"
echo "│   EXP-013 — Iteration 3: CloudEvents Foundation  │"
echo "│   runtime-version: ${RUNTIME_VERSION}                      │"
echo "│   Pilot issue: #${PILOT_ISSUE} (FTR-001: Invoice PIX)     │"
echo "└──────────────────────────────────────────────────┘"
echo ""

log "=== bootstrap-runtime.sh v${RUNTIME_VERSION} started ==="
log "Pilot issue: #${PILOT_ISSUE} | Repo: ${GH_OWNER}/${GH_REPO} | Project: #${GH_PROJECT}"

# ── Doctor ──────────────────────────────────────────────────────────────────
echo "Running Runtime Doctor..."
if ! bash "$SCRIPT_DIR/runtime-doctor.sh"; then
  echo ""
  echo "  Doctor reported FAIL. Aborting bootstrap."
  exit 1
fi

CORRELATION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
log "Correlation ID: $CORRELATION_ID"

# ── Step 1: Emit CloudEvent ──────────────────────────────────────────────────
echo "Step 1/5 — Emitting CloudEvent: Delivery.Bootstrap.Started..."
CE_JSON=$(bash "$RUNTIME_DIR/producer/emit.sh" \
  --issue          "$PILOT_ISSUE" \
  --event          "Delivery.Bootstrap.Started" \
  --correlation-id "$CORRELATION_ID")

log "CloudEvent emitted: $CE_JSON"
echo "  ✓ specversion:            $(echo "$CE_JSON" | jq -r '.specversion')"
echo "  ✓ id:                     $(echo "$CE_JSON" | jq -r '.id')"
echo "  ✓ type:                   $(echo "$CE_JSON" | jq -r '.type')"
echo "  ✓ runtime-correlation-id: $CORRELATION_ID"

# ── Step 2: Persist Timeline ─────────────────────────────────────────────────
echo ""
echo "Step 2/5 — Persisting CloudEvent in Timeline..."
TIMELINE_FILE=$(bash "$RUNTIME_DIR/timeline/append.sh" \
  --issue      "$PILOT_ISSUE" \
  --event-json "$CE_JSON")

log "Timeline persisted: $TIMELINE_FILE"
EVENT_COUNT=$(jq 'length' "$TIMELINE_FILE")
echo "  ✓ Timeline: $TIMELINE_FILE"
echo "  ✓ Events:   $EVENT_COUNT"

# ── Step 3: Derive State ─────────────────────────────────────────────────────
echo ""
echo "Step 3/5 — Computing Derived State from CloudEvents..."
DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" \
  --issue "$PILOT_ISSUE")

DERIVED_STATE=$(echo "$DERIVED" | jq -r '.state')
DERIVED_EVENT_TYPE=$(echo "$DERIVED" | jq -r '.["last-event-type"]')
log "Derived state: $DERIVED"
echo "  ✓ state:           $DERIVED_STATE"
echo "  ✓ last-event-type: $DERIVED_EVENT_TYPE"

# ── Step 4: Update GitHub Project ────────────────────────────────────────────
echo ""
echo "Step 4/5 — Updating GitHub Project (oem-state + oem-last-event)..."
bash "$RUNTIME_DIR/github/sync.sh" \
  --issue          "$PILOT_ISSUE" \
  --state          "$DERIVED_STATE" \
  --last-event     "$DERIVED_EVENT_TYPE" \
  --correlation-id "$CORRELATION_ID" 2>&1 | tee -a "$LOG_FILE"
echo "  ✓ GitHub sync complete (see github-sync.log)"

# ── Step 5: Send Datadog metric ───────────────────────────────────────────────
echo ""
echo "Step 5/5 — Sending metric to Datadog..."
bash "$RUNTIME_DIR/datadog/send.sh" \
  --issue          "$PILOT_ISSUE" \
  --event          "$DERIVED_EVENT_TYPE" \
  --state          "$DERIVED_STATE" \
  --correlation-id "$CORRELATION_ID" 2>&1 | tee -a "$LOG_FILE"
echo "  ✓ Datadog metric sent (see datadog.log)"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "----------------------------------"
echo ""
echo "  Issue:              #${PILOT_ISSUE} — FTR-001: Invoice PIX — Happy Path Completo"
echo "  CloudEvent type:    $DERIVED_EVENT_TYPE"
echo "  Estado:             $DERIVED_STATE"
echo "  Correlation ID:     $CORRELATION_ID"
echo "  Timeline:           $TIMELINE_FILE"
echo "  Project atualizado: https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}"
echo "  Datadog enviado:    metric=runtime.event.received | issue:${PILOT_ISSUE} state:${DERIVED_STATE}"
echo ""
echo "----------------------------------"
echo ""
log "=== bootstrap-runtime.sh v${RUNTIME_VERSION} complete | correlation-id: $CORRELATION_ID ==="
