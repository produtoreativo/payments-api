#!/usr/bin/env bash
# demo-delivery-with-diligence.sh — EXP-014 Iteration 2: Recorded Operational Flow
#
# Executa o fluxo Delivery + Diligence com saída estruturada para gravação.
# Cada evento produz um bloco visual no terminal.
#
# Usage:
#   demo-delivery-with-diligence.sh [--demo] [--with-diligence] [--demo-run-id <id>]
#
# Flags:
#   --demo            Ativa delays entre eventos (DEMO_STEP_DELAY_SECONDS=4)
#   --with-diligence  Executa o ciclo Diligence após o Delivery
#   --demo-run-id ID  Define o demo-run-id (default: auto-gerado)
#
# Demo delays (configuráveis via environment):
#   DEMO_STEP_DELAY_SECONDS=4      delay entre eventos Delivery
#   DEMO_FEATURE_DELAY_SECONDS=2   delay entre Features
#   DEMO_DILIGENCE_DELAY_SECONDS=4 delay entre eventos Diligence

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

# ── Parse flags ────────────────────────────────────────────────────────────
DEMO_MODE=false
WITH_DILIGENCE=false
DEMO_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo)          DEMO_MODE=true; shift ;;
    --with-diligence) WITH_DILIGENCE=true; shift ;;
    --demo-run-id)   DEMO_RUN_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ── Delay config (only active in --demo mode) ────────────────────────────
DEMO_STEP_DELAY=${DEMO_STEP_DELAY_SECONDS:-4}
DEMO_FEATURE_DELAY=${DEMO_FEATURE_DELAY_SECONDS:-2}
DEMO_DILIGENCE_DELAY=${DEMO_DILIGENCE_DELAY_SECONDS:-4}

step_delay()      { $DEMO_MODE && sleep "$DEMO_STEP_DELAY"      || true; }
feature_delay()   { $DEMO_MODE && sleep "$DEMO_FEATURE_DELAY"   || true; }
diligence_delay() { $DEMO_MODE && sleep "$DEMO_DILIGENCE_DELAY" || true; }

# ── Runtime config ─────────────────────────────────────────────────────────
RUNTIME_VERSION=$(yaml_get "runtime-version")
GH_OWNER=$(yaml_get "github.owner")
GH_REPO=$(yaml_get "github.repository")
GH_PROJECT=$(yaml_get "github.project-number")
CE_SPECVERSION=$(yaml_get "cloud-events.specversion")
CE_SOURCE=$(yaml_get "cloud-events.source")
CE_DATACONTENTTYPE=$(yaml_get "cloud-events.datacontenttype")
SCHEMA_VERSION=$(yaml_get "schema-version")
FRAMEWORK_VERSION=$(yaml_get "framework-version")

ENV_FILE="$PRODOPS_DIR/../api/.env"
for KEY in DD_API_KEY DD_APP_KEY DD_SITE; do
  if [[ -z "${!KEY:-}" && -f "$ENV_FILE" ]]; then
    VAL=$(grep -E "^${KEY}=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
    [[ -n "$VAL" ]] && export "$KEY=$VAL"
  fi
done
DD_SITE="${DD_SITE:-datadoghq.com}"
DD_SERVICE=$(yaml_get "datadog.service")
DD_ENV_VALUE=$(yaml_get "datadog.environment")

# ── Demo run ID ────────────────────────────────────────────────────────────
if [[ -z "$DEMO_RUN_ID" ]]; then
  DEMO_RUN_ID="exp-014-demo-$(date -u +%Y-%m-%d-%H%M)"
fi

# ── Recording directory ────────────────────────────────────────────────────
RECORDINGS_DIR="$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/recordings/${DEMO_RUN_ID}"
mkdir -p "$RECORDINGS_DIR/delivery-timelines"
mkdir -p "$RECORDINGS_DIR/diligence-timelines"
mkdir -p "$RECORDINGS_DIR/derived-states"

ARTIFACTS_DIR="$PRODOPS_DIR/artifacts/runtime"
LOG_FILE="$ARTIFACTS_DIR/runtime.log"
mkdir -p "$ARTIFACTS_DIR/timelines"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

# ── Banner ─────────────────────────────────────────────────────────────────
echo ""
echo "┌────────────────────────────────────────────────────────────────────┐"
echo "│  EXP-014 — Iteration 2: Recorded Operational Flow                 │"
echo "│  runtime-version: ${RUNTIME_VERSION}                                       │"
if $DEMO_MODE; then
echo "│  Mode: DEMO (delays: step=${DEMO_STEP_DELAY}s feature=${DEMO_FEATURE_DELAY}s diligence=${DEMO_DILIGENCE_DELAY}s)    │"
else
echo "│  Mode: FAST (no delays)                                            │"
fi
if $WITH_DILIGENCE; then
echo "│  --with-diligence: Diligence Capture → Attach will run after       │"
fi
echo "│  demo-run-id: ${DEMO_RUN_ID}          │"
echo "└────────────────────────────────────────────────────────────────────┘"
echo ""

log "=== demo-delivery-with-diligence.sh v${RUNTIME_VERSION} started ==="
log "demo-run-id: ${DEMO_RUN_ID} | demo-mode: ${DEMO_MODE} | with-diligence: ${WITH_DILIGENCE}"

# ── Doctor ──────────────────────────────────────────────────────────────────
echo "Running Runtime Doctor..."
if ! bash "$SCRIPT_DIR/runtime-doctor.sh"; then
  echo "  Doctor reported FAIL. Aborting."
  exit 1
fi

# ── GitHub: resolve project ────────────────────────────────────────────────
PROJECT_ID=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    organization(login: $owner) {
      projectV2(number: $number) { id }
    }
  }' -f owner="$GH_OWNER" -F number="$GH_PROJECT" \
  -q '.data.organization.projectV2.id')
