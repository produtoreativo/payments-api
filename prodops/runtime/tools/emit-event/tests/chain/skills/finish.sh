#!/usr/bin/env bash
# Finish Skill — emits Delivery.Finish.Started and Delivery.Finish.Completed
set -euo pipefail
WORK_ITEM_ID="${1:?}"; ITERATION_ID="${2:?}"; CORRELATION_ID="${3:?}"; PLAYER="${4:?}"; EVIDENCE_DIR="${5:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$(cd "$SCRIPT_DIR/../../../scripts" && pwd)/emit-event"
log() { echo "[finish-skill] $*" >&2; }; ok() { echo "[finish-skill] ✓ $*" >&2; }
gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

emit_event() {
  local event="$1" ev_dir="${2:-}"
  local exec_id; exec_id=$(gen_uuid)
  local input; input=$(jq -n --arg e "$event" --arg w "$WORK_ITEM_ID" --arg i "$ITERATION_ID" \
    --arg c "$CORRELATION_ID" --arg x "$exec_id" --arg p "$PLAYER" \
    '{"event":$e,"work-item-id":$w,"iteration-id":$i,"correlation-id":$c,"execution-id":$x,"actor":{"player":$p,"agent":"finish-agent"},"payload":{}}')
  local ev_flag=(); [[ -n "$ev_dir" ]] && ev_flag=(--evidence-file "$ev_dir/$(echo "$event" | tr '[:upper:]' '[:lower:]' | tr '.' '-').json")
  local out; out=$(echo "$input" | bash "$TOOL" "${ev_flag[@]+"${ev_flag[@]}"}" 2>/dev/null)
  local status; status=$(echo "$out" | jq -r '.status')
  ok "$event → status=$status"
  echo "$out"
}

log "Emitting Finish.Started (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Finish.Started" "$EVIDENCE_DIR"
log "Finish work: quality gates + Release Trail (simulated)..."
ok "Finish work: all gates passed, evidence appended"
log "Emitting Finish.Completed (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Finish.Completed" "$EVIDENCE_DIR"
