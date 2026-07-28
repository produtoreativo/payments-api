#!/usr/bin/env bash
# create-demo-dashboard.sh — cria o Dashboard Datadog para EXP-014 Iteration 2
# "ProdOps Runtime — Delivery Tracked by Diligence"
# 4 Seções (A,B,C,D) × 4 widgets cada = 16 widgets

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
for KEY in DD_API_KEY DD_APP_KEY DD_SITE; do
  if [[ -z "${!KEY:-}" && -f "$ENV_FILE" ]]; then
    VAL=$(grep -E "^${KEY}=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
    [[ -n "$VAL" ]] && export "$KEY=$VAL"
  fi
done
DD_SITE="${DD_SITE:-datadoghq.com}"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

echo ""
echo "┌────────────────────────────────────────────────────────────────┐"
echo "│  Datadog Dashboard — EXP-014 Iteration 2                      │"
echo "│  ProdOps Runtime — Delivery Tracked by Diligence              │"
echo "└────────────────────────────────────────────────────────────────┘"
echo ""

DASHBOARD_JSON=$(jq -n \
  --arg service "$DD_SERVICE" \
  --arg env     "$DD_ENV_VALUE" \
'{
  "title": "ProdOps Runtime — Delivery Tracked by Diligence",
  "description": "EXP-014 Iter 2 — Operational visibility for Delivery and Diligence journeys. Tracks CloudEvents, state transitions, and correlation across GitHub, Datadog and Runtime.",
  "layout_type": "ordered",
  "reflow_type": "fixed",
  "template_variables": [
    { "name": "issue",                    "prefix": "issue",                   "available_values": ["76","77","78"], "default": "*" },
    { "name": "delivery_correlation_id",  "prefix": "delivery-correlation-id", "available_values": [], "default": "*" },
    { "name": "diligence_correlation_id", "prefix": "diligence-correlation-id","available_values": [], "default": "*" },
    { "name": "delivery_state",           "prefix": "delivery-state",          "available_values": [], "default": "*" },
    { "name": "diligence_status",         "prefix": "diligence-status",        "available_values": [], "default": "*" },
    { "name": "service",                  "prefix": "service",                 "available_values": [], "default": $service },
    { "name": "env",                      "prefix": "env",                     "available_values": [], "default": $env },
    { "name": "demo_run_id",              "prefix": "demo-run-id",             "available_values": [], "default": "*" }
  ],
  "widgets": [
    {
      "definition": {
        "type": "note",
        "content": "## ProdOps Runtime — EXP-014 Iteration 2\n### Delivery Tracked by Diligence\n\n**Features:**\n- #76 FTR-001 — Invoice PIX → **DONE**\n- #77 FTR-002 — Invoice Cartão → **VALIDATING**\n- #78 FTR-003 — Confirmação de Pagamento → **HACKING**\n\n**Delivery** `runtime.event.received` | **Diligence** `runtime.diligence.event.received`\n\nFilter by `$demo_run_id` to isolate a single recording run.\n[GitHub Project →](https://github.com/orgs/produtoreativo/projects/25)",
        "background_color": "vivid_blue",
        "font_size": "14",
        "text_align": "left",
        "show_tick": false
      },
      "layout": {"x": 0, "y": 0, "width": 6, "height": 3}
    },
    {
      "definition": {
        "type": "query_value",
        "title": "Delivery Events",
        "requests": [{
          "q": "sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value}.as_count()",
          "aggregator": "sum"
        }],
        "precision": 0,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 6, "y": 0, "width": 2, "height": 2}
    },
    {
      "definition": {
        "type": "query_value",
        "title": "Diligence Events",
        "requests": [{
          "q": "sum:runtime.diligence.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value}.as_count()",
          "aggregator": "sum"
        }],
        "precision": 0,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 8, "y": 0, "width": 2, "height": 2}
    },
    {
      "definition": {
        "type": "query_value",
        "title": "Features Tracked",
        "requests": [{
          "q": "sum:runtime.diligence.features.tracked{demo-run-id:$demo_run_id.value}.as_count()",
          "aggregator": "sum"
        }],
        "precision": 0,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 10, "y": 0, "width": 2, "height": 2}
    },
    {
      "definition": {
        "type": "note",
        "content": "## B — Delivery Flow\n`runtime.event.received`",
        "background_color": "green",
        "font_size": "12",
        "text_align": "left",
        "show_tick": false
      },
      "layout": {"x": 0, "y": 3, "width": 12, "height": 1}
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "B1 — Delivery Event Stream",
        "requests": [{
          "q": "sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {event}.as_count()",
          "display_type": "bars",
          "style": {"palette": "dog_classic"}
        }],
        "show_legend": true,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 0, "y": 4, "width": 12, "height": 3}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "B2 — Current Delivery State by Issue",
        "requests": [{
          "q": "top(sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,state}.as_count(), 25, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 0, "y": 7, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "B3 — Last Delivery Event by Issue",
        "requests": [{
          "q": "top(sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,event}.as_count(), 25, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 4, "y": 7, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "B4 — State Transitions over Time",
        "requests": [{
          "q": "sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {state}.as_count()",
          "display_type": "bars",
          "style": {"palette": "cool"}
        }],
        "show_legend": true,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 8, "y": 7, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "note",
        "content": "## C — Diligence Tracking\n`runtime.diligence.event.received` · `runtime.diligence.features.tracked`",
        "background_color": "purple",
        "font_size": "12",
        "text_align": "left",
        "show_tick": false
      },
      "layout": {"x": 0, "y": 10, "width": 12, "height": 1}
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "C1 — Diligence Event Stream",
        "requests": [{
          "q": "sum:runtime.diligence.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {event}.as_count()",
          "display_type": "bars",
          "style": {"palette": "purple"}
        }],
        "show_legend": true,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 0, "y": 11, "width": 8, "height": 3}
    },
    {
      "definition": {
        "type": "query_value",
        "title": "C4 — Features In Sync",
        "requests": [{
          "q": "sum:runtime.diligence.features.tracked{demo-run-id:$demo_run_id.value}.as_count()",
          "aggregator": "sum"
        }],
        "precision": 0,
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 8, "y": 11, "width": 4, "height": 2}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "C2 — Diligence Status by Issue",
        "requests": [{
          "q": "top(sum:runtime.diligence.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,diligence-status}.as_count(), 20, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 0, "y": 14, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "C3 — Delivery State × Diligence Status",
        "requests": [{
          "q": "top(sum:runtime.diligence.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,delivery-state,diligence-status}.as_count(), 20, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 4, "y": 14, "width": 8, "height": 3}
    },
    {
      "definition": {
        "type": "note",
        "content": "## D — Correlation and Evidence\nDelivery ↔ Diligence cross-reference via `delivery-correlation-id` and `diligence-correlation-id`",
        "background_color": "orange",
        "font_size": "12",
        "text_align": "left",
        "show_tick": false
      },
      "layout": {"x": 0, "y": 17, "width": 12, "height": 1}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "D1 — Delivery Correlation IDs",
        "requests": [{
          "q": "top(sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,delivery-correlation-id}.as_count(), 10, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 0, "y": 18, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "D2 — Diligence Correlation IDs",
        "requests": [{
          "q": "top(sum:runtime.diligence.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,diligence-correlation-id}.as_count(), 10, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 4, "y": 18, "width": 4, "height": 3}
    },
    {
      "definition": {
        "type": "toplist",
        "title": "D4 — Delivery Events by Issue",
        "requests": [{
          "q": "top(sum:runtime.event.received{issue:$issue.value,demo-run-id:$demo_run_id.value} by {issue,journey}.as_count(), 10, '\''sum'\'', '\''desc'\'')"
        }],
        "time": {"live_span": "30m"}
      },
      "layout": {"x": 8, "y": 18, "width": 4, "height": 3}
    }
  ]
}')

# Remove JS-style comments from the JSON (jq already outputs clean JSON)
DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | jq '.')

DEF_FILE="$PRODOPS_DIR/artifacts/runtime/datadog-demo-dashboard-definition.json"
echo "$DASHBOARD_JSON" > "$DEF_FILE"
log "Dashboard definition saved: $DEF_FILE"

if [[ -z "${DD_API_KEY:-}" ]]; then
  log "ERROR: DD_API_KEY not set"
  exit 1
fi
if [[ -z "${DD_APP_KEY:-}" ]]; then
  log "ERROR: DD_APP_KEY not set (required for dashboard creation)"
  exit 1
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
  DASH_ID=$(echo "$HTTP_BODY" | jq -r '.id // empty')
  DASH_URL=$(echo "$HTTP_BODY" | jq -r '.url // empty')
  log "Dashboard created — ID: ${DASH_ID}"
  echo "$HTTP_BODY" > "$PRODOPS_DIR/artifacts/runtime/datadog-demo-dashboard-response.json"

  # Save sanitized metadata
  echo "$HTTP_BODY" | jq '{
    id: .id,
    title: .title,
    url: .url,
    created_at: .created_at,
    widget_count: (.widgets | length),
    template_variable_count: (.template_variables | length)
  }' > "$PRODOPS_DIR/artifacts/runtime/datadog-demo-dashboard-metadata.json"

  echo ""
  echo "  Dashboard created successfully!"
  echo "  ID:  ${DASH_ID}"
  echo "  URL: https://app.${DD_SITE}${DASH_URL}"
  echo ""
else
  log "ERROR: Datadog API returned HTTP ${HTTP_STATUS}"
  log "Body: $HTTP_BODY"
  echo ""
  echo "  Definition saved to: $DEF_FILE"
  exit 1
fi
