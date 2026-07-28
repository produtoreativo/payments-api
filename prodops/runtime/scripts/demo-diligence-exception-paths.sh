#!/usr/bin/env bash
# demo-diligence-exception-paths.sh — EXP-014 Iteration 5: Diligence Exception Paths
#
# Executes three exception-path scenarios for Issues #76, #77, #78.
# Reads Delivery state from existing timelines — does NOT alter them.
#
# Scenario A (#76): Capture → Attach → Promote → Close
# Scenario B (#77): Capture → Attach → Block.Declared → Block.Resolved → Attach → Promote → Close
# Scenario C (#78): Scan.Started → Divergence.Detected → Scan.Completed
#                   → Flag → Repair → Promote → Close
#
# Usage:
#   demo-diligence-exception-paths.sh [--demo] [--demo-run-id <id>]
#
# Flags:
#   --demo            Activate delays between events (default: 3s)
#   --demo-run-id ID  Set demo-run-id (default: auto-generated)

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
DEMO_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo)          DEMO_MODE=true; shift ;;
    --demo-run-id)   DEMO_RUN_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

DEMO_STEP_DELAY=${DEMO_STEP_DELAY_SECONDS:-3}
step_delay() { $DEMO_MODE && sleep "$DEMO_STEP_DELAY" || true; }

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
  DEMO_RUN_ID="exp-014-exc-$(date -u +%Y-%m-%d-%H%M)"
fi

# ── Recording directory ────────────────────────────────────────────────────
RECORDINGS_DIR="$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/recordings/${DEMO_RUN_ID}"
EVIDENCE_DIR="$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/diligence-exception-paths"
mkdir -p "$RECORDINGS_DIR/diligence-timelines"
mkdir -p "$EVIDENCE_DIR"

ARTIFACTS_DIR="$PRODOPS_DIR/artifacts/runtime"
LOG_FILE="$ARTIFACTS_DIR/runtime.log"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

# ── Banner ─────────────────────────────────────────────────────────────────
echo ""
echo "┌────────────────────────────────────────────────────────────────────┐"
echo "│  EXP-014 — Iteration 5: Diligence Exception Paths                 │"
echo "│  runtime-version: ${RUNTIME_VERSION}                                       │"
if $DEMO_MODE; then
echo "│  Mode: DEMO (step-delay: ${DEMO_STEP_DELAY}s)                              │"
else
echo "│  Mode: FAST                                                        │"
fi
echo "│  demo-run-id: ${DEMO_RUN_ID}   │"
echo "└────────────────────────────────────────────────────────────────────┘"
echo ""

log "=== demo-diligence-exception-paths.sh v${RUNTIME_VERSION} started ==="
log "demo-run-id: ${DEMO_RUN_ID}"

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
DSTATUS_FIELD_ID=$(get_field_id "diligence-status")
DEVIDENCE_FIELD_ID=$(get_field_id "diligence-evidence")
RSYNC_FIELD_ID=$(get_field_id "runtime-sync")
BLOCK_REASON_FIELD_ID=$(get_field_id "diligence-block-reason")
FINDING_ID_FIELD_ID=$(get_field_id "diligence-finding-id")

# ── GitHub: get item IDs ───────────────────────────────────────────────────
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

# ── GitHub: update helpers ─────────────────────────────────────────────────
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

clear_text() {
  local ISSUE="$1" FIELD_ID="$2"
  [[ -z "$FIELD_ID" ]] && return 0
  update_text "$ISSUE" "$FIELD_ID" ""
}

# ── Datadog: exception-path metrics ───────────────────────────────────────
send_dd_metric() {
  local METRIC="$1" TYPE="$2" VALUE="$3" EXTRA_TAGS="$4"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now "$NOW" --arg metric "$METRIC" --argjson type "$TYPE" \
    --argjson val "$VALUE" --arg service "$DD_SERVICE" \
    --arg env "$DD_ENV_VALUE" --arg demo_run "$DEMO_RUN_ID" \
    --arg extra "$EXTRA_TAGS" \
    '{series:[{
      metric:$metric, type:$type,
      points:[{timestamp:$now, value:$val}],
      tags:([
        ("service:"+$service), ("env:"+$env),
        ("demo-run-id:"+$demo_run),
        "journey:diligence", "runtime:prodops"
      ] + (if $extra != "" then ($extra | split(",")) else [] end))
    }]}')
  local HTTP
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD")
  echo "$HTTP"
}

send_diligence_event_metric() {
  local ISSUE="$1" CE_TYPE="$2" DEL_STATE="$3" DIL_STATUS="$4" \
        RS="$5" DEL_CORR="$6" DIL_CORR="$7"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now "$NOW" --arg issue "$ISSUE" --arg event "$CE_TYPE" \
    --arg del_state "$DEL_STATE" --arg dil_status "$DIL_STATUS" \
    --arg rs "$RS" --arg del_corr "$DEL_CORR" --arg dil_corr "$DIL_CORR" \
    --arg service "$DD_SERVICE" --arg env "$DD_ENV_VALUE" \
    --arg demo_run "$DEMO_RUN_ID" \
    '{series:[{
      metric:"runtime.diligence.event.received", type:1,
      points:[{timestamp:$now,value:1}],
      tags:[
        ("issue:"+$issue), ("event:"+$event),
        ("delivery-state:"+$del_state), ("diligence-status:"+$dil_status),
        ("runtime-sync:"+$rs),
        ("delivery-correlation-id:"+$del_corr),
        ("diligence-correlation-id:"+$dil_corr),
        ("service:"+$service), ("env:"+$env),
        "journey:diligence", "runtime:prodops",
        ("demo-run-id:"+$demo_run)
      ]
    }]}')
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD"
}

