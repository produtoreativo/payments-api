#!/usr/bin/env bash
# Runtime Event Dispatcher — EXP-015 Iteration 9
#
# Reads the subscription configuration and reacts to Delivery events by triggering
# Diligence skills. Delivery skills never call this dispatcher directly — they only
# emit facts via prodops_emit_event. The dispatcher is called by the Runtime after
# each event is processed.
#
# Usage:
#   bash dispatch.sh --event-type <cloud-event-type>
#                    --work-item-id <id>
#                    --correlation-id <uuid>
#                    --iteration-id <id>
#                    --player <claude|codex|copilot>
#                   [--evidence-dir <dir>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL_DIR="$(cd "$RUNTIME_DIR/tools/emit-event/scripts" && pwd)"
TOOL="$TOOL_DIR/emit-event"
SUBSCRIPTIONS="$RUNTIME_DIR/subscriptions/delivery-diligence.yaml"

EVENT_TYPE=""
WORK_ITEM_ID=""
CORRELATION_ID=""
ITERATION_ID=""
PLAYER="claude"
EVIDENCE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-type)     EVENT_TYPE="$2"; shift 2 ;;
    --work-item-id)   WORK_ITEM_ID="$2"; shift 2 ;;
    --correlation-id) CORRELATION_ID="$2"; shift 2 ;;
    --iteration-id)   ITERATION_ID="$2"; shift 2 ;;
    --player)         PLAYER="$2"; shift 2 ;;
    --evidence-dir)   EVIDENCE_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$EVENT_TYPE" ]]     && { echo "[dispatcher] Error: --event-type required" >&2; exit 1; }
[[ -z "$WORK_ITEM_ID" ]]   && { echo "[dispatcher] Error: --work-item-id required" >&2; exit 1; }
[[ -z "$CORRELATION_ID" ]] && { echo "[dispatcher] Error: --correlation-id required" >&2; exit 1; }

log()  { echo "[dispatcher] $*" >&2; }
ok()   { echo "[dispatcher] ✓ $*" >&2; }
skip() { echo "[dispatcher] — $*" >&2; }

gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

# ── Look up subscriptions for this event type ─────────────────────────────────
SUBSCRIBERS=$(python3 - "$SUBSCRIPTIONS" "$EVENT_TYPE" <<'PYEOF'
import sys, yaml
try:
    data = yaml.safe_load(open(sys.argv[1]))
    subs = data.get("subscriptions", {}).get(sys.argv[2], [])
    for s in subs:
        print(s)
except Exception as e:
    sys.exit(0)
PYEOF
)

if [[ -z "$SUBSCRIBERS" ]]; then
  skip "No subscriptions for event: $EVENT_TYPE"
  exit 0
fi

log "Dispatching for event: $EVENT_TYPE"
log "Subscribers: $(echo "$SUBSCRIBERS" | tr '\n' ' ')"

# ── Trigger each subscribed Diligence skill ───────────────────────────────────
emit_diligence_event() {
  local event="$1" agent="$2"
  local exec_id; exec_id=$(gen_uuid)
  local input; input=$(jq -n \
    --arg e "$event" --arg w "$WORK_ITEM_ID" --arg i "${ITERATION_ID:-diligence}" \
    --arg c "$CORRELATION_ID" --arg x "$exec_id" --arg p "$PLAYER" --arg a "$agent" \
    '{"event":$e,"work-item-id":$w,"iteration-id":$i,"correlation-id":$c,
      "execution-id":$x,"actor":{"player":$p,"agent":$a},"payload":{}}')
  local safe; safe=$(echo "$event" | tr '[:upper:]' '[:lower:]' | tr '.' '-')
  local ev_flag=(); [[ -n "$EVIDENCE_DIR" ]] && ev_flag=(--evidence-file "$EVIDENCE_DIR/${safe}.json")
  local out; out=$(echo "$input" | bash "$TOOL" "${ev_flag[@]+"${ev_flag[@]}"}" 2>/dev/null)
  local status; status=$(echo "$out" | jq -r '.status')
  ok "$event → status=$status"
}

# ── IMPORTANT — Signal events vs real work ────────────────────────────────────
#
# The events emitted below are LIFECYCLE SIGNALS, not evidence of completed work.
# They mark that the Diligence cycle was triggered and is expected to run.
#
# Semantics:
#   Diligence.Capture.Started   → Delivery event received; Diligence should capture
#   Diligence.Capture.Completed → Signal only; actual OBC capture must be done by
#                                  the agent executing diligence-sync/steps/capture/
#
# The agent executing the Diligence SKILL.md is responsible for:
#   1. Doing the real work (reading OBC, updating state, creating Work Items)
#   2. Emitting additional events (Scan, Flag, Repair, Close, Divergence.Detected)
#      as instructed by each step's SKILL.md
#
# Audit note: presence of Diligence.Capture.Completed in the timeline does NOT
# guarantee the OBC was updated — it guarantees the signal was sent.
# ─────────────────────────────────────────────────────────────────────────────

while IFS= read -r subscriber; do
  case "$subscriber" in
    diligence.capture)
      log "Signaling Diligence Capture (reactive to $EVENT_TYPE) — agent must execute real capture work"
      emit_diligence_event "Diligence.Capture.Started"    "diligence-capture-agent"
      emit_diligence_event "Diligence.Capture.Completed"  "diligence-capture-agent"
      ;;
    diligence.attach)
      log "Signaling Diligence Attach (reactive to $EVENT_TYPE) — agent must execute real attach work"
      emit_diligence_event "Diligence.Attach.Started"     "diligence-attach-agent"
      emit_diligence_event "Diligence.Attach.Completed"   "diligence-attach-agent"
      ;;
    diligence.promote)
      log "Signaling Diligence Promote (reactive to $EVENT_TYPE) — agent must execute real promote work"
      emit_diligence_event "Diligence.Promote.Started"    "diligence-promote-agent"
      emit_diligence_event "Diligence.Promote.Completed"  "diligence-promote-agent"
      ;;
    diligence.trail)
      log "Executing Diligence Trail — posting phase comment on plan-issue"
      bash "$SCRIPT_DIR/trail.sh" \
        --event-type     "$EVENT_TYPE" \
        --work-item-id   "$WORK_ITEM_ID" \
        --iteration-id   "${ITERATION_ID:-}" \
        --correlation-id "$CORRELATION_ID" \
        --player         "$PLAYER" || log "Warning: trail.sh failed (non-fatal)"
      ;;
    *)
      log "Warning: unknown subscriber '$subscriber' — skipped"
      ;;
  esac
done <<< "$SUBSCRIBERS"

log "Dispatch complete for $EVENT_TYPE"
