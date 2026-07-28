#!/usr/bin/env bash
# Event Producer — emits a CloudEvents 1.0 compliant event from the Event Catalog
# Usage: emit.sh --issue <id> --event <logical-name> --correlation-id <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
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

ISSUE=""
EVENT=""
CORRELATION_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)          ISSUE="$2"; shift 2 ;;
    --event)          EVENT="$2"; shift 2 ;;
    --correlation-id) CORRELATION_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ISSUE" ]]          && { echo "Error: --issue required" >&2; exit 1; }
[[ -z "$EVENT" ]]          && { echo "Error: --event required" >&2; exit 1; }
[[ -z "$CORRELATION_ID" ]] && { echo "Error: --correlation-id required" >&2; exit 1; }

# Verify event exists in catalog
if ! python3 - "$CATALOG" "$EVENT" <<'PYEOF' 2>/dev/null; then
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
assert sys.argv[2] in data['events'], f"Event not in catalog: {sys.argv[2]}"
PYEOF
  echo "Error: event '$EVENT' not found in catalog. See: $CATALOG" >&2
  exit 1
fi

# CloudEvents envelope fields
CE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
CE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CE_SPECVERSION=$(yaml_get "cloud-events.specversion")
CE_SOURCE=$(yaml_get "cloud-events.source")
CE_DATACONTENTTYPE=$(yaml_get "cloud-events.datacontenttype")
CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")
CE_DATASCHEMA=$(catalog_get "$EVENT" "data-schema")

# ProdOps payload (goes into CloudEvent data)
RUNTIME_VERSION=$(yaml_get "runtime-version")
FRAMEWORK_VERSION=$(yaml_get "framework-version")
SCHEMA_VERSION=$(yaml_get "schema-version")
JOURNEY=$(catalog_get "$EVENT" "journey")
CYCLE=$(catalog_get "$EVENT" "cycle")
PHASE=$(catalog_get "$EVENT" "phase")
ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")
NEW_STATE=$(catalog_get "$EVENT" "new-state")

CE_JSON=$(jq -n \
  --arg specversion        "$CE_SPECVERSION" \
  --arg id                 "$CE_ID" \
  --arg source             "$CE_SOURCE" \
  --arg type               "$CE_TYPE" \
  --arg subject            "$ISSUE" \
  --arg time               "$CE_TIME" \
  --arg datacontenttype    "$CE_DATACONTENTTYPE" \
  --arg dataschema         "$CE_DATASCHEMA" \
  --arg issue              "$ISSUE" \
  --arg journey            "$JOURNEY" \
  --arg cycle              "$CYCLE" \
  --arg phase              "$PHASE" \
  --argjson alters_state   "$ALTERS_STATE" \
  --arg new_state          "$NEW_STATE" \
  --arg correlation_id     "$CORRELATION_ID" \
  --arg runtime_version    "$RUNTIME_VERSION" \
  --arg framework_version  "$FRAMEWORK_VERSION" \
  --arg schema_version     "$SCHEMA_VERSION" \
  '{
    "specversion":     $specversion,
    "id":              $id,
    "source":          $source,
    "type":            $type,
    "subject":         $subject,
    "time":            $time,
    "datacontenttype": $datacontenttype,
    "dataschema":      $dataschema,
    "data": {
      "issue":                  $issue,
      "journey":                $journey,
      "cycle":                  $cycle,
      "phase":                  $phase,
      "alters-state":           $alters_state,
      "new-state":              $new_state,
      "runtime-correlation-id": $correlation_id,
      "runtime-version":        $runtime_version,
      "framework-version":      $framework_version,
      "schema-version":         $schema_version
    }
  }')

# Validate before outputting — no invalid event leaves the producer
if ! bash "$RUNTIME_DIR/scripts/validate-event.sh" --event-json "$CE_JSON" >&2; then
  echo "Error: produced invalid CloudEvent" >&2
  exit 1
fi

echo "$CE_JSON"