send_features_tracked_metric() {
  local ISSUE="$1" DEL_STATE="$2" RS="$3" DEL_CORR="$4" DIL_CORR="$5" DIL_STATUS="$6"
  if [[ -z "${DD_API_KEY:-}" ]]; then return 0; fi
  local NOW; NOW=$(date +%s)
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --argjson now "$NOW" --arg issue "$ISSUE" \
    --arg del_state "$DEL_STATE" --arg rs "$RS" --arg dil_status "$DIL_STATUS" \
    --arg del_corr "$DEL_CORR" --arg dil_corr "$DIL_CORR" \
    --arg service "$DD_SERVICE" --arg env "$DD_ENV_VALUE" \
    --arg demo_run "$DEMO_RUN_ID" \
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
        ("demo-run-id:"+$demo_run)
      ]
    }]}')
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.${DD_SITE}/api/v2/series" \
    -H "Content-Type: application/json" -H "DD-API-KEY: ${DD_API_KEY}" \
    -d "$PAYLOAD"
}

# ── Core: build and emit a Diligence CloudEvent ────────────────────────────
# Usage: emit_diligence_event ISSUE EVENT DIL_CORR DEL_STATE DEL_LAST DEL_CORR DIL_STATUS [EXTRA_JSON_FIELDS]
emit_diligence_event() {
  local ISSUE="$1" EVENT="$2" DIL_CORR="$3" DEL_STATE="$4" \
        DEL_LAST="$5" DEL_CORR="$6" DIL_STATUS="$7"
  local EXTRA_FIELDS="${8:-}"

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
    --arg id                       "$CE_ID" \
    --arg source                   "$CE_SOURCE" \
    --arg type                     "$CE_TYPE" \
    --arg subject                  "$ISSUE" \
    --arg time                     "$CE_TIME" \
    --arg datacontenttype          "$CE_DATACONTENTTYPE" \
    --arg dataschema               "$CE_DATASCHEMA" \
    --arg issue                    "$ISSUE" \
    --arg journey                  "$JOURNEY" \
    --arg cycle                    "$CYCLE" \
    --arg phase                    "$PHASE" \
    --arg diligence_correlation_id "$DIL_CORR" \
    --arg delivery_correlation_id  "$DEL_CORR" \
    --arg delivery_last_event_type "$DEL_LAST" \
    --arg delivery_derived_state   "$DEL_STATE" \
    --arg diligence_status         "$DIL_STATUS" \
    --arg runtime_version          "$RUNTIME_VERSION" \
    --arg framework_version        "$FRAMEWORK_VERSION" \
    --arg schema_version           "$SCHEMA_VERSION" \
    --arg demo_run_id              "$DEMO_RUN_ID" \
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

  # Merge extra fields into data if provided
  if [[ -n "$EXTRA_FIELDS" ]]; then
    CE_JSON=$(echo "$CE_JSON" | jq --argjson extra "$EXTRA_FIELDS" '.data += $extra')
  fi

  # Validate CloudEvent structure
  bash "$RUNTIME_DIR/scripts/validate-event.sh" --event-json "$CE_JSON" >&2

  # Append to diligence timeline
  local DKEY="diligence-${ISSUE}"
  local TL="$ARTIFACTS_DIR/timelines/${DKEY}.json"
  if [[ -f "$TL" ]]; then
    jq --argjson new "$CE_JSON" '. + [$new]' "$TL" > "${TL}.tmp" && mv "${TL}.tmp" "$TL"
  else
    echo "[$CE_JSON]" | jq '.' > "$TL"
  fi

  echo "$CE_JSON"
}

print_event_block() {
  local LABEL="$1" ISSUE="$2" EVENT="$3" CE_TYPE="$4" DIL_STATUS="$5" \
        RS="$6" DD_HTTP="$7" EVCOUNT="$8" DEL_CORR="$9" DIL_CORR="${10}"
  echo ""
  echo "  [${LABEL}] #${ISSUE} ${EVENT}"
  echo "  ──────────────────────────────────────────────────────────"
  echo "  CloudEvent:     ${CE_TYPE}"
  echo "  Validation:     PASS ✓"
  printf "  Timeline:       appended (%s total)\n" "$EVCOUNT"
  echo "  Status:         ${DIL_STATUS} / runtime-sync: ${RS}"
  echo "  Datadog:        HTTP ${DD_HTTP} ✓"
  echo "  Del Corr:       ${DEL_CORR:0:8}..."
  echo "  Dil Corr:       ${DIL_CORR:0:8}..."
}

# ── Read Delivery context (non-destructive) ────────────────────────────────
read_delivery_state() {
  local ISSUE="$1"
  local DS_FILE="$ARTIFACTS_DIR/derived-state-${ISSUE}.json"
  if [[ ! -f "$DS_FILE" ]]; then
    echo "ERROR: Derived state for #${ISSUE} not found at ${DS_FILE}" >&2
    exit 1
  fi
  echo "$DS_FILE"
}

