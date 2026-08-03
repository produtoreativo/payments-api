#!/usr/bin/env bash
# prodops_emit_event — player-neutral Delivery event emission spike
# Delegates to the existing Runtime pipeline (emit → timeline → derive-state → datadog → github).
#
# Usage:
#   emit-event.sh --input <json-file>
#   echo '{"event":"..."}' | emit-event.sh
#
# Exit codes:
#   0  accepted — event processed successfully
#   1  invalid input — missing required fields
#   2  unknown event — not found in catalog
#   3  pipeline error — a runtime step failed
#   4  idempotent skip — same correlation-id + event-type already in timeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRODOPS_DIR="$(cd "$RUNTIME_DIR/.." && pwd)"

PRODUCER="$RUNTIME_DIR/producer/emit.sh"
TIMELINE="$RUNTIME_DIR/timeline/append.sh"
DERIVE="$RUNTIME_DIR/consumer/derive-state.sh"
DATADOG="$RUNTIME_DIR/datadog/send.sh"
GITHUB="$RUNTIME_DIR/github/sync.sh"
CATALOG="$RUNTIME_DIR/catalog/events.yaml"
TIMELINES_DIR="$PRODOPS_DIR/artifacts/runtime/timelines"

log() { echo "[prodops_emit_event] $*" >&2; }

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

# ── Input ─────────────────────────────────────────────────────────────────────
INPUT_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) INPUT_FILE="$2"; shift 2 ;;
    *) log "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -n "$INPUT_FILE" ]]; then
  INPUT_JSON=$(cat "$INPUT_FILE")
elif [[ ! -t 0 ]]; then
  INPUT_JSON=$(cat)
else
  log "Error: provide --input <file> or pipe JSON to stdin"
  exit 1
fi

# ── Parse ──────────────────────────────────────────────────────────────────────
EVENT=$(echo "$INPUT_JSON"          | jq -r '.event              // empty')
WORK_ITEM_ID=$(echo "$INPUT_JSON"   | jq -r '."work-item-id"    // empty')
CORRELATION_ID=$(echo "$INPUT_JSON" | jq -r '."correlation-id"  // empty')
EXECUTION_ID=$(echo "$INPUT_JSON"   | jq -r '."execution-id"    // empty')
ITERATION_ID=$(echo "$INPUT_JSON"   | jq -r '."iteration-id"    // empty')
PLAYER=$(echo "$INPUT_JSON"         | jq -r '.actor.player      // "unknown"')
AGENT_NAME=$(echo "$INPUT_JSON"     | jq -r '.actor.agent       // "unknown"')

log "player=$PLAYER agent=$AGENT_NAME iteration=$ITERATION_ID execution=$EXECUTION_ID"

# ── Resolve subject ───────────────────────────────────────────────────────────
# Plan-level events (Delivery.Plan.*) use iteration-id as subject.
# Guard against the agent serializing JSON null as the string "null".
if [[ ( -z "$WORK_ITEM_ID" || "$WORK_ITEM_ID" == "null" ) && -n "$ITERATION_ID" ]]; then
  WORK_ITEM_ID="$ITERATION_ID"
fi

# ── Validate required fields ──────────────────────────────────────────────────
declare -a ERRORS=()
[[ -z "$EVENT" ]]          && ERRORS+=("missing required field: event")
[[ -z "$WORK_ITEM_ID" ]]   && ERRORS+=("missing required field: work-item-id")
[[ -z "$CORRELATION_ID" ]] && ERRORS+=("missing required field: correlation-id")

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  ERROR_JSON=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
  jq -n --argjson errors "$ERROR_JSON" \
    '{"status":"error","event-id":null,"event-type":null,"correlation-id":null,
      "derived-state":null,"github-sync":"skipped","datadog-sync":"skipped","errors":$errors}'
  exit 1
fi

# ── Verify event in catalog ───────────────────────────────────────────────────
if ! python3 - "$CATALOG" "$EVENT" <<'PYEOF' 2>/dev/null; then
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
assert sys.argv[2] in data['events'], f"not in catalog: {sys.argv[2]}"
PYEOF
  jq -n --arg e "$EVENT" \
    '{"status":"error","event-id":null,"event-type":null,"correlation-id":null,
      "derived-state":null,"github-sync":"skipped","datadog-sync":"skipped",
      "errors":["event not in catalog: \($e)"]}'
  exit 2
fi

CE_TYPE=$(catalog_get "$EVENT" "cloud-event-type")
ALTERS_STATE=$(catalog_get "$EVENT" "alters-state")