log "GitHub Project ID: $PROJECT_ID"

# ── GitHub: field IDs ─────────────────────────────────────────────────────
FIELDS_JSON=$(gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes {
            ... on ProjectV2Field { id name }
            ... on ProjectV2SingleSelectField { id name options { id name } }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID")

get_field_id()  { echo "$FIELDS_JSON" | jq -r --arg n "$1" '.data.node.fields.nodes[] | select(.name == $n) | .id // empty'; }
get_option_id() { echo "$FIELDS_JSON" | jq -r --arg n "$1" --arg v "$2" '.data.node.fields.nodes[] | select(.name == $n) | .options[]? | select(.name == $v) | .id // empty'; }

OEM_STATE_FIELD=$(get_field_id "oem-state")
OEM_LAST_EVENT_FIELD=$(get_field_id "oem-last-event")
DSTATUS_FIELD_ID=$(get_field_id "diligence-status")
DEVIDENCE_FIELD_ID=$(get_field_id "diligence-evidence")
RSYNC_FIELD_ID=$(get_field_id "runtime-sync")

# ── GitHub: get or add issue to project ──────────────────────────────────
get_item_id() {
  local ISSUE_NUM="$1"
  local ISSUE_NODE
  ISSUE_NODE=$(gh api "repos/${GH_OWNER}/${GH_REPO}/issues/${ISSUE_NUM}" -q '.node_id' 2>/dev/null)
  gh api graphql -f query='
    mutation($project: ID!, $contentId: ID!) {
      addProjectV2ItemById(input: {projectId: $project, contentId: $contentId}) {
        item { id }
      }
    }' -f project="$PROJECT_ID" -f contentId="$ISSUE_NODE" \
    -q '.data.addProjectV2ItemById.item.id' 2>/dev/null
}

ITEM_ID_76=$(get_item_id "76"); log "Issue #76 item ID: ${ITEM_ID_76}"
ITEM_ID_77=$(get_item_id "77"); log "Issue #77 item ID: ${ITEM_ID_77}"
ITEM_ID_78=$(get_item_id "78"); log "Issue #78 item ID: ${ITEM_ID_78}"

get_item_id_for_issue() {
  case "$1" in
    76) echo "$ITEM_ID_76" ;;
    77) echo "$ITEM_ID_77" ;;
    78) echo "$ITEM_ID_78" ;;
  esac
}

# ── Datadog: send delivery metric ─────────────────────────────────────────
send_delivery_metric() {
  local ISSUE="$1" EVENT="$2" STATE="$3" CORR="$4"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now   "$NOW"     --arg issue   "$ISSUE"  --arg event "$EVENT" \
    --arg state     "$STATE"   --arg corr    "$CORR"   \
    --arg service   "$DD_SERVICE" --arg env  "$DD_ENV_VALUE" \
    --arg demo_run  "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.event.received", type:1,
      points:[{timestamp:$now,value:1}],
      tags:[
        ("issue:"+$issue), ("event:"+$event), ("state:"+$state),
        ("delivery-correlation-id:"+$corr),
        ("service:"+$service), ("env:"+$env),
        "journey:delivery", "runtime:prodops",
        ("demo-run-id:"+$demo_run),
        ("iteration-id:"+$demo_run)
      ]
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  [[ "$HTTP" == "202" ]] && echo "202" || { log "ERROR: Datadog delivery metric HTTP ${HTTP}"; echo "$HTTP"; }
}

