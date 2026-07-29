#!/usr/bin/env bash
# Full Delivery Chain Runner — Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
# EXP-015 Iterations 6 & 7
#
# One correlation-id for the full flow; execution-id distinct per tool invocation.
# Runner does not build events — skills do.
#
# Usage:
#   bash run-chain.sh [--player <claude|codex|copilot>]
#                     [--work-item-id <id>] [--iteration-id <id>]
#                     [--evidence-dir <dir>]
#                     [--incomplete-hack]    # stop after Hack.Started (quality gate probe)
#                     [--stop-after <phase>] # stop after phase: bootstrap|hack|sync|finish|ship|validate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"
# Dispatcher is now called from within the Runtime pipeline (emit-event Step 6).
# The runner does NOT call the dispatcher directly.

PLAYER="claude"
WORK_ITEM_ID="999"
ITERATION_ID="IP-EXP015-CHAIN"
INCOMPLETE_HACK="false"
INCOMPLETE_VALIDATE="false"
STOP_AFTER=""
EVIDENCE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --player)               PLAYER="$2"; shift 2 ;;
    --work-item-id)         WORK_ITEM_ID="$2"; shift 2 ;;
    --iteration-id)         ITERATION_ID="$2"; shift 2 ;;
    --incomplete-hack)      INCOMPLETE_HACK="true"; shift ;;
    --incomplete-validate)  INCOMPLETE_VALIDATE="true"; shift ;;
    --stop-after)           STOP_AFTER="$2"; shift 2 ;;
    --evidence-dir)         EVIDENCE_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
log()  { echo -e "${YELLOW}[chain-runner]${NC} $*"; }
ok()   { echo -e "${GREEN}[chain-runner] ✓${NC} $*"; }
fail() { echo -e "${RED}[chain-runner] ✗${NC} $*"; }

gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

# ── One correlation-id for the full Delivery flow ────────────────────────────
FLOW_CORR_ID=$(gen_uuid)

MODE="FULL HAPPY PATH (7 phases, 15 events)"
[[ "$INCOMPLETE_HACK" == "true" ]] && MODE="INCOMPLETE HACK PROBE"
[[ "$INCOMPLETE_VALIDATE" == "true" ]] && MODE="INCOMPLETE VALIDATE PROBE (Iteration 8)"
[[ -n "$STOP_AFTER" ]] && MODE="PARTIAL (stop after $STOP_AFTER)"

echo
echo "════════════════════════════════════════════════════════════════"
echo "  Full Delivery Chain Runner — EXP-015                         "
echo "════════════════════════════════════════════════════════════════"
echo "  player          = $PLAYER"
echo "  work-item-id    = $WORK_ITEM_ID"
echo "  iteration-id    = $ITERATION_ID"
echo "  correlation-id  = $FLOW_CORR_ID"
echo "  mode            = $MODE"
[[ -n "$EVIDENCE_DIR" ]] && echo "  evidence-dir    = $EVIDENCE_DIR"
echo "════════════════════════════════════════════════════════════════"
echo

[[ -n "$EVIDENCE_DIR" ]] && mkdir -p "$EVIDENCE_DIR"

# Helper: invoke a skill script, check exit code, read evidence status
run_skill() {
  local phase="$1"
  local skill_script="$SKILLS_DIR/${phase}.sh"
  local ev_dir="$EVIDENCE_DIR"

  log "Invoking ${phase} skill..."

  set +e
  bash "$skill_script" "$WORK_ITEM_ID" "$ITERATION_ID" "$FLOW_CORR_ID" "$PLAYER" "$ev_dir" \
    2>&1 >/dev/null
  local exit_code=$?
  set -e

  if [[ $exit_code -ne 0 ]]; then
    fail "${phase} skill failed (exit $exit_code)"
    exit 1
  fi
  ok "${phase} skill completed"
  echo
}

# ── Phase 1: Bootstrap ───────────────────────────────────────────────────────
log "Invoking bootstrap skill..."
set +e
bash "$SKILLS_DIR/bootstrap.sh" \
  "$WORK_ITEM_ID" "$ITERATION_ID" "$FLOW_CORR_ID" "$PLAYER" "$EVIDENCE_DIR" \
  2>&1 >/dev/null
BOOTSTRAP_EXIT=$?
set -e
[[ $BOOTSTRAP_EXIT -ne 0 ]] && { fail "bootstrap skill failed (exit $BOOTSTRAP_EXIT)"; exit 1; }
ok "bootstrap skill completed"
echo
[[ "$STOP_AFTER" == "bootstrap" ]] && { log "Stopped after bootstrap (--stop-after)"; exit 0; }

