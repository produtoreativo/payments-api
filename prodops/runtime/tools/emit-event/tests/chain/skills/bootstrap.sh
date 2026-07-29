#!/usr/bin/env bash
# Bootstrap Skill — emits Delivery.Bootstrap.Started and Delivery.Bootstrap.Completed
# Called by run-chain.sh with a shared correlation-id.
#
# Usage: bash bootstrap.sh <work-item-id> <iteration-id> <correlation-id> <player> [evidence-dir]
#
# Exit codes:
#   0  Bootstrap.Completed accepted
#   1  Bootstrap.Started rejected
#   2  Bootstrap work failed
#   3  Bootstrap.Completed rejected

set -euo pipefail

WORK_ITEM_ID="${1:?work-item-id required}"
ITERATION_ID="${2:?iteration-id required}"
CORRELATION_ID="${3:?correlation-id required}"
PLAYER="${4:?player required}"
EVIDENCE_DIR="${5:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$(cd "$CHAIN_DIR/.." && pwd)"
TOOL="$(cd "$TESTS_DIR/../scripts" && pwd)/emit-event"

log() { echo "[bootstrap-skill] $*" >&2; }
ok()  { echo "[bootstrap-skill] ✓ $*" >&2; }
err() { echo "[bootstrap-skill] ✗ $*" >&2; }

gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

# ── Hack.Started ──────────────────────────────────────────────────────────────
log "Emitting Bootstrap.Started (correlation-id=$CORRELATION_ID)"
EXEC_ID_STARTED=$(gen_uuid)

STARTED_INPUT=$(jq -n \
  --arg event          "Delivery.Bootstrap.Started" \
  --arg work_item_id   "$WORK_ITEM_ID" \
  --arg iteration_id   "$ITERATION_ID" \
  --arg correlation_id "$CORRELATION_ID" \
  --arg execution_id   "$EXEC_ID_STARTED" \
  --arg player         "$PLAYER" \
  '{
    "event": $event,
    "work-item-id": $work_item_id,
    "iteration-id": $iteration_id,
    "correlation-id": $correlation_id,
    "execution-id": $execution_id,
    "actor": {"player": $player, "agent": "bootstrap-agent"},
    "payload": {}
  }')

EVIDENCE_FLAG=()
[[ -n "$EVIDENCE_DIR" ]] && EVIDENCE_FLAG=(--evidence-file "$EVIDENCE_DIR/bootstrap-started.json")

set +e
STARTED_OUT=$(echo "$STARTED_INPUT" | bash "$TOOL" "${EVIDENCE_FLAG[@]+"${EVIDENCE_FLAG[@]}"}" 2>/dev/null)
STARTED_EXIT=$?
set -e

if [[ $STARTED_EXIT -ne 0 ]]; then
  err "Bootstrap.Started rejected (exit $STARTED_EXIT)"
  echo "$STARTED_OUT" >&2
  exit 1
fi
STARTED_STATUS=$(echo "$STARTED_OUT" | jq -r '.status')
ok "Bootstrap.Started → status=$STARTED_STATUS"

# ── Bootstrap work (simulated) ────────────────────────────────────────────────
log "Bootstrap work: verifying environment..."
# In a real execution the skill checks runtimes, deps, smoke gate.
# Here we simulate the work succeeding in the experiment context.
log "Bootstrap work: node=$(node --version 2>/dev/null || echo 'not found'), git=$(git --version | cut -d' ' -f3)"
log "Bootstrap work: smoke gate skipped (experiment mode)"
ok "Bootstrap work: environment ready"

# ── Bootstrap.Completed ───────────────────────────────────────────────────────
log "Emitting Bootstrap.Completed (correlation-id=$CORRELATION_ID)"
EXEC_ID_COMPLETED=$(gen_uuid)

COMPLETED_INPUT=$(jq -n \
  --arg event          "Delivery.Bootstrap.Completed" \
  --arg work_item_id   "$WORK_ITEM_ID" \
  --arg iteration_id   "$ITERATION_ID" \
  --arg correlation_id "$CORRELATION_ID" \
  --arg execution_id   "$EXEC_ID_COMPLETED" \
  --arg player         "$PLAYER" \
  '{
    "event": $event,
    "work-item-id": $work_item_id,
    "iteration-id": $iteration_id,
    "correlation-id": $correlation_id,
    "execution-id": $execution_id,
    "actor": {"player": $player, "agent": "bootstrap-agent"},
    "payload": {}
  }')

EVIDENCE_FLAG=()
[[ -n "$EVIDENCE_DIR" ]] && EVIDENCE_FLAG=(--evidence-file "$EVIDENCE_DIR/bootstrap-completed.json")

set +e
COMPLETED_OUT=$(echo "$COMPLETED_INPUT" | bash "$TOOL" "${EVIDENCE_FLAG[@]+"${EVIDENCE_FLAG[@]}"}" 2>/dev/null)
COMPLETED_EXIT=$?
set -e

if [[ $COMPLETED_EXIT -ne 0 ]]; then
  err "Bootstrap.Completed rejected (exit $COMPLETED_EXIT)"
  echo "$COMPLETED_OUT" >&2
  exit 3
fi
COMPLETED_STATUS=$(echo "$COMPLETED_OUT" | jq -r '.status')
ok "Bootstrap.Completed → status=$COMPLETED_STATUS"

# Print both outputs for runner to inspect
echo "$STARTED_OUT"
echo "$COMPLETED_OUT"