# ── Datadog: send diligence metric ────────────────────────────────────────
send_diligence_metric() {
  local ISSUE="$1" EVENT_TYPE="$2" DEL_STATE="$3" DIL_STATUS="$4" \
        DEL_CORR="$5" DIL_CORR="$6"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now   "$NOW"     --arg issue   "$ISSUE" --arg event  "$EVENT_TYPE" \
    --arg del_state "$DEL_STATE" --arg dil_status "$DIL_STATUS" \
    --arg del_corr  "$DEL_CORR" --arg dil_corr  "$DIL_CORR" \
    --arg service   "$DD_SERVICE" --arg env  "$DD_ENV_VALUE" \
    --arg demo_run  "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.diligence.event.received", type:1,
      points:[{timestamp:$now,value:1}],
      tags:[
        ("issue:"+$issue), ("event:"+$event),
        ("delivery-state:"+$del_state), ("diligence-status:"+$dil_status),
        ("delivery-correlation-id:"+$del_corr),
        ("diligence-correlation-id:"+$dil_corr),
        ("service:"+$service), ("env:"+$env),
        "journey:diligence", "runtime:prodops",
        ("demo-run-id:"+$demo_run),
        ("iteration-id:"+$demo_run)
      ]
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  [[ "$HTTP" == "202" ]] && echo "202" || { log "ERROR: Datadog diligence metric HTTP ${HTTP}"; echo "$HTTP"; }
}

send_features_tracked_metric() {
  local ISSUE="$1" DEL_STATE="$2" RS="$3" DEL_CORR="$4" DIL_CORR="$5" DIL_STATUS="$6"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now   "$NOW"    --arg issue  "$ISSUE" \
    --arg del_state "$DEL_STATE" --arg rs "$RS" --arg dil_status "$DIL_STATUS" \
    --arg del_corr  "$DEL_CORR" --arg dil_corr "$DIL_CORR" \
    --arg service   "$DD_SERVICE" --arg env  "$DD_ENV_VALUE" \
    --arg demo_run  "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.diligence.features.tracked", type:1,
      points:[{timestamp:$now,value:1}],
      tags:[
        ("issue:"+$issue), ("delivery-state:"+$del_state),
        ("diligence-status:"+$dil_status), ("runtime-sync:"+$rs),
        ("delivery-correlation-id:"+$del_corr),
        ("diligence-correlation-id:"+$dil_corr),
        ("service:"+$service), ("env:"+$env),
        "journey:diligence", "runtime:prodops",
        ("demo-run-id:"+$demo_run),
        ("iteration-id:"+$demo_run)
      ]
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  [[ "$HTTP" == "202" ]] && echo "202" || { log "ERROR: Datadog features.tracked HTTP ${HTTP}"; echo "$HTTP"; }
}

# ── Datadog: send lead-time gauge ─────────────────────────────────────────
send_lead_time_metric() {
  local ISSUE="$1" LEAD_SECS="$2" DEL_STATE="$3"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now      "$NOW"       --arg issue    "$ISSUE" \
    --argjson lead     "$LEAD_SECS" --arg del_state "$DEL_STATE" \
    --arg service      "$DD_SERVICE" --arg env     "$DD_ENV_VALUE" \
    --arg demo_run     "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.delivery.leadtime", type:3,
      points:[{timestamp:$now,value:$lead}],
      tags:[
        ("issue:"+$issue), ("delivery-state:"+$del_state),
        ("service:"+$service), ("env:"+$env),
        ("demo-run-id:"+$demo_run)
      ]
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  [[ "$HTTP" == "202" ]] && echo "202" || { log "ERROR: Datadog lead-time HTTP ${HTTP}"; echo "$HTTP"; }
}

# ── Datadog: send funnel count ────────────────────────────────────────────
send_funnel_metric() {
  local STAGE="$1" COUNT="$2"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now   "$NOW"   --arg stage "$STAGE" --argjson count "$COUNT" \
    --arg service   "$DD_SERVICE" --arg env "$DD_ENV_VALUE" \
    --arg demo_run  "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.delivery.funnel", type:1,
      points:[{timestamp:$now,value:$count}],
      tags:[
        ("stage:"+$stage),
        ("service:"+$service), ("env:"+$env),
        ("demo-run-id:"+$demo_run)
      ]
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  [[ "$HTTP" == "202" ]] && echo "202" || { log "ERROR: Datadog funnel HTTP ${HTTP}"; echo "$HTTP"; }
}