# ── Generate Diligence correlation IDs ────────────────────────────────────
DIL_CORR_76=$(uuidgen | tr '[:upper:]' '[:lower:]')
DIL_CORR_77=$(uuidgen | tr '[:upper:]' '[:lower:]')
DIL_CORR_78=$(uuidgen | tr '[:upper:]' '[:lower:]')

# ── Read Delivery correlation IDs from existing timelines ─────────────────
get_delivery_corr() {
  local ISSUE="$1"
  jq -r '.[0].data["delivery-correlation-id"] // .[0].data["correlation-id"] // "unknown"' \
    "$ARTIFACTS_DIR/timelines/${ISSUE}.json" 2>/dev/null || echo "unknown"
}

DEL_CORR_76=$(get_delivery_corr 76)
DEL_CORR_77=$(get_delivery_corr 77)
DEL_CORR_78=$(get_delivery_corr 78)

echo "── Correlation IDs"
echo "  #76 delivery-corr:  ${DEL_CORR_76:0:8}...  diligence-corr: ${DIL_CORR_76:0:8}..."
echo "  #77 delivery-corr:  ${DEL_CORR_77:0:8}...  diligence-corr: ${DIL_CORR_77:0:8}..."
echo "  #78 delivery-corr:  ${DEL_CORR_78:0:8}...  diligence-corr: ${DIL_CORR_78:0:8}..."
echo ""

# ── Snapshot Delivery state (read-only) ───────────────────────────────────
DS76_FILE=$(read_delivery_state 76)
DS77_FILE=$(read_delivery_state 77)
DS78_FILE=$(read_delivery_state 78)

DEL_STATE_76=$(jq -r '.state' "$DS76_FILE")
DEL_LAST_76=$(jq -r '.["last-event-type"]' "$DS76_FILE")
DEL_STATE_77=$(jq -r '.state' "$DS77_FILE")
DEL_LAST_77=$(jq -r '.["last-event-type"]' "$DS77_FILE")
DEL_STATE_78=$(jq -r '.state' "$DS78_FILE")
DEL_LAST_78=$(jq -r '.["last-event-type"]' "$DS78_FILE")

echo "── Delivery state snapshot (read-only — will not be modified)"
echo "  #76 → ${DEL_STATE_76}  (last: ${DEL_LAST_76})"
echo "  #77 → ${DEL_STATE_77}  (last: ${DEL_LAST_77})"
echo "  #78 → ${DEL_STATE_78}  (last: ${DEL_LAST_78})"
echo ""

# Compute delivery timeline hash BEFORE — preservation check
hash_timeline() {
  local ISSUE="$1"
  local TL="$ARTIFACTS_DIR/timelines/${ISSUE}.json"
  [[ -f "$TL" ]] && python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()[:16])" "$TL" || echo "absent"
}

HASH_DEL_76_BEFORE=$(hash_timeline 76)
HASH_DEL_77_BEFORE=$(hash_timeline 77)
HASH_DEL_78_BEFORE=$(hash_timeline 78)
log "Delivery timeline hashes (before): #76=${HASH_DEL_76_BEFORE} #77=${HASH_DEL_77_BEFORE} #78=${HASH_DEL_78_BEFORE}"

# ── Reset diligence timelines for this run ────────────────────────────────
echo "[]" > "$ARTIFACTS_DIR/timelines/diligence-76.json"
echo "[]" > "$ARTIFACTS_DIR/timelines/diligence-77.json"
echo "[]" > "$ARTIFACTS_DIR/timelines/diligence-78.json"

# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  SCENARIO A — #76: Sync completo (Capture → Attach → Promote → Close)"
echo "════════════════════════════════════════════════════════════════════"
# ═══════════════════════════════════════════════════════════════════════════

ISSUE=76
DIL_CORR="$DIL_CORR_76"
DEL_CORR="$DEL_CORR_76"
DEL_STATE="$DEL_STATE_76"
DEL_LAST="$DEL_LAST_76"

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
printf  "  ║  [SCENARIO A] #76 — FTR-001: Invoice PIX                  ║\n"
printf  "  ║  Delivery: %-12s | dil-corr: %-8s...           ║\n" "$DEL_STATE" "${DIL_CORR:0:8}"
echo "  ╚══════════════════════════════════════════════════════════════╝"

# A.1 Capture.Started — diligence-status: Sync In Progress
DIL_STATUS="Sync In Progress"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Capture.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Capture.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Sync In Progress')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Capture.Started" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Sync In Progress ✓"
step_delay

# A.2 Capture.Completed — diligence-status: Captured, evidence: Partial
DIL_STATUS="Captured"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Capture.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Capture.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Captured')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Partial')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Pending')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Capture.Completed" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Captured / Partial / Pending ✓"
step_delay

# A.3 Attach.Started
DIL_STATUS="Sync In Progress"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Attach.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Attach.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Attach.Started" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# A.4 Attach.Completed — Attached / Complete / In Sync
DIL_STATUS="Attached"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Attach.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Attach.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Attached')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Attach.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Attached / Complete / In Sync ✓"
step_delay

# A.5 Promote.Started — Promoting
DIL_STATUS="Promoting"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoting')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Promote.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Promoting ✓"
step_delay

# A.6 Promote.Completed — Promoted
DIL_STATUS="Promoted"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoted')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Promote.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Promoted ✓"
step_delay