# ── Idempotency check ─────────────────────────────────────────────────────────
TIMELINE_FILE="$TIMELINES_DIR/${WORK_ITEM_ID}.json"
if [[ -f "$TIMELINE_FILE" ]]; then
  EXISTING_ID=$(jq -r \
    --arg cid "$CORRELATION_ID" --arg type "$CE_TYPE" \
    '.[] | select(.data["runtime-correlation-id"] == $cid and .type == $type) | .id' \
    "$TIMELINE_FILE" 2>/dev/null | head -1)

  if [[ -n "$EXISTING_ID" ]]; then
    log "Idempotent skip — already processed: correlation-id=$CORRELATION_ID type=$CE_TYPE"
    CURRENT_STATE=$(jq -r \
      '[.[] | select(.data["alters-state"] == true)] | if length == 0 then "UNKNOWN" else last.data["new-state"] end' \
      "$TIMELINE_FILE" 2>/dev/null)
    jq -n \
      --arg event_id       "$EXISTING_ID" \
      --arg event_type     "$CE_TYPE" \
      --arg correlation_id "$CORRELATION_ID" \
      --arg derived_state  "$CURRENT_STATE" \
      '{"status":"skipped","event-id":$event_id,"event-type":$event_type,
        "correlation-id":$correlation_id,"derived-state":$derived_state,
        "github-sync":"skipped","datadog-sync":"skipped","errors":[]}'
    exit 4
  fi
fi

# ── Step 1: Emit CloudEvent ───────────────────────────────────────────────────
log "Emitting $EVENT for issue #$WORK_ITEM_ID (correlation-id=$CORRELATION_ID)"
EMIT_ERR_FILE=$(mktemp)
if ! CE_JSON=$(bash "$PRODUCER" \
    --issue          "$WORK_ITEM_ID" \
    --event          "$EVENT" \
    --correlation-id "$CORRELATION_ID" 2>"$EMIT_ERR_FILE"); then
  ERR_MSG=$(cat "$EMIT_ERR_FILE")
  rm -f "$EMIT_ERR_FILE"
  jq -n --arg err "$ERR_MSG" \
    '{"status":"error","event-id":null,"event-type":null,"correlation-id":null,
      "derived-state":null,"github-sync":"skipped","datadog-sync":"skipped","errors":[$err]}'
  exit 3
fi
rm -f "$EMIT_ERR_FILE"
EVENT_ID=$(echo "$CE_JSON" | jq -r '.id')
log "CloudEvent produced: id=$EVENT_ID type=$CE_TYPE alters-state=$ALTERS_STATE"

# ── Step 2: Persist timeline ──────────────────────────────────────────────────
log "Appending to timeline..."
if ! bash "$TIMELINE" \
    --issue      "$WORK_ITEM_ID" \
    --event-json "$CE_JSON" >/dev/null 2>&1; then
  jq -n \
    '{"status":"error","event-id":null,"event-type":null,"correlation-id":null,
      "derived-state":null,"github-sync":"skipped","datadog-sync":"skipped",
      "errors":["timeline/append.sh failed"]}'
  exit 3
fi

# ── Step 3: Derive state ──────────────────────────────────────────────────────
log "Deriving state..."
DERIVED_JSON=$(bash "$DERIVE" --issue "$WORK_ITEM_ID" 2>/dev/null) || {
  jq -n \
    '{"status":"error","event-id":null,"event-type":null,"correlation-id":null,
      "derived-state":null,"github-sync":"skipped","datadog-sync":"skipped",
      "errors":["consumer/derive-state.sh failed"]}'
  exit 3
}
DERIVED_STATE=$(echo "$DERIVED_JSON" | jq -r '.state')
log "Derived state: $DERIVED_STATE"

# ── Step 4: Datadog ───────────────────────────────────────────────────────────
DD_STATUS="success"
log "Sending Datadog metric..."
if ! bash "$DATADOG" \
    --issue          "$WORK_ITEM_ID" \
    --event          "$CE_TYPE" \
    --state          "$DERIVED_STATE" \
    --correlation-id "$CORRELATION_ID" >/dev/null 2>&1; then
  log "WARNING: Datadog sync failed (non-fatal)"
  DD_STATUS="error"
fi

# ── Step 5: GitHub sync ───────────────────────────────────────────────────────
GH_STATUS="success"
log "Syncing GitHub Project..."
if ! bash "$GITHUB" \
    --issue          "$WORK_ITEM_ID" \
    --state          "$DERIVED_STATE" \
    --last-event     "$CE_TYPE" \
    --correlation-id "$CORRELATION_ID" >/dev/null 2>&1; then
  log "WARNING: GitHub sync failed (non-fatal)"
  GH_STATUS="error"
fi

# ── Output ────────────────────────────────────────────────────────────────────
jq -n \
  --arg event_id       "$EVENT_ID" \
  --arg event_type     "$CE_TYPE" \
  --arg correlation_id "$CORRELATION_ID" \
  --arg derived_state  "$DERIVED_STATE" \
  --arg github_sync    "$GH_STATUS" \
  --arg datadog_sync   "$DD_STATUS" \
  '{
    "status":         "accepted",
    "event-id":       $event_id,
    "event-type":     $event_type,
    "correlation-id": $correlation_id,
    "derived-state":  $derived_state,
    "github-sync":    $github_sync,
    "datadog-sync":   $datadog_sync,
    "errors":         []
  }'