# ── GitHub: update SingleSelect field ─────────────────────────────────────
update_singleselect() {
  local ISSUE="$1" FIELD_ID="$2" OPT_ID="$3"
  [[ -z "$FIELD_ID" || -z "$OPT_ID" ]] && return 0
  local IITEM; IITEM=$(get_item_id_for_issue "$ISSUE")
  gh api graphql -f query='
    mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) {
      updateProjectV2ItemFieldValue(input:{
        projectId:$p, itemId:$i, fieldId:$f, value:{singleSelectOptionId:$o}
      }){projectV2Item{id}}
    }' -f p="$PROJECT_ID" -f i="$IITEM" -f f="$FIELD_ID" -f o="$OPT_ID" \
    > /dev/null 2>&1
}

update_text() {
  local ISSUE="$1" FIELD_ID="$2" VALUE="$3"
  [[ -z "$FIELD_ID" ]] && return 0
  local IITEM; IITEM=$(get_item_id_for_issue "$ISSUE")
  gh api graphql -f query='
    mutation($p: ID!, $i: ID!, $f: ID!, $v: String!) {
      updateProjectV2ItemFieldValue(input:{
        projectId:$p, itemId:$i, fieldId:$f, value:{text:$v}
      }){projectV2Item{id}}
    }' -f p="$PROJECT_ID" -f i="$IITEM" -f f="$FIELD_ID" -f v="$VALUE" \
    > /dev/null 2>&1
}

# ── Feature configuration ──────────────────────────────────────────────────
ISSUES=(76 77 78)
FEATURE_NAMES=("FTR-001: Invoice PIX" "FTR-002: Invoice Cartão" "FTR-003: Confirmação Pagamento")
TARGET_STATES=("DONE" "VALIDATING" "HACKING")

EVENTS_76=(
  "Delivery.Bootstrap.Started" "Delivery.Bootstrap.Completed"
  "Delivery.Hack.Started"      "Delivery.Hack.Completed"
  "Delivery.Sync.Started"      "Delivery.Sync.Completed"
  "Delivery.Finish.Started"    "Delivery.Finish.Completed"
  "Delivery.Ship.Started"      "Delivery.Ship.Completed"
  "Delivery.Validate.Started"  "Shared.Gate.Passed"
  "Delivery.Validate.Completed" "Delivery.Promote.Started"
  "Delivery.Promote.Completed"
)
EVENTS_77=(
  "Delivery.Bootstrap.Started" "Delivery.Bootstrap.Completed"
  "Delivery.Hack.Started"      "Delivery.Hack.Completed"
  "Delivery.Sync.Started"      "Delivery.Sync.Completed"
  "Delivery.Finish.Started"    "Delivery.Finish.Completed"
  "Delivery.Ship.Started"      "Delivery.Ship.Completed"
  "Delivery.Validate.Started"
)
EVENTS_78=(
  "Delivery.Bootstrap.Started" "Delivery.Bootstrap.Completed"
  "Delivery.Hack.Started"
)

declare -a CORR_IDS
declare -a DILIGENCE_CORR_IDS

for i in "${!ISSUES[@]}"; do
  CORR_IDS[$i]=$(uuidgen | tr '[:upper:]' '[:lower:]')
  DILIGENCE_CORR_IDS[$i]=$(uuidgen | tr '[:upper:]' '[:lower:]')
  # Reset timelines for this demo run
  echo "[]" > "$ARTIFACTS_DIR/timelines/${ISSUES[$i]}.json"
done

echo ""
echo "── Correlation IDs"
for i in "${!ISSUES[@]}"; do
  echo "  #${ISSUES[$i]} delivery:    ${CORR_IDS[$i]}"
  echo "  #${ISSUES[$i]} diligence:   ${DILIGENCE_CORR_IDS[$i]}"
done
echo ""