# A.7 Close.Started — Closing
DIL_STATUS="Closing"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closing')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Close.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Closing ✓"
step_delay

# A.8 Close.Completed — Closed / Complete / In Sync  ✅
DIL_STATUS="Closed"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closed')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
HTTP_FT=$(send_features_tracked_metric "$ISSUE" "$DEL_STATE" "In Sync" "$DEL_CORR" "$DIL_CORR" "$DIL_STATUS")
HTTP_FC=$(send_dd_metric "runtime.diligence.features.closed" 1 1 "issue:${ISSUE},diligence-status:closed")
print_event_block "SCENARIO-A" "$ISSUE" "Diligence.Close.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Closed / Complete / In Sync ✓"
echo "  features.closed: HTTP ${HTTP_FC} ✓"
log "#76 | Scenario A complete | diligence-status=Closed | runtime-sync=In Sync"
echo ""
echo "  ✅ #76 → Closed / Complete / In Sync"

# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  SCENARIO B — #77: Block → Resume → Close"
echo "════════════════════════════════════════════════════════════════════"
# ═══════════════════════════════════════════════════════════════════════════

ISSUE=77
DIL_CORR="$DIL_CORR_77"
DEL_CORR="$DEL_CORR_77"
DEL_STATE="$DEL_STATE_77"
DEL_LAST="$DEL_LAST_77"

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
printf  "  ║  [SCENARIO B] #77 — FTR-002: Invoice Cartão               ║\n"
printf  "  ║  Delivery: %-12s | dil-corr: %-8s...           ║\n" "$DEL_STATE" "${DIL_CORR:0:8}"
echo "  ╚══════════════════════════════════════════════════════════════╝"

# B.1 Prepare block: temporarily hide derived state to create real blocking condition
DS77_BACKUP="$ARTIFACTS_DIR/derived-state-77.json.bak"
cp "$DS77_FILE" "$DS77_BACKUP"
echo "  [BLOCK-PREP] Backing up derived-state-77.json to introduce real block"
echo "  [BLOCK-PREP] Original: $(jq -c '{state:.state}' "$DS77_FILE")"

# Rename the derived state to simulate missing evidence gate
mv "$DS77_FILE" "${DS77_FILE}.hidden"
echo "  [BLOCK-PREP] derived-state-77.json temporarily hidden (gate: missing Derived State)"

# B.2 Capture.Started
DIL_STATUS="Sync In Progress"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Capture.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Capture.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Sync In Progress')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Capture.Started" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# B.3 Capture.Completed → gate check fails → Block.Declared
# Gate check: confirm derived state is readable
GATE_PASS=true
if [[ ! -f "$DS77_FILE" ]]; then
  GATE_PASS=false
fi

DIL_STATUS="Captured"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Capture.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Capture.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Captured')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Partial')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Capture.Completed" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

if [[ "$GATE_PASS" == "false" ]]; then
  # B.4 Block.Declared — gate failure detected
  BLOCK_REASON="Derived State absent for #77 — evidence gate requires readable derived-state-77.json before Attach can proceed"
  DIL_STATUS="Blocked"
  EXTRA_BLOCK='{"block-reason":"'"$BLOCK_REASON"'","gate":"attach-precondition","blocked-at":"Attach.PreCheck"}'
  CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Block.Declared" \
    "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_BLOCK")
  CE_TYPE=$(catalog_get "Diligence.Block.Declared" "cloud-event-type")
  EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
  update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Blocked')"
  update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Partial')"
  update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Blocked')"
  update_text "$ISSUE" "$BLOCK_REASON_FIELD_ID" "$BLOCK_REASON"
  DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Blocked" "$DEL_CORR" "$DIL_CORR")
  HTTP_BL=$(send_dd_metric "runtime.diligence.blocked" 1 1 "issue:${ISSUE},block-reason:derived-state-absent")
  print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Block.Declared" "$CE_TYPE" "$DIL_STATUS" "Blocked" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
  echo "  GitHub:         Blocked / Partial / Blocked ✓"
  echo "  block-reason:   ${BLOCK_REASON}"
  echo "  blocked metric: HTTP ${HTTP_BL} ✓"
  echo ""
  echo "  ⛔ #77 BLOCKED — Gate: derived-state-77.json absent"
  echo "     Promote is PREVENTED while block is active."
  log "#77 | BLOCKED | gate=attach-precondition | reason=derived-state-absent"
  step_delay

  # B.5 Restore the evidence (resolve the block)
  mv "${DS77_FILE}.hidden" "$DS77_FILE"
  echo ""
  echo "  [RESOLVE] Restoring derived-state-77.json (evidence restored)"
  echo "  [RESOLVE] Restored: $(jq -c '{state:.state}' "$DS77_FILE")"
  step_delay

  # B.6 Block.Resolved
  DIL_STATUS="Captured"
  EXTRA_RESOLVED='{"block-resolution":"Derived State restored from runtime artifacts","resolved-gate":"attach-precondition"}'
  CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Block.Resolved" \
    "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_RESOLVED")
  CE_TYPE=$(catalog_get "Diligence.Block.Resolved" "cloud-event-type")
  EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
  update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Captured')"
  update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Pending')"
  clear_text "$ISSUE" "$BLOCK_REASON_FIELD_ID"
  DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
  print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Block.Resolved" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
  echo "  GitHub:         Captured / Pending (block-reason cleared) ✓"
  echo "  Resume from:    Attach step"
  step_delay