# ── Phase 2: Hack ────────────────────────────────────────────────────────────
log "Invoking hack skill..."
HACK_INCOMPLETE_FLAG=""
[[ "$INCOMPLETE_HACK" == "true" ]] && HACK_INCOMPLETE_FLAG="--incomplete"
set +e
bash "$SKILLS_DIR/hack.sh" \
  "$WORK_ITEM_ID" "$ITERATION_ID" "$FLOW_CORR_ID" "$PLAYER" "$EVIDENCE_DIR" \
  "$HACK_INCOMPLETE_FLAG" 2>&1 >/dev/null
HACK_EXIT=$?
set -e

if [[ "$INCOMPLETE_HACK" == "true" ]]; then
  [[ $HACK_EXIT -ne 2 ]] && { fail "hack incomplete probe unexpected exit: $HACK_EXIT"; exit 1; }
  ok "hack skill: incomplete execution confirmed (quality gate not met — Hack.Completed NOT emitted)"
else
  [[ $HACK_EXIT -ne 0 ]] && { fail "hack skill failed (exit $HACK_EXIT)"; exit 1; }
  ok "hack skill completed"
fi
echo
[[ "$INCOMPLETE_HACK" == "true" || "$STOP_AFTER" == "hack" ]] && {
  log "Stopped after hack"
  # Fall through to timeline verification
}

if [[ "$INCOMPLETE_HACK" == "false" && "$STOP_AFTER" != "hack" ]]; then

# ── Phase 3: Sync ────────────────────────────────────────────────────────────
run_skill "sync"
[[ "$STOP_AFTER" == "sync" ]] && { log "Stopped after sync (--stop-after)"; exit 0; }

# ── Phase 4: Finish ──────────────────────────────────────────────────────────
run_skill "finish"
[[ "$STOP_AFTER" == "finish" ]] && { log "Stopped after finish (--stop-after)"; exit 0; }

# ── Phase 5: Ship ────────────────────────────────────────────────────────────
run_skill "ship"
[[ "$STOP_AFTER" == "ship" ]] && { log "Stopped after ship (--stop-after)"; exit 0; }

# ── Phase 6: Validate ────────────────────────────────────────────────────────
log "Invoking validate skill..."
VALIDATE_INCOMPLETE_FLAG=""
[[ "$INCOMPLETE_VALIDATE" == "true" ]] && VALIDATE_INCOMPLETE_FLAG="--incomplete"
set +e
bash "$SKILLS_DIR/validate.sh" \
  "$WORK_ITEM_ID" "$ITERATION_ID" "$FLOW_CORR_ID" "$PLAYER" "$EVIDENCE_DIR" \
  "$VALIDATE_INCOMPLETE_FLAG" 2>&1 >/dev/null
VALIDATE_EXIT=$?
set -e
if [[ "$INCOMPLETE_VALIDATE" == "true" ]]; then
  [[ $VALIDATE_EXIT -ne 2 ]] && { fail "validate incomplete probe unexpected exit: $VALIDATE_EXIT"; exit 1; }
  ok "validate skill: incomplete execution confirmed (evidence insufficient — Validate.Completed NOT emitted)"
else
  [[ $VALIDATE_EXIT -ne 0 ]] && { fail "validate skill failed (exit $VALIDATE_EXIT)"; exit 1; }
  ok "validate skill completed"
fi
echo
[[ "$STOP_AFTER" == "validate" || "$INCOMPLETE_VALIDATE" == "true" ]] && {
  log "Stopped after validate"
}

# ── Phase 7: Promote ─────────────────────────────────────────────────────────
if [[ "$INCOMPLETE_VALIDATE" == "false" ]]; then
  run_skill "promote"
fi

fi  # end of full path (incomplete hack check)

# ── Verify timeline ──────────────────────────────────────────────────────────
TIMELINE_FILE="$REPO_ROOT/prodops/artifacts/runtime/timelines/${WORK_ITEM_ID}.json"
log "Verifying timeline: $TIMELINE_FILE"
[[ ! -f "$TIMELINE_FILE" ]] && { fail "Timeline file not found: $TIMELINE_FILE"; exit 1; }

TOTAL_EVENTS=$(jq 'length' "$TIMELINE_FILE")
CORR_EVENTS=$(jq --arg cid "$FLOW_CORR_ID" \
  '[.[] | select(.data["runtime-correlation-id"] == $cid)] | length' "$TIMELINE_FILE")

log "Timeline total events: $TOTAL_EVENTS"
log "Events for this flow (correlation-id=$FLOW_CORR_ID): $CORR_EVENTS"

FLOW_EVENT_TYPES=$(jq -r --arg cid "$FLOW_CORR_ID" \
  '[.[] | select(.data["runtime-correlation-id"] == $cid) | .type] | .[]' \
  "$TIMELINE_FILE")
log "Event types in this flow:"
while IFS= read -r t; do log "  • $t"; done <<< "$FLOW_EVENT_TYPES"