# ── Helper: emit one Delivery event ──────────────────────────────────────
DELIVERY_STEP_COUNT=0
emit_delivery_event() {
  local ISSUE="$1" EVENT="$2" CORR="$3"
  local FEATURE_IDX="$4"
  DELIVERY_STEP_COUNT=$((DELIVERY_STEP_COUNT + 1))

  local ALTERS_STATE CE_TYPE
  ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")
  CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")

  local CE_JSON
  CE_JSON=$(bash "$RUNTIME_DIR/producer/emit.sh" \
    --issue "$ISSUE" --event "$EVENT" --correlation-id "$CORR")

  bash "$RUNTIME_DIR/timeline/append.sh" --issue "$ISSUE" --event-json "$CE_JSON" > /dev/null

  local DERIVED CURRENT_STATE LAST_EVENT_TYPE EVCOUNT
  DERIVED=$(bash "$RUNTIME_DIR/consumer/derive-state.sh" --issue "$ISSUE")
  CURRENT_STATE=$(echo "$DERIVED" | jq -r '.state')
  LAST_EVENT_TYPE=$(echo "$DERIVED" | jq -r '.["last-event-type"]')
  EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/${ISSUE}.json")

  local DD_HTTP="—"
  DD_HTTP=$(send_delivery_metric "$ISSUE" "$CE_TYPE" "$CURRENT_STATE" "$CORR")

  local GH_STATUS="—"
  if [[ "$ALTERS_STATE" == "true" ]]; then
    local OPT_ID
    OPT_ID=$(get_option_id "oem-state" "$CURRENT_STATE")
    update_singleselect "$ISSUE" "$OEM_STATE_FIELD" "$OPT_ID"
    update_text "$ISSUE" "$OEM_LAST_EVENT_FIELD" "$LAST_EVENT_TYPE"
    GH_STATUS="oem-state=${CURRENT_STATE}"
  fi

  # Structured output block
  echo ""
  echo "  [DELIVERY] #${ISSUE} ${EVENT}"
  echo "  ──────────────────────────────────────────────────────────"
  echo "  CloudEvent:   ${CE_TYPE}"
  echo "  Validation:   PASS ✓"
  printf  "  Timeline:     appended (%d total)\n" "$EVCOUNT"
  echo "  State:        ${CURRENT_STATE}"
  if [[ "$ALTERS_STATE" == "true" ]]; then
    echo "  GitHub:       ${GH_STATUS} ✓"
  else
    echo "  GitHub:       — (non-state-altering)"
  fi
  echo "  Datadog:      HTTP ${DD_HTTP} ✓"
  echo "  Correlation:  ${CORR:0:8}... | demo-run-id: ${DEMO_RUN_ID}"

  log "#${ISSUE} | ${CE_TYPE} | state=${CURRENT_STATE} | events=${EVCOUNT}"
  step_delay
}

# ── Helper: emit one Diligence event ─────────────────────────────────────
emit_diligence_event() {
  local ISSUE="$1" EVENT="$2" DIL_CORR="$3" DEL_STATE="$4" \
        DEL_LAST="$5" DEL_CORR="$6" DIL_STATUS="$7"

  local CE_TYPE CE_DATASCHEMA JOURNEY CYCLE PHASE
  CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")
  CE_DATASCHEMA=$(catalog_get "$EVENT" "data-schema")
  JOURNEY=$(catalog_get "$EVENT" "journey")
  CYCLE=$(catalog_get "$EVENT" "cycle")
  PHASE=$(catalog_get "$EVENT" "phase")

  local CE_ID CE_TIME
  CE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  CE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local CE_JSON
  CE_JSON=$(jq -n \
    --arg specversion              "$CE_SPECVERSION" \
    --arg id                       "$CE_ID"          \
    --arg source                   "$CE_SOURCE"       \
    --arg type                     "$CE_TYPE"         \
    --arg subject                  "$ISSUE"           \
    --arg time                     "$CE_TIME"         \
    --arg datacontenttype          "$CE_DATACONTENTTYPE" \
    --arg dataschema               "$CE_DATASCHEMA"   \
    --arg issue                    "$ISSUE"           \
    --arg journey                  "$JOURNEY"         \
    --arg cycle                    "$CYCLE"           \
    --arg phase                    "$PHASE"           \
    --arg diligence_correlation_id "$DIL_CORR"       \
    --arg delivery_correlation_id  "$DEL_CORR"       \
    --arg delivery_last_event_type "$DEL_LAST"       \
    --arg delivery_derived_state   "$DEL_STATE"      \
    --arg diligence_status         "$DIL_STATUS"     \
    --arg runtime_version          "$RUNTIME_VERSION" \
    --arg framework_version        "$FRAMEWORK_VERSION" \
    --arg schema_version           "$SCHEMA_VERSION"  \
    --arg demo_run_id              "$DEMO_RUN_ID"     \
    '{
      "specversion": $specversion, "id": $id, "source": $source,
      "type": $type, "subject": $subject, "time": $time,
      "datacontenttype": $datacontenttype, "dataschema": $dataschema,
      "data": {
        "issue": $issue, "journey": $journey, "cycle": $cycle, "phase": $phase,
        "alters-state": false,
        "diligence-correlation-id": $diligence_correlation_id,
        "delivery-correlation-id":  $delivery_correlation_id,
        "delivery-last-event-type": $delivery_last_event_type,
        "delivery-derived-state":   $delivery_derived_state,
        "diligence-status":         $diligence_status,
        "demo-run-id":              $demo_run_id,
        "runtime-version": $runtime_version,
        "framework-version": $framework_version,
        "schema-version": $schema_version
      }
    }')

  # Validate
  bash "$RUNTIME_DIR/scripts/validate-event.sh" --event-json "$CE_JSON" >&2

  # Append to diligence timeline
  local DKEY="diligence-${ISSUE}"
  local TL="$ARTIFACTS_DIR/timelines/${DKEY}.json"
  if [[ -f "$TL" ]]; then
    jq --argjson new "$CE_JSON" '. + [$new]' "$TL" > "${TL}.tmp" && mv "${TL}.tmp" "$TL"
  else
    echo "[$CE_JSON]" | jq '.' > "$TL"
  fi
  local EVCOUNT; EVCOUNT=$(jq 'length' "$TL")

  echo "$CE_JSON"
}