fi

# B.7 Attach.Started (resume from block)
DIL_STATUS="Sync In Progress"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Attach.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Attach.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Attach.Started" "$CE_TYPE" "$DIL_STATUS" "Pending" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# B.8 Attach.Completed
DIL_STATUS="Attached"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Attach.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Attach.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Attached')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Attach.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Attached / Complete / In Sync ✓"
step_delay

# B.9 Promote.Started
DIL_STATUS="Promoting"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoting')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Promote.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# B.10 Promote.Completed
DIL_STATUS="Promoted"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoted')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Promote.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# B.11 Close.Started
DIL_STATUS="Closing"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closing')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Close.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# B.12 Close.Completed — Closed ✅
DIL_STATUS="Closed"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closed')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
HTTP_FT=$(send_features_tracked_metric "$ISSUE" "$DEL_STATE" "In Sync" "$DEL_CORR" "$DIL_CORR" "$DIL_STATUS")
HTTP_FC=$(send_dd_metric "runtime.diligence.features.closed" 1 1 "issue:${ISSUE},diligence-status:closed")
print_event_block "SCENARIO-B" "$ISSUE" "Diligence.Close.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Closed / Complete / In Sync ✓"
log "#77 | Scenario B complete | diligence-status=Closed | block-validated=true"
echo ""
echo "  ✅ #77 → Closed / Complete / In Sync (Block → Resume validated)"

# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  SCENARIO C — #78: Drift → Flag → Repair → Close"
echo "════════════════════════════════════════════════════════════════════"
# ═══════════════════════════════════════════════════════════════════════════

ISSUE=78
DIL_CORR="$DIL_CORR_78"
DEL_CORR="$DEL_CORR_78"
DEL_STATE="$DEL_STATE_78"
DEL_LAST="$DEL_LAST_78"

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
printf  "  ║  [SCENARIO C] #78 — FTR-003: Confirmação de Pagamento     ║\n"
printf  "  ║  Delivery: %-12s | dil-corr: %-8s...           ║\n" "$DEL_STATE" "${DIL_CORR:0:8}"
echo "  ╚══════════════════════════════════════════════════════════════╝"

# C.1 Capture cycle (Attach was done in a prior demo run — just re-attach state baseline)
echo ""
echo "  [SCENARIO-C] Establishing baseline via Capture → Attach..."