echo
echo "════════════════════════════════════════════════════════════════"

if [[ "$INCOMPLETE_HACK" == "true" ]]; then
  # Probe: expect only 3 events (Bootstrap.Started + Bootstrap.Completed + Hack.Started)
  HAS_HACK_COMPLETED=$(jq --arg cid "$FLOW_CORR_ID" \
    '[.[] | select(.data["runtime-correlation-id"] == $cid and (.type | test("hack.completed")))] | length' \
    "$TIMELINE_FILE")
  ok "Chain run complete — INCOMPLETE HACK PROBE"
  log "Expected: Bootstrap.Started + Bootstrap.Completed + Hack.Started (3 events)"
  log "NOT expected: Hack.Completed"
  if [[ "$HAS_HACK_COMPLETED" -eq 0 ]]; then
    ok "CONFIRMED: Hack.Completed not in timeline (events in flow: $CORR_EVENTS)"
  else
    fail "Hack.Completed found in timeline — probe failed"
    exit 1
  fi

elif [[ "$INCOMPLETE_VALIDATE" == "true" ]]; then
  # Probe: expect Bootstrap→Hack→Sync→Finish→Ship→Validate.Started (11 events, no Gate.Passed or Validate.Completed)
  HAS_VALIDATE_COMPLETED=$(jq --arg cid "$FLOW_CORR_ID" \
    '[.[] | select(.data["runtime-correlation-id"] == $cid and (.type | test("validate.completed")))] | length' \
    "$TIMELINE_FILE")
  HAS_GATE_PASSED=$(jq --arg cid "$FLOW_CORR_ID" \
    '[.[] | select(.data["runtime-correlation-id"] == $cid and (.type | test("gate.passed")))] | length' \
    "$TIMELINE_FILE")
  ok "Chain run complete — INCOMPLETE VALIDATE PROBE (Iteration 8)"
  log "Expected: 11 events through Validate.Started (no Gate.Passed, no Validate.Completed)"
  log "Events in flow: $CORR_EVENTS"
  if [[ "$HAS_VALIDATE_COMPLETED" -eq 0 && "$HAS_GATE_PASSED" -eq 0 ]]; then
    ok "CONFIRMED: Validate.Completed and Gate.Passed NOT in timeline"
    ok "Validate.Started emitted; runtime shows partial execution"
  else
    fail "Validate.Completed or Gate.Passed found — probe failed"
    exit 1
  fi

elif [[ -n "$STOP_AFTER" ]]; then
  ok "Chain run complete — PARTIAL (stopped after $STOP_AFTER)"
  log "Events in this flow: $CORR_EVENTS (partial — full 15-event check skipped)"
  ok "CONFIRMED: $CORR_EVENTS events in timeline for this flow"

else
  # Full path: expect all 15 events
  EXPECTED=15
  ok "Chain run complete — FULL HAPPY PATH"
  log "Expected: 15 events (7 phases × 2 + Gate.Passed)"

  HAS_ALL=$(jq --arg cid "$FLOW_CORR_ID" \
    '[.[] | select(.data["runtime-correlation-id"] == $cid) | .type] |
     (contains(["prodops.delivery.bootstrap.started"]) and
      contains(["prodops.delivery.bootstrap.completed"]) and
      contains(["prodops.delivery.hack.started"]) and
      contains(["prodops.delivery.hack.completed"]) and
      contains(["prodops.delivery.sync.started"]) and
      contains(["prodops.delivery.sync.completed"]) and
      contains(["prodops.delivery.finish.started"]) and
      contains(["prodops.delivery.finish.completed"]) and
      contains(["prodops.delivery.ship.started"]) and
      contains(["prodops.delivery.ship.completed"]) and
      contains(["prodops.delivery.validate.started"]) and
      contains(["prodops.shared.gate.passed"]) and
      contains(["prodops.delivery.validate.completed"]) and
      contains(["prodops.delivery.promote.started"]) and
      contains(["prodops.delivery.promote.completed"]))' \
    "$TIMELINE_FILE")

  if [[ "$HAS_ALL" == "true" && "$CORR_EVENTS" -eq "$EXPECTED" ]]; then
    ok "CONFIRMED: all 15 events present in timeline"
  elif [[ "$HAS_ALL" == "true" ]]; then
    ok "CONFIRMED: all 15 event types present (total events in flow: $CORR_EVENTS)"
  else
    fail "Not all 15 events found in timeline (found: $CORR_EVENTS events in flow)"
    jq --arg cid "$FLOW_CORR_ID" \
      '[.[] | select(.data["runtime-correlation-id"] == $cid) | .type]' \
      "$TIMELINE_FILE"
    exit 1
  fi
fi

echo "════════════════════════════════════════════════════════════════"