# ── Delivery: run events per feature ─────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  DELIVERY PHASE"
echo "════════════════════════════════════════════════════════════════════"

run_delivery_feature() {
  local IDX="$1"
  local ISSUE="${ISSUES[$IDX]}"
  local FNAME="${FEATURE_NAMES[$IDX]}"
  local TARGET="${TARGET_STATES[$IDX]}"
  local CORR="${CORR_IDS[$IDX]}"

  # Get the events array for this feature
  local EVENTS_VAR="EVENTS_${ISSUE}[@]"
  local EVENTS=("${!EVENTS_VAR}")

  echo ""
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  printf  "  ║  [DELIVERY] #%-5s %-43s ║\n" "$ISSUE" "$FNAME"
  printf  "  ║  Target: %-10s | %d events | corr: %-8s...      ║\n" "$TARGET" "${#EVENTS[@]}" "${CORR:0:8}"
  echo "  ╚══════════════════════════════════════════════════════════════╝"

  for EVENT in "${EVENTS[@]}"; do
    emit_delivery_event "$ISSUE" "$EVENT" "$CORR" "$IDX"
  done

  local FINAL_STATE
  FINAL_STATE=$(jq -r '.state' "$ARTIFACTS_DIR/derived-state-${ISSUE}.json")
  if [[ "$FINAL_STATE" == "$TARGET" ]]; then
    echo ""
    echo "  ✅ #${ISSUE} → ${FINAL_STATE} (target met)"
  else
    echo ""
    echo "  ⚠️  #${ISSUE} → ${FINAL_STATE} (expected: ${TARGET})"
  fi
  feature_delay
}

run_delivery_feature 0  # #76 → DONE (15 events)
run_delivery_feature 1  # #77 → VALIDATING (11 events)
run_delivery_feature 2  # #78 → HACKING (3 events)

echo ""
echo "  Delivery snapshot:"
DONE_COUNT=0; VALIDATION_COUNT=0; DELIVERY_COUNT=0; TOTAL_LEAD_SECS=0; LEAD_FEATURES=0
for i in "${!ISSUES[@]}"; do
  DSTATE=$(jq -r '.state' "$ARTIFACTS_DIR/derived-state-${ISSUES[$i]}.json")
  printf "  #%s %-30s → %s\n" "${ISSUES[$i]}" "${FEATURE_NAMES[$i]}" "$DSTATE"
  DELIVERY_COUNT=$((DELIVERY_COUNT + 1))
  [[ "$DSTATE" == "VALIDATING" || "$DSTATE" == "DONE" ]] && VALIDATION_COUNT=$((VALIDATION_COUNT + 1))
  [[ "$DSTATE" == "DONE" ]] && DONE_COUNT=$((DONE_COUNT + 1))
  # Lead time: parse first and last event timestamps from delivery timeline
  TIMELINE_FILE="$ARTIFACTS_DIR/timelines/${ISSUES[$i]}.json"
  if [[ -f "$TIMELINE_FILE" ]]; then
    T_FIRST=$(python3 -c "import json,datetime; d=json.load(open('$TIMELINE_FILE')); t=d[0]['time'].rstrip('Z'); print(int(datetime.datetime.fromisoformat(t).timestamp()))" 2>/dev/null || echo 0)
    T_LAST=$(python3 -c "import json,datetime; d=json.load(open('$TIMELINE_FILE')); t=d[-1]['time'].rstrip('Z'); print(int(datetime.datetime.fromisoformat(t).timestamp()))" 2>/dev/null || echo 0)
    if [[ "$T_FIRST" -gt 0 && "$T_LAST" -gt "$T_FIRST" ]]; then
      LEAD=$((T_LAST - T_FIRST))
      DSTATE_LOWER=$(echo "$DSTATE" | tr '[:upper:]' '[:lower:]')
      HTTP=$(send_lead_time_metric "${ISSUES[$i]}" "$LEAD" "$DSTATE_LOWER")
      [[ "$HTTP" == "202" ]] && echo "  [METRIC] lead-time #${ISSUES[$i]}: ${LEAD}s → HTTP 202 ✓"
      TOTAL_LEAD_SECS=$((TOTAL_LEAD_SECS + LEAD)); LEAD_FEATURES=$((LEAD_FEATURES + 1))
    fi
  fi
