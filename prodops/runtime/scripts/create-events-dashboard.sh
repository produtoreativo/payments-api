#!/usr/bin/env bash
# Creates the ProdOps Events Dashboard in Datadog via the Dashboards API.
# Reads credentials from $DD_API_KEY / $DD_APP_KEY env vars or api/.env fallback.
# Writes response to prodops/artifacts/runtime/datadog-events-dashboard-response.json
# and metadata to prodops/artifacts/runtime/datadog-events-dashboard-metadata.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$RUNTIME_DIR/.." && pwd)"
DEFINITION="$PRODOPS_DIR/artifacts/runtime/datadog-events-dashboard-definition.json"
RESPONSE_FILE="$PRODOPS_DIR/artifacts/runtime/datadog-events-dashboard-response.json"
METADATA_FILE="$PRODOPS_DIR/artifacts/runtime/datadog-events-dashboard-metadata.json"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"; }

# ── Credentials ───────────────────────────────────────────────────────────────
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

[[ -z "${DD_API_KEY:-}" ]] && { log "ERROR: DD_API_KEY not set"; exit 1; }
[[ -z "${DD_APP_KEY:-}" ]] && { log "ERROR: DD_APP_KEY not set (required for Dashboards API)"; exit 1; }
[[ ! -f "$DEFINITION" ]]   && { log "ERROR: definition not found at $DEFINITION"; exit 1; }

log "Creating dashboard — $(jq -r '.title' "$DEFINITION")"
log "Endpoint: https://api.${DD_SITE}/api/v1/dashboard"

HTTP_STATUS=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" \
  -X POST "https://api.${DD_SITE}/api/v1/dashboard" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d @"$DEFINITION")

if [[ "$HTTP_STATUS" != "200" ]]; then
  log "ERROR: Datadog returned HTTP ${HTTP_STATUS}"
  jq . "$RESPONSE_FILE" 2>/dev/null || cat "$RESPONSE_FILE"
  exit 1
fi

log "Dashboard created — HTTP ${HTTP_STATUS}"

# ── Extract metadata ──────────────────────────────────────────────────────────
jq '{
  id:           .id,
  title:        .title,
  url:          .url,
  created_at:   .created_at,
  widget_count: (.widgets | length),
  template_variable_count: (.template_variables | length)
}' "$RESPONSE_FILE" > "$METADATA_FILE"

DASH_ID=$(jq -r '.id' "$METADATA_FILE")
DASH_URL=$(jq -r '.url' "$METADATA_FILE")

log "ID:    $DASH_ID"
log "URL:   https://app.${DD_SITE}${DASH_URL}"
log "Metadata saved → $METADATA_FILE"
log "Response saved → $RESPONSE_FILE"
