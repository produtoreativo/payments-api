#!/usr/bin/env bash
# Datadog Sender — publishes runtime.event.received metric via HTTP API v2
# Usage: send.sh --issue <id> --event <type> --state <state> --correlation-id <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"
LOG_FILE="$PRODOPS_DIR/artifacts/runtime/datadog.log"

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

# Credentials: prefer environment variables, fall back to api/.env
ENV_FILE="$PRODOPS_DIR/../api/.env"
if [[ -z "${DD_API_KEY:-}" && -f "$ENV_FILE" ]]; then
  DD_API_KEY=$(grep -E "^DD_API_KEY=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
fi
if [[ -z "${DD_SITE:-}" && -f "$ENV_FILE" ]]; then
  DD_SITE=$(grep -E "^DD_SITE=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
fi
DD_SITE="${DD_SITE:-datadoghq.com}"

ISSUE=""
EVENT=""
STATE=""
CORRELATION_ID=""
LEAD_TIME_DAYS=""
ITERATION_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)            ISSUE="$2"; shift 2 ;;
    --event)            EVENT="$2"; shift 2 ;;
    --state)            STATE="$2"; shift 2 ;;
    --correlation-id)   CORRELATION_ID="$2"; shift 2 ;;
    --lead-time-days)   LEAD_TIME_DAYS="$2"; shift 2 ;;
    --iteration-id)     ITERATION_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ISSUE" ]]  && { echo "Error: --issue required" >&2; exit 1; }
[[ -z "$EVENT" ]]  && { echo "Error: --event required" >&2; exit 1; }
[[ -z "$STATE" ]]  && { echo "Error: --state required" >&2; exit 1; }

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

CORR="${CORRELATION_ID:-no-correlation-id}"

# Determine metric name based on event journey prefix:
#   prodops.diligence.* → runtime.diligence.event.received
#   prodops.delivery.*  → runtime.event.received
if [[ "$EVENT" == prodops.diligence.* ]]; then
  METRIC="runtime.diligence.event.received"
else
  METRIC="runtime.event.received"
fi

log "Sending metric — ${METRIC} | issue=${ISSUE} event=${EVENT} state=${STATE} correlation-id=${CORR}"

if [[ -z "${DD_API_KEY:-}" ]]; then
  log "ERROR: DD_API_KEY is not set"
  exit 1
fi

NOW=$(date +%s)

# Build base tags array; append iteration:<id> tag when iteration-id is known.
PAYLOAD=$(jq -n \
  --argjson now "$NOW" \
  --arg metric         "$METRIC" \
  --arg issue          "$ISSUE" \
  --arg event          "$EVENT" \
  --arg state          "$STATE" \
  --arg correlation_id "$CORR" \
  --arg service        "$DD_SERVICE" \
  --arg env            "$DD_ENV_VALUE" \
  --arg iteration_id   "${ITERATION_ID:-}" \
  --argjson has_iter   "$([ -n "${ITERATION_ID:-}" ] && echo true || echo false)" \
  '{
    series: [{
      metric: $metric,
      type: 1,
      points: [{ timestamp: $now, value: 1 }],
      tags: (
        [
          ("issue:" + $issue),
          ("event:" + $event),
          ("delivery-state:" + $state),
          ("delivery-correlation-id:" + $correlation_id),
          ("service:" + $service),
          ("env:" + $env),
          "runtime:prodops"
        ] + (if $has_iter then [("iteration:" + $iteration_id)] else [] end)
      )
    }]
  }')

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://api.${DD_SITE}/api/v2/series" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -d "$PAYLOAD")

if [[ "$HTTP_STATUS" == "202" ]]; then
  log "Datadog accepted metric — HTTP ${HTTP_STATUS}"
  log "Visualize: Metrics Explorer → metric: ${METRIC} → filter: issue:${ISSUE}"
else
  log "ERROR: Datadog returned HTTP ${HTTP_STATUS}"
  log "Payload: $PAYLOAD"
  exit 1
fi

if [[ -n "${LEAD_TIME_DAYS:-}" ]]; then
  LEAD_PAYLOAD=$(jq -n \
    --argjson now   "$NOW" \
    --argjson days  "$LEAD_TIME_DAYS" \
    --arg issue     "$ISSUE" \
    --arg service   "$DD_SERVICE" \
    --arg env       "$DD_ENV_VALUE" \
    '{
      series: [{
        metric: "runtime.delivery.lead_time_days",
        type: 0,
        points: [{ timestamp: $now, value: $days }],
        tags: [
          ("issue:" + $issue),
          ("service:" + $service),
          ("env:" + $env),
          "runtime:prodops"
        ]
      }]
    }')

  HTTP_STATUS2=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$LEAD_PAYLOAD")

  if [[ "$HTTP_STATUS2" == "202" ]]; then
    log "Lead time metric accepted — ${LEAD_TIME_DAYS} days | HTTP ${HTTP_STATUS2}"
  else
    log "ERROR: Lead time metric returned HTTP ${HTTP_STATUS2}"
    exit 1
  fi
fi