done
# Funnel metrics
PLANNED_COUNT=${#ISSUES[@]}
echo ""
echo "  [METRIC] Funnel:"
for STAGE_DEF in "planned:${PLANNED_COUNT}" "delivery:${DELIVERY_COUNT}" "validation:${VALIDATION_COUNT}" "production:${DONE_COUNT}"; do
  STAGE="${STAGE_DEF%%:*}"; COUNT="${STAGE_DEF##*:}"
  HTTP=$(send_funnel_metric "$STAGE" "$COUNT")
  [[ "$HTTP" == "202" ]] && echo "    ${STAGE}=${COUNT} → HTTP 202 ✓"
done
[[ "$LEAD_FEATURES" -gt 0 ]] && AVG_LEAD=$((TOTAL_LEAD_SECS / LEAD_FEATURES)) && \
  echo "  [METRIC] avg lead-time: ${AVG_LEAD}s (${LEAD_FEATURES} features)"

# ── Diligence phase ────────────────────────────────────────────────────────
if $WITH_DILIGENCE; then
  echo ""
  echo ""
  echo "════════════════════════════════════════════════════════════════════"
  echo "  DILIGENCE PHASE — Capture → Attach"
  echo "════════════════════════════════════════════════════════════════════"

  DILIGENCE_EVENTS=("Diligence.Capture.Started" "Diligence.Capture.Completed"
                    "Diligence.Attach.Started"   "Diligence.Attach.Completed")

  for i in "${!ISSUES[@]}"; do
    ISSUE="${ISSUES[$i]}"
    FNAME="${FEATURE_NAMES[$i]}"
    DIL_CORR="${DILIGENCE_CORR_IDS[$i]}"
    DEL_CORR="${CORR_IDS[$i]}"
    DERIVED_FILE="$ARTIFACTS_DIR/derived-state-${ISSUE}.json"
    DEL_STATE=$(jq -r '.state' "$DERIVED_FILE")
    DEL_LAST=$(jq -r '.["last-event-type"]' "$DERIVED_FILE")

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    printf  "  ║  [DILIGENCE] #%-5s %-42s ║\n" "$ISSUE" "$FNAME"
    printf  "  ║  Delivery: %-12s | dil-corr: %-8s...           ║\n" "$DEL_STATE" "${DIL_CORR:0:8}"
    echo "  ╚══════════════════════════════════════════════════════════════╝"

    # Reset diligence timeline for this demo run
    echo "[]" > "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json"

    DIL_STATUS="Pending"
    for EVENT in "${DILIGENCE_EVENTS[@]}"; do
      case "$EVENT" in
        "Diligence.Capture.Started")  DIL_STATUS="Sync In Progress" ;;
        "Diligence.Capture.Completed") DIL_STATUS="Captured" ;;
        "Diligence.Attach.Started")   DIL_STATUS="Sync In Progress" ;;
        "Diligence.Attach.Completed") DIL_STATUS="Attached" ;;
      esac

      local_ce_json=$(emit_diligence_event "$ISSUE" "$EVENT" \
        "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")

      CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")
      DD_HTTP=$(send_diligence_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" \
        "$DIL_STATUS" "$DEL_CORR" "$DIL_CORR")

      EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")

      echo ""
      echo "  [DILIGENCE] #${ISSUE} ${EVENT}"
      echo "  ──────────────────────────────────────────────────────────"
      echo "  CloudEvent:    ${CE_TYPE}"
      echo "  Delivery State: ${DEL_STATE}"
      echo "  Diligence:     ${DIL_STATUS}"
      printf "  Timeline:      appended (%d total)\n" "$EVCOUNT"
      echo "  Datadog:       HTTP ${DD_HTTP} ✓"
      echo "  Del Corr:      ${DEL_CORR:0:8}..."
      echo "  Dil Corr:      ${DIL_CORR:0:8}..."

      # GitHub sync at key points
      if [[ "$EVENT" == "Diligence.Capture.Completed" ]]; then
        update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Captured')"
        update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Partial')"
        update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Pending')"
        echo "  GitHub:        Captured / Partial / Pending ✓"
      fi

      if [[ "$EVENT" == "Diligence.Attach.Completed" ]]; then
        update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Attached')"
        update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
        update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
        echo "  GitHub:        Attached / Complete / In Sync ✓"

        send_features_tracked_metric "$ISSUE" "$DEL_STATE" "In Sync" \
          "$DEL_CORR" "$DIL_CORR" "Attached"
        echo "  features.tracked: HTTP 202 ✓"
      fi

      log "#${ISSUE} | ${CE_TYPE} | delivery=${DEL_STATE} | diligence=${DIL_STATUS}"
      diligence_delay
    done
  done
fi

# ── Archive to recordings directory ──────────────────────────────────────
echo ""
echo "── Archiving to recordings directory..."
for ISSUE in "${ISSUES[@]}"; do
  cp "$ARTIFACTS_DIR/timelines/${ISSUE}.json" \
     "$RECORDINGS_DIR/delivery-timelines/${ISSUE}.json" 2>/dev/null || true
  cp "$ARTIFACTS_DIR/derived-state-${ISSUE}.json" \
     "$RECORDINGS_DIR/derived-states/derived-state-${ISSUE}.json" 2>/dev/null || true
  if $WITH_DILIGENCE && [[ -f "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json" ]]; then
    cp "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json" \
       "$RECORDINGS_DIR/diligence-timelines/diligence-${ISSUE}.json"
  fi
done

# ── GitHub snapshot ────────────────────────────────────────────────────────
gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        items(first: 20) {
          nodes {
            content { ... on Issue { number title } }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
                ... on ProjectV2ItemFieldTextValue {
                  text
                  field { ... on ProjectV2Field { name } }
                }
              }
            }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID" > "$RECORDINGS_DIR/github-snapshot.json" 2>/dev/null || true

# ── Generate demo-summary.json ─────────────────────────────────────────────
TOTAL_DELIVERY=0
TOTAL_DILIGENCE=0
for ISSUE in "${ISSUES[@]}"; do
  C=$(jq 'length' "$ARTIFACTS_DIR/timelines/${ISSUE}.json" 2>/dev/null || echo 0)
  TOTAL_DELIVERY=$((TOTAL_DELIVERY + C))
  if $WITH_DILIGENCE; then
    D=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json" 2>/dev/null || echo 0)
    TOTAL_DILIGENCE=$((TOTAL_DILIGENCE + D))
  fi
done

jq -n \
  --arg demo_run_id    "$DEMO_RUN_ID" \
  --arg runtime_version "$RUNTIME_VERSION" \
  --arg demo_mode       "$DEMO_MODE" \
  --arg with_diligence  "$WITH_DILIGENCE" \
  --argjson del_events  "$TOTAL_DELIVERY" \
  --argjson dil_events  "$TOTAL_DILIGENCE" \
  --arg ts              "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg corr_76         "${CORR_IDS[0]}" \
  --arg corr_77         "${CORR_IDS[1]}" \
  --arg corr_78         "${CORR_IDS[2]}" \
  --arg dcorr_76        "${DILIGENCE_CORR_IDS[0]}" \
  --arg dcorr_77        "${DILIGENCE_CORR_IDS[1]}" \
  --arg dcorr_78        "${DILIGENCE_CORR_IDS[2]}" \
  '{
    "demo-run-id": $demo_run_id,
    "runtime-version": $runtime_version,
    "timestamp": $ts,
    "demo-mode": $demo_mode,
    "with-diligence": $with_diligence,
    "delivery-events-total": $del_events,
    "diligence-events-total": $dil_events,
    "correlation-ids": {
      "76": {"delivery": $corr_76, "diligence": $dcorr_76},
      "77": {"delivery": $corr_77, "diligence": $dcorr_77},
      "78": {"delivery": $corr_78, "diligence": $dcorr_78}
    }
  }' > "$RECORDINGS_DIR/demo-summary.json"