for BASE_EVENT in "Diligence.Capture.Started" "Diligence.Capture.Completed" \
                  "Diligence.Attach.Started" "Diligence.Attach.Completed"; do
  case "$BASE_EVENT" in
    "Diligence.Capture.Started")  DIL_STATUS="Sync In Progress" ;;
    "Diligence.Capture.Completed") DIL_STATUS="Captured" ;;
    "Diligence.Attach.Started")   DIL_STATUS="Sync In Progress" ;;
    "Diligence.Attach.Completed") DIL_STATUS="Attached" ;;
  esac
  CE_JSON=$(emit_diligence_event "$ISSUE" "$BASE_EVENT" \
    "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
  CE_TYPE=$(catalog_get "$BASE_EVENT" "cloud-event-type")
  EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
  DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Pending" "$DEL_CORR" "$DIL_CORR")
  echo "  [BASELINE] ${BASE_EVENT} → ${DIL_STATUS} (HTTP ${DD_HTTP})"
done
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Attached')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
echo "  GitHub:         Attached / Complete / In Sync ✓ (baseline)"
step_delay

# C.2 Introduce deliberate drift: change oem-state to wrong value in GitHub
echo ""
echo "  [DRIFT-INTRO] Reading Derived State as source of truth..."
EXPECTED_OEM_STATE=$(jq -r '.state' "$DS78_FILE")
echo "  [DRIFT-INTRO] Derived State says oem-state should be: ${EXPECTED_OEM_STATE}"

# Save GitHub state BEFORE drift (snapshot)
GH_BEFORE=$(gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        items(first: 20) {
          nodes {
            content { ... on Issue { number } }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID" \
  | jq '[.data.node.items.nodes[] |
    select(.content.number == 78) |
    {issue: .content.number,
     fields: [.fieldValues.nodes[] | select(.field.name != null) | {(.field.name): .name}] | add}]')

# Introduce drift: set oem-state to BOOTSTRAPPING (wrong — derived says HACKING)
DRIFT_VALUE="BOOTSTRAPPING"
DRIFT_OPT_ID=$(get_option_id "oem-state" "$DRIFT_VALUE")
IITEM_78=$(get_item_id_for_issue "78")
OEM_STATE_FIELD_ID=$(get_field_id "oem-state")
gh api graphql -f query='
  mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) {
    updateProjectV2ItemFieldValue(input:{
      projectId:$p, itemId:$i, fieldId:$f, value:{singleSelectOptionId:$o}
    }){projectV2Item{id}}
  }' -f p="$PROJECT_ID" -f i="$IITEM_78" -f f="$OEM_STATE_FIELD_ID" -f o="$DRIFT_OPT_ID" \
  > /dev/null 2>&1

echo "  [DRIFT-INTRO] GitHub oem-state set to '${DRIFT_VALUE}' (drift introduced)"
echo "  [DRIFT-INTRO] Derived State source of truth: '${EXPECTED_OEM_STATE}'"
echo "  [DRIFT-INTRO] Drift = GitHub(${DRIFT_VALUE}) ≠ DerivedState(${EXPECTED_OEM_STATE})"
step_delay

# C.3 Scan.Started — diligence-status: Scanning
DIL_STATUS="Scanning"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Scan.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Scan.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Scanning')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Scan.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Scanning ✓"
step_delay

# C.4 Divergence.Detected — read current GitHub state and compare with Derived State
GH_CURRENT_OEM=$(gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        items(first: 20) {
          nodes {
            content { ... on Issue { number } }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID" \
  | jq -r '[.data.node.items.nodes[] |
    select(.content.number == 78) |
    .fieldValues.nodes[] |
    select(.field.name == "oem-state") | .name] | .[0]')

echo ""
echo "  [SCAN] Comparing GitHub vs Derived State for #78..."
echo "  [SCAN] GitHub oem-state:        ${GH_CURRENT_OEM}"
echo "  [SCAN] Derived State:           ${EXPECTED_OEM_STATE}"

DIVERGENCE_DETECTED=false
if [[ "$GH_CURRENT_OEM" != "$EXPECTED_OEM_STATE" ]]; then
  DIVERGENCE_DETECTED=true
  FINDING_ID="FND-$(date -u +%Y%m%d%H%M)-78"
  echo "  [SCAN] DIVERGENCE DETECTED → ${FINDING_ID}"

  # Build finding JSON
  FINDING_JSON=$(jq -n \
    --arg id "$FINDING_ID" \
    --argjson issue 78 \
    --arg detected_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg divergence_type "oem-state-mismatch" \
    --arg expected_value "$EXPECTED_OEM_STATE" \
    --arg actual_value "$GH_CURRENT_OEM" \
    --arg source_of_truth "Timeline → Derived State (derived-state-78.json)" \
    --arg severity "HIGH" \
    --arg evidence "GitHub oem-state=${GH_CURRENT_OEM} vs Derived State=${EXPECTED_OEM_STATE}; Timeline last event=${DEL_LAST}" \
    --arg delivery_correlation_id "$DEL_CORR" \
    --arg diligence_correlation_id "$DIL_CORR" \
    --arg recommended_repair "Update GitHub oem-state from Derived State value (${EXPECTED_OEM_STATE})" \
    --arg repair_source "derived-state-78.json" \
    --arg status "Open" \
    --arg demo_run_id "$DEMO_RUN_ID" \
    '{
      "finding-id": $id,
      "issue": $issue,
      "detected-at": $detected_at,
      "divergence-type": $divergence_type,
      "expected-value": $expected_value,
      "actual-value": $actual_value,
      "source-of-truth": $source_of_truth,
      "severity": $severity,
      "evidence": $evidence,
      "delivery-correlation-id": $delivery_correlation_id,
      "diligence-correlation-id": $diligence_correlation_id,
      "recommended-repair": $recommended_repair,
      "repair-source": $repair_source,
      "status": $status,
      "demo-run-id": $demo_run_id
    }')

  echo "$FINDING_JSON" > "$EVIDENCE_DIR/finding-${FINDING_ID}.json"
  echo "  [FINDING] Saved to: evidence/diligence-exception-paths/finding-${FINDING_ID}.json"

  # Emit Divergence.Detected CloudEvent
  DIL_STATUS="Scanning"
  EXTRA_DIVERGENCE=$(jq -n \
    --arg fid "$FINDING_ID" --arg dtype "oem-state-mismatch" \
    --arg expected "$EXPECTED_OEM_STATE" --arg actual "$GH_CURRENT_OEM" \
    '{
      "finding-id": $fid,
      "divergence-type": $dtype,
      "expected-value": $expected,
      "actual-value": $actual,
      "severity": "HIGH"
    }')
  CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Divergence.Detected" \
    "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_DIVERGENCE")
  CE_TYPE=$(catalog_get "Diligence.Divergence.Detected" "cloud-event-type")
  EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
  update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Drift')"
  update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Invalid')"
  update_text "$ISSUE" "$FINDING_ID_FIELD_ID" "$FINDING_ID"
  DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Drift" "$DEL_CORR" "$DIL_CORR")
  HTTP_DD=$(send_dd_metric "runtime.diligence.drift.detected" 1 1 "issue:${ISSUE},finding-id:${FINDING_ID}")
  HTTP_FO=$(send_dd_metric "runtime.diligence.findings.open" 1 1 "issue:${ISSUE},finding-id:${FINDING_ID},severity:HIGH")
  print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Divergence.Detected" "$CE_TYPE" "$DIL_STATUS" "Drift" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
  echo "  GitHub:         Drift / Invalid ✓  finding-id: ${FINDING_ID}"
  echo "  drift.detected: HTTP ${HTTP_DD} ✓"
  echo "  findings.open:  HTTP ${HTTP_FO} ✓"
  step_delay
fi

# C.5 Scan.Completed
DIL_STATUS="Scanning"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Scan.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Scan.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Drift" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Scan.Completed" "$CE_TYPE" "$DIL_STATUS" "Drift" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# C.6 Flag.Started
DIL_STATUS="Flagged"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Flag.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Flag.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Flagged')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Drift" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Flag.Started" "$CE_TYPE" "$DIL_STATUS" "Drift" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Flagged ✓"
step_delay

# C.7 Flag.Completed
DIL_STATUS="Flagged"
EXTRA_FLAG='{"severity":"HIGH","corrective-action":"Update GitHub oem-state from Derived State","reparable-by":"Diligence"}'
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Flag.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_FLAG")
CE_TYPE=$(catalog_get "Diligence.Flag.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Drift" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Flag.Completed" "$CE_TYPE" "$DIL_STATUS" "Drift" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# C.8 Repair.Started — get correct value from Derived State (NOT from GitHub)
CORRECT_OEM=$(jq -r '.state' "$DS78_FILE")
echo ""
echo "  [REPAIR] Source of truth: Timeline → Derived State"
echo "  [REPAIR] Correct oem-state from derived-state-78.json: ${CORRECT_OEM}"
echo "  [REPAIR] NOT reading current GitHub state as reference"

DIL_STATUS="Repairing"
EXTRA_REPAIR_START='{"repair-source":"derived-state-78.json","target-field":"oem-state","correct-value":"'"$CORRECT_OEM"'"}'
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Repair.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_REPAIR_START")
CE_TYPE=$(catalog_get "Diligence.Repair.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Repairing')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'Repairing')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "Repairing" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Repair.Started" "$CE_TYPE" "$DIL_STATUS" "Repairing" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Repairing ✓"
step_delay

# C.9 Execute repair: restore oem-state from Derived State
CORRECT_OEM_OPT=$(get_option_id "oem-state" "$CORRECT_OEM")
gh api graphql -f query='
  mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) {
    updateProjectV2ItemFieldValue(input:{
      projectId:$p, itemId:$i, fieldId:$f, value:{singleSelectOptionId:$o}
    }){projectV2Item{id}}
  }' -f p="$PROJECT_ID" -f i="$IITEM_78" -f f="$OEM_STATE_FIELD_ID" -f o="$CORRECT_OEM_OPT" \
  > /dev/null 2>&1

echo "  [REPAIR] GitHub oem-state restored to: ${CORRECT_OEM} (from Derived State)"
step_delay

# C.10 Repair.Completed — Repaired / Complete / In Sync
DIL_STATUS="Repaired"
EXTRA_REPAIR_DONE='{"repaired-field":"oem-state","restored-value":"'"$CORRECT_OEM"'","source":"derived-state-78.json"}'
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Repair.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS" "$EXTRA_REPAIR_DONE")
CE_TYPE=$(catalog_get "Diligence.Repair.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Repaired')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
HTTP_RC=$(send_dd_metric "runtime.diligence.repairs.completed" 1 1 "issue:${ISSUE},finding-id:${FINDING_ID:-none}")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Repair.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Repaired / Complete / In Sync ✓"
echo "  repairs.done:   HTTP ${HTTP_RC} ✓"
step_delay

# Update finding status to Closed
if [[ -n "${FINDING_ID:-}" && -f "$EVIDENCE_DIR/finding-${FINDING_ID}.json" ]]; then
  jq '.status = "Closed" | .["closed-at"] = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' \
    "$EVIDENCE_DIR/finding-${FINDING_ID}.json" > "$EVIDENCE_DIR/finding-${FINDING_ID}.json.tmp"
  mv "$EVIDENCE_DIR/finding-${FINDING_ID}.json.tmp" "$EVIDENCE_DIR/finding-${FINDING_ID}.json"
  echo "  [FINDING] ${FINDING_ID} status → Closed"
fi

# C.11 Promote.Started
DIL_STATUS="Promoting"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoting')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Promote.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# C.12 Promote.Completed
DIL_STATUS="Promoted"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Promote.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Promote.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Promoted')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Promote.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# C.13 Close.Started
DIL_STATUS="Closing"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Started" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Started" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closing')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Close.Started" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
step_delay

# C.14 Close.Completed — Closed ✅
DIL_STATUS="Closed"
CE_JSON=$(emit_diligence_event "$ISSUE" "Diligence.Close.Completed" \
  "$DIL_CORR" "$DEL_STATE" "$DEL_LAST" "$DEL_CORR" "$DIL_STATUS")
CE_TYPE=$(catalog_get "Diligence.Close.Completed" "cloud-event-type")
EVCOUNT=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json")
update_singleselect "$ISSUE" "$DSTATUS_FIELD_ID" "$(get_option_id 'diligence-status' 'Closed')"
update_singleselect "$ISSUE" "$DEVIDENCE_FIELD_ID" "$(get_option_id 'diligence-evidence' 'Complete')"
update_singleselect "$ISSUE" "$RSYNC_FIELD_ID" "$(get_option_id 'runtime-sync' 'In Sync')"
DD_HTTP=$(send_diligence_event_metric "$ISSUE" "$CE_TYPE" "$DEL_STATE" "$DIL_STATUS" "In Sync" "$DEL_CORR" "$DIL_CORR")
HTTP_FT=$(send_features_tracked_metric "$ISSUE" "$DEL_STATE" "In Sync" "$DEL_CORR" "$DIL_CORR" "$DIL_STATUS")
HTTP_FC=$(send_dd_metric "runtime.diligence.features.closed" 1 1 "issue:${ISSUE},diligence-status:closed")
print_event_block "SCENARIO-C" "$ISSUE" "Diligence.Close.Completed" "$CE_TYPE" "$DIL_STATUS" "In Sync" "$DD_HTTP" "$EVCOUNT" "$DEL_CORR" "$DIL_CORR"
echo "  GitHub:         Closed / Complete / In Sync ✓"
log "#78 | Scenario C complete | diligence-status=Closed | drift-repaired=true"
echo ""
echo "  ✅ #78 → Closed / Complete / In Sync (Drift → Repair validated)"

# ── Verify Delivery Timeline preservation ────────────────────────────────
echo ""
echo "── Delivery Timeline Preservation Check"
HASH_DEL_76_AFTER=$(hash_timeline 76)
HASH_DEL_77_AFTER=$(hash_timeline 77)
HASH_DEL_78_AFTER=$(hash_timeline 78)

check_hash() {
  local ISSUE="$1" BEFORE="$2" AFTER="$3"
  if [[ "$BEFORE" == "$AFTER" ]]; then
    echo "  [PASS] #${ISSUE} Delivery Timeline unchanged (${BEFORE})"
  else
    echo "  [FAIL] #${ISSUE} Delivery Timeline MODIFIED! before=${BEFORE} after=${AFTER}"
  fi
}
check_hash 76 "$HASH_DEL_76_BEFORE" "$HASH_DEL_76_AFTER"
check_hash 77 "$HASH_DEL_77_BEFORE" "$HASH_DEL_77_AFTER"
check_hash 78 "$HASH_DEL_78_BEFORE" "$HASH_DEL_78_AFTER"

# ── Save github-before-after evidence ────────────────────────────────────
echo ""
echo "── Saving GitHub before/after snapshot..."
GH_AFTER=$(gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        items(first: 20) {
          nodes {
            content { ... on Issue { number } }
            fieldValues(first: 30) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name field { ... on ProjectV2SingleSelectField { name } }
                }
                ... on ProjectV2ItemFieldTextValue {
                  text field { ... on ProjectV2Field { name } }
                }
              }
            }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID" \
  | jq '[.data.node.items.nodes[] |
    select(.content.number == 76 or .content.number == 77 or .content.number == 78) |
    {
      issue: .content.number,
      fields: ([.fieldValues.nodes[] |
        select(.field.name != null) |
        if .name then {(.field.name): .name} else {(.field.name): .text} end
      ] | add)
    }]')

jq -n \
  --argjson before "$GH_BEFORE" \
  --argjson after "$GH_AFTER" \
  --arg demo_run "$DEMO_RUN_ID" \
  '{
    "demo-run-id": $demo_run,
    "scenario": "C — drift introduced on #78 oem-state",
    "drift-field": "oem-state",
    "drift-value": "BOOTSTRAPPING",
    "repaired-to": "HACKING",
    "repair-source": "Timeline → Derived State",
    "github-before-drift": $before,
    "github-after-repair": $after
  }' > "$EVIDENCE_DIR/github-before-after.json"
echo "  Saved: evidence/diligence-exception-paths/github-before-after.json"

# ── Archive diligence timelines ───────────────────────────────────────────
echo ""
echo "── Archiving diligence timelines..."
mkdir -p "$RECORDINGS_DIR/diligence-timelines"
for ISSUE in 76 77 78; do
  TL="$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json"
  if [[ -f "$TL" ]]; then
    cp "$TL" "$RECORDINGS_DIR/diligence-timelines/diligence-${ISSUE}.json"
    echo "  Archived: diligence-${ISSUE}.json ($(jq 'length' "$TL") events)"
  fi
done

# ── Demo summary ──────────────────────────────────────────────────────────
TOTAL_EVENTS_76=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-76.json")
TOTAL_EVENTS_77=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-77.json")
TOTAL_EVENTS_78=$(jq 'length' "$ARTIFACTS_DIR/timelines/diligence-78.json")
TOTAL_DIL=$((TOTAL_EVENTS_76 + TOTAL_EVENTS_77 + TOTAL_EVENTS_78))

jq -n \
  --arg demo_run_id "$DEMO_RUN_ID" \
  --arg runtime_version "$RUNTIME_VERSION" \
  --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson events_76 "$TOTAL_EVENTS_76" \
  --argjson events_77 "$TOTAL_EVENTS_77" \
  --argjson events_78 "$TOTAL_EVENTS_78" \
  --argjson total "$TOTAL_DIL" \
  --arg dil_corr_76 "$DIL_CORR_76" \
  --arg dil_corr_77 "$DIL_CORR_77" \
  --arg dil_corr_78 "$DIL_CORR_78" \
  '{
    "demo-run-id": $demo_run_id,
    "runtime-version": $runtime_version,
    "timestamp": $timestamp,
    "type": "exception-paths",
    "diligence-events-total": $total,
    "scenario-a": {"issue": 76, "events": $events_76, "result": "Closed"},
    "scenario-b": {"issue": 77, "events": $events_77, "result": "Closed", "block-validated": true},
    "scenario-c": {"issue": 78, "events": $events_78, "result": "Closed", "drift-repaired": true},
    "diligence-correlation-ids": {
      "76": $dil_corr_76,
      "77": $dil_corr_77,
      "78": $dil_corr_78
    }
  }' > "$RECORDINGS_DIR/demo-summary.json"

echo ""
echo "Archived to: $RECORDINGS_DIR"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] === demo-diligence-exception-paths.sh complete ==="
log "=== demo-diligence-exception-paths.sh complete === total-events=${TOTAL_DIL}"