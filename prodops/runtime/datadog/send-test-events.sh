#!/usr/bin/env bash
# send-test-events.sh — injects synthetic events to verify dashboard v3 queries
#
# Sends one event per delivery phase and one per diligence phase, plus
# exception path events and a lead time gauge, all for the current active issue.
#
# Usage: bash send-test-events.sh [--issue <n>] [--lead-time-days <n>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CONFIG="$REPO_ROOT/prodops/runtime/runtime.yaml"
ENV_FILE="${REPO_ROOT}/api/.env"
DD_SITE="${DD_SITE:-datadoghq.com}"

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

DD_SERVICE=$(yaml_get "datadog.service")
DD_ENV_VALUE=$(yaml_get "datadog.environment")

eval "$(grep -E "^(DD_API_KEY)=" "$ENV_FILE" | sed 's/^/export /')"
if [[ -z "${DD_API_KEY:-}" ]]; then
  echo "ERROR: DD_API_KEY not set in $ENV_FILE" >&2; exit 1
fi

ISSUE="40"
LEAD_TIME_DAYS="3"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)           ISSUE="$2"; shift 2 ;;
    --lead-time-days)  LEAD_TIME_DAYS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

CORR_ID="test-$(date -u +%Y%m%d%H%M%S)"

log() { echo "[$(date -u +"%H:%M:%SZ")] $*"; }
ok()  { echo "  ✓ $*"; }

send_delivery() {
  local event="$1" state="$2"
  bash "$SCRIPT_DIR/send.sh" \
    --issue          "$ISSUE" \
    --event          "$event" \
    --state          "$state" \
    --correlation-id "$CORR_ID"
  ok "runtime.event.received | event=${event} | state=${state}"
}

send_diligence() {
  local event="$1" diligence_status="$2"
  local now; now=$(date +%s)

  local payload; payload=$(jq -n \
    --argjson now             "$now" \
    --arg issue               "$ISSUE" \
    --arg event               "$event" \
    --arg delivery_state      "DONE" \
    --arg diligence_status    "$diligence_status" \
    --arg delivery_corr       "$CORR_ID" \
    --arg diligence_corr      "${CORR_ID}-dil" \
    --arg service             "$DD_SERVICE" \
    --arg env                 "$DD_ENV_VALUE" \
    '{
      series: [{
        metric: "runtime.diligence.event.received",
        type: 1,
        points: [{ timestamp: $now, value: 1 }],
        tags: [
          ("issue:" + $issue),
          ("event:" + $event),
          ("delivery-state:" + $delivery_state),
          ("diligence-status:" + $diligence_status),
          ("delivery-correlation-id:" + $delivery_corr),
          ("diligence-correlation-id:" + $diligence_corr),
          ("service:" + $service),
          ("env:" + $env),
          "runtime:prodops"
        ]
      }]
    }')

  local http_status; http_status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$payload")

  if [[ "$http_status" == "202" ]]; then
    ok "runtime.diligence.event.received | event=${event} | status=${diligence_status}"
  else
    echo "  ✗ ERROR HTTP ${http_status} for ${event}" >&2
    exit 1
  fi
}

echo ""
echo "┌────────────────────────────────────────────────────────────────┐"
echo "│  send-test-events.sh — Dashboard v3 Query Verification        │"
echo "│  issue=#${ISSUE} | service=${DD_SERVICE} | env=${DD_ENV_VALUE}          │"
echo "│  corr-id: ${CORR_ID}                 │"
echo "└────────────────────────────────────────────────────────────────┘"
echo ""

# ── Delivery Happy Path events ────────────────────────────────────────────────
log "Sending Delivery Journey events (all 8 phases)..."

send_delivery "prodops.delivery.bootstrap.started"  "BOOTSTRAPPING"
sleep 1
send_delivery "prodops.delivery.hack.started"       "HACKING"
sleep 1
send_delivery "prodops.delivery.sync.started"       "SYNCING"
sleep 1
send_delivery "prodops.delivery.finish.started"     "FINISHING"
sleep 1
send_delivery "prodops.delivery.ship.started"       "SHIPPING"
sleep 1
send_delivery "prodops.delivery.validate.started"   "VALIDATING"
sleep 1
send_delivery "prodops.delivery.promote.started"    "PROMOTING"
sleep 1
send_delivery "prodops.delivery.promote.completed"  "DONE"

echo ""

# ── Lead Time gauge ───────────────────────────────────────────────────────────
log "Sending Lead Time gauge (${LEAD_TIME_DAYS} days)..."

bash "$SCRIPT_DIR/send.sh" \
  --issue          "$ISSUE" \
  --event          "prodops.delivery.promote.completed" \
  --state          "DONE" \
  --correlation-id "$CORR_ID" \
  --lead-time-days "$LEAD_TIME_DAYS"

ok "runtime.delivery.lead_time_days | issue=${ISSUE} | days=${LEAD_TIME_DAYS}"
echo ""

# ── Diligence Happy Path events ───────────────────────────────────────────────
log "Sending Diligence Status events (Capture, Attach, Promote, Close)..."

send_diligence "prodops.diligence.capture.completed"  "Captured"
sleep 1
send_diligence "prodops.diligence.attach.completed"   "Attached"
sleep 1
send_diligence "prodops.diligence.promote.completed"  "Promoted"
sleep 1
send_diligence "prodops.diligence.close.completed"    "Closed"

echo ""

# ── Exception Path events ─────────────────────────────────────────────────────
log "Sending Exception Path events (Block, Drift, Repair, Close)..."

send_diligence "prodops.diligence.block.declared"       "Blocked"
sleep 1
send_diligence "prodops.diligence.divergence.detected"  "Drift"
sleep 1
send_diligence "prodops.diligence.repair.completed"     "Repaired"
sleep 1
send_diligence "prodops.diligence.close.completed"      "Closed"

echo ""

log "All test events sent ✓"
echo ""
echo "  Dashboard queries to verify (select last 1h in Datadog):"
echo "  - KPI: Iteration Ativas   → should show ≥1"
echo "  - KPI: DONE               → should show ≥1"
echo "  - KPI: Falhas/Bloqueios   → should show ≥1"
echo "  - KPI: Lead Time (dias)   → should show ${LEAD_TIME_DAYS}"
echo "  - Funil: bars per phase   → should show 8 phases"
echo "  - Delivery phases: each   → should show ≥1"
echo "  - Diligence phases: each  → should show ≥1"
echo "  - Exception Paths: each   → should show ≥1"
echo ""
echo "  Note: Datadog may take 1-2 minutes to index new metrics."
echo ""
