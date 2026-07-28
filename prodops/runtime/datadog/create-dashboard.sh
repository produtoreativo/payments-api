#!/usr/bin/env bash
# create-dashboard.sh — creates a minimal ProdOps Runtime dashboard in Datadog
# Requires: DD_API_KEY + DD_APP_KEY (application key)
# Usage: create-dashboard.sh

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

ENV_FILE="$PRODOPS_DIR/../api/.env"
if [[ -z "${DD_API_KEY:-}" && -f "$ENV_FILE" ]]; then
  DD_API_KEY=$(grep -E "^DD_API_KEY=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
fi
if [[ -z "${DD_APP_KEY:-}" && -f "$ENV_FILE" ]]; then
  DD_APP_KEY=$(grep -E "^DD_APP_KEY=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
fi
if [[ -z "${DD_SITE:-}" && -f "$ENV_FILE" ]]; then
  DD_SITE=$(grep -E "^DD_SITE=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
fi
DD_SITE="${DD_SITE:-datadoghq.com}"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

# ── Build dashboard JSON ────────────────────────────────────────────────────
DASHBOARD_JSON=$(jq -n \
  --arg service "$DD_SERVICE" \
  --arg env     "$DD_ENV_VALUE" \
'{
  "title": "ProdOps Runtime — EXP-013 Delivery Happy Path",
  "description": "Operational visibility for the ProdOps Runtime experiment. Tracks CloudEvents emitted per issue and runtime-correlation-id.",
  "layout_type": "ordered",
  "reflow_type": "fixed",
  "template_variables": [
    {
      "name": "correlation_id",
      "prefix": "correlation-id",
      "available_values": [],
      "default": "*"
    },
    {
      "name": "issue",
      "prefix": "issue",
      "available_values": [],
      "default": "*"
    }
  ],
  "widgets": [
    {
      "definition": {
        "type": "note",
        "content": "## ProdOps Runtime — EXP-013\n\nUse **$correlation_id** to filter a single execution run.\nUse **$issue** to filter by Feature (GitHub issue number).",
        "background_color": "blue",
        "font_size": "14",
        "text_align": "left",
        "show_tick": false,
        "tick_pos": "50%",
        "tick_edge": "left"
      },
      "layout": {"x": 0, "y": 0, "width": 12, "height": 1}
    },
    {
      "definition": {
        "type": "query_value",
        "title": "Total de Eventos",
        "requests": [
          {
            "q": "sum:runtime.event.received{issue:$issue.value,correlation-id:$correlation_id.value}.as_count()",
            "aggregator": "sum"
          }
        ],
        "precision": 0,
        "time": {"live_span": "4h"}
      },
      "layout": {"x": 0, "y": 1, "width": 3, "height": 2}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "Último Estado por Issue",
        "requests": [
          {
            "q": "top(sum:runtime.event.received{issue:$issue.value} by {issue,state}.as_count(), 25, '\''sum'\'', '\''desc'\'')"
          }
        ],
        "time": {"live_span": "4h"}
      },
      "layout": {"x": 3, "y": 1, "width": 4, "height": 2}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "Eventos por Tipo",
        "requests": [
          {
            "q": "top(sum:runtime.event.received{issue:$issue.value,correlation-id:$correlation_id.value} by {event}.as_count(), 15, '\''sum'\'', '\''desc'\'')"
          }
        ],
        "time": {"live_span": "4h"}
      },
      "layout": {"x": 7, "y": 1, "width": 5, "height": 2}
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "Timeline de Eventos (por tipo)",
        "requests": [
          {
            "q": "sum:runtime.event.received{issue:$issue.value,correlation-id:$correlation_id.value} by {event}.as_count()",
            "display_type": "bars",
            "style": {"palette": "dog_classic"}
          }
        ],
        "show_legend": true,
        "time": {"live_span": "4h"}
      },
      "layout": {"x": 0, "y": 3, "width": 12, "height": 3}
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "Timeline de Transições de Estado",
        "requests": [
          {
            "q": "sum:runtime.event.received{issue:$issue.value,correlation-id:$correlation_id.value} by {state}.as_count()",
            "display_type": "bars",
            "style": {"palette": "cool"}
          }
        ],
        "show_legend": true,
        "time": {"live_span": "4h"}
      },
      "layout": {"x": 0, "y": 6, "width": 12, "height": 3}
    }
  ]
}')

# ── Save definition regardless of API availability ─────────────────────────
DASHBOARD_DEF_FILE="$PRODOPS_DIR/artifacts/runtime/datadog-dashboard-definition.json"
echo "$DASHBOARD_JSON" > "$DASHBOARD_DEF_FILE"
log "Dashboard definition saved to: $DASHBOARD_DEF_FILE"

# ── Try API creation ───────────────────────────────────────────────────────
if [[ -z "${DD_API_KEY:-}" ]]; then
  log "ERROR: DD_API_KEY not set — cannot create dashboard via API"
  echo "Dashboard definition saved. Create manually via Datadog UI → Import JSON."
  exit 1
fi

if [[ -z "${DD_APP_KEY:-}" ]]; then
  log "WARN: DD_APP_KEY not set — dashboard creation requires Application Key"
  echo ""
  echo "  Dashboard definition saved to: $DASHBOARD_DEF_FILE"
  echo "  To create the dashboard:"
  echo "    1. Open Datadog → Dashboards → New Dashboard"
  echo "    2. Click the cog icon → Import dashboard JSON"
  echo "    3. Paste the content of: $DASHBOARD_DEF_FILE"
  echo ""
  exit 0
fi

log "Creating dashboard via Datadog API..."

RESPONSE_FILE=$(mktemp)
HTTP_STATUS=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" \
  -X POST "https://api.${DD_SITE}/api/v1/dashboard" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d "$DASHBOARD_JSON")
HTTP_BODY=$(cat "$RESPONSE_FILE")
rm -f "$RESPONSE_FILE"

if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "201" ]]; then
  DASHBOARD_ID=$(echo "$HTTP_BODY" | jq -r '.id // empty')
  DASHBOARD_URL=$(echo "$HTTP_BODY" | jq -r '.url // empty')
  log "Dashboard created — ID: $DASHBOARD_ID"
  echo ""
  echo "  Dashboard created successfully!"
  echo "  ID:  $DASHBOARD_ID"
  echo "  URL: https://app.${DD_SITE}${DASHBOARD_URL}"
  echo ""
  echo "$HTTP_BODY" > "$PRODOPS_DIR/artifacts/runtime/datadog-dashboard-response.json"
else
  log "ERROR: Datadog API returned HTTP ${HTTP_STATUS}"
  log "Response: $HTTP_BODY"
  echo ""
  echo "  Dashboard creation failed (HTTP ${HTTP_STATUS})."
  echo "  Definition saved to: $DASHBOARD_DEF_FILE"
  echo "  Import manually via: Datadog → Dashboards → New Dashboard → Import JSON"
  echo ""
  exit 1
fi