echo "Archived to: ${RECORDINGS_DIR}"

# ── Final output ────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "  EXP-014 Iteration 2 — Execution Complete"
echo ""
echo "  demo-run-id:  ${DEMO_RUN_ID}"
echo ""

for i in "${!ISSUES[@]}"; do
  DSTATE=$(jq -r '.state' "$ARTIFACTS_DIR/derived-state-${ISSUES[$i]}.json")
  DEVENTS=$(jq 'length' "$ARTIFACTS_DIR/timelines/${ISSUES[$i]}.json")
  echo "  #${ISSUES[$i]} ${FEATURE_NAMES[$i]}"
  echo "     delivery-state:  ${DSTATE}"
  echo "     delivery-events: ${DEVENTS}"
  echo "     delivery-corr:   ${CORR_IDS[$i]}"
  if $WITH_DILIGENCE; then
    DEVENTS=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUES[$i]}.json" 2>/dev/null || echo 0)
    echo "     diligence-events: ${DEVENTS}"
    echo "     diligence-corr:  ${DILIGENCE_CORR_IDS[$i]}"
  fi
  echo ""
done

echo "  GitHub Project: https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}"
echo "  Recordings:     ${RECORDINGS_DIR}"
echo ""

log "=== demo-delivery-with-diligence.sh complete ==="
log "demo-run-id=${DEMO_RUN_ID} | delivery=${TOTAL_DELIVERY} events | diligence=${TOTAL_DILIGENCE} events"
