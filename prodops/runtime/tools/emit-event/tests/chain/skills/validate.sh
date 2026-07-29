#!/usr/bin/env bash
# Validate Skill — emits Validate.Started, Shared.Gate.Passed, and Validate.Completed
# Supports --incomplete flag: emits only Validate.Started (gate probe for Iteration 8)
set -euo pipefail
WORK_ITEM_ID="${1:?}"; ITERATION_ID="${2:?}"; CORRELATION_ID="${3:?}"; PLAYER="${4:?}"; EVIDENCE_DIR="${5:-}"; INCOMPLETE="${6:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$(cd "$SCRIPT_DIR/../../../scripts" && pwd)/emit-event"
log() { echo "[validate-skill] $*" >&2; }; ok() { echo "[validate-skill] ✓ $*" >&2; }
gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

emit_event() {
  local event="$1" agent="$2" ev_dir="${3:-}"
  local exec_id; exec_id=$(gen_uuid)
  local input; input=$(jq -n --arg e "$event" --arg w "$WORK_ITEM_ID" --arg i "$ITERATION_ID" \
    --arg c "$CORRELATION_ID" --arg x "$exec_id" --arg p "$PLAYER" --arg a "$agent" \
    '{"event":$e,"work-item-id":$w,"iteration-id":$i,"correlation-id":$c,"execution-id":$x,"actor":{"player":$p,"agent":$a},"payload":{}}')
  local safe_name; safe_name=$(echo "$event" | tr '[:upper:]' '[:lower:]' | tr '.' '-')
  local ev_flag=(); [[ -n "$ev_dir" ]] && ev_flag=(--evidence-file "$ev_dir/${safe_name}.json")
  local out; out=$(echo "$input" | bash "$TOOL" "${ev_flag[@]+"${ev_flag[@]}"}" 2>/dev/null)
  local status; status=$(echo "$out" | jq -r '.status')
  ok "$event → status=$status"
  echo "$out"
}

log "Emitting Validate.Started (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Validate.Started" "validate-agent" "$EVIDENCE_DIR"

if [[ "$INCOMPLETE" == "--incomplete" ]]; then
  echo "[validate-skill] ⚠ Incomplete mode: acceptance evidence not sufficient — Gate.Passed and Validate.Completed will NOT be emitted" >&2
  echo "[validate-skill] ⚠ Timeline will contain Validate.Started but NOT Validate.Completed" >&2
  exit 2
fi

log "Validate work: acceptance evidence, SLOs, metrics (simulated)..."
ok "Validate work: evidence collected, quality gates passed"
log "Emitting Shared.Gate.Passed (quality gate evidence confirmed)"
emit_event "Shared.Gate.Passed" "validate-agent" "$EVIDENCE_DIR"
log "Emitting Validate.Completed (correlation-id=$CORRELATION_ID)"
emit_event "Delivery.Validate.Completed" "validate-agent" "$EVIDENCE_DIR"
