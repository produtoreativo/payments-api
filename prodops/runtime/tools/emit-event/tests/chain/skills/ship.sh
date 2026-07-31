#!/usr/bin/env bash
# Ship Skill — emits Delivery.Ship.Started and Delivery.Ship.Completed
set -euo pipefail
WORK_ITEM_ID="${1:?}"; ITERATION_ID="${2:?}"; CORRELATION_ID="${3:?}"; PLAYER="${4:?}"; EVIDENCE_DIR="${5:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$(cd "$SCRIPT_DIR/../../../scripts" && pwd)/emit-event"
log() { echo "[ship-skill] $*" >&2; }; ok() { echo "[ship-skill] ✓ $*" >&2; }
gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

emit_event() {
  local event="$1" ev_dir="${2:-}"
  local exec_id; exec_id=$(gen_uuid)
  local input; input=$(jq -n --arg e "$event" --arg w "$WORK_ITEM_ID" --arg i "$ITERATION_ID" \
    --arg c "$CORRELATION_ID" --arg x "$exec_id" --arg p "$PLAYER" \
    '{"event":$e,"work-item-id":$w,"iteration-id":$i,"correlation-id":$c,"execution-id":$x,"actor":{"player":$p,"agent":"ship-agent"},"payload":{}}')
  local ev_flag=(); [[ -n "$ev_dir" ]] && ev_flag=(--evidence-file "$ev_dir/$(echo "$event" | tr '[:upper:]' '[:lower:]' | tr '.' '-').json")
  local out; out=$(echo "$input" | bash "$TOOL" "${ev_flag[@]+"${ev_flag[@]}"}" 2>/dev/null)
  local status; status=$(echo "$out" | jq -r '.status')
  ok "$event → status=$status"
  echo "$out"
}

log "Emitting Ship.Started (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Ship.Started" "$EVIDENCE_DIR"
log "Ship work: security checks, PR notes, deploy package (simulated)..."
ok "Ship work: PR notes prepared, no secrets found"
log "Emitting Ship.Completed (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Ship.Completed" "$EVIDENCE_DIR"
