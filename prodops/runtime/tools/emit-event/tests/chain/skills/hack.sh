#!/usr/bin/env bash
# Hack Skill — emits Delivery.Hack.Started and optionally Delivery.Hack.Completed
# Called by run-chain.sh with a shared correlation-id.
#
# Usage:
#   bash hack.sh <work-item-id> <iteration-id> <correlation-id> <player> [evidence-dir] [--incomplete]
#
# --incomplete: emits only Hack.Started (simulates quality gate not met).
#
# Exit codes:
#   0  Hack.Completed accepted (or --incomplete: Hack.Started accepted)
#   1  Hack.Started rejected
#   2  Quality gate not met (incomplete mode)
#   3  Hack.Completed rejected

set -euo pipefail

WORK_ITEM_ID="${1:?work-item-id required}"
ITERATION_ID="${2:?iteration-id required}"
CORRELATION_ID="${3:?correlation-id required}"
PLAYER="${4:?player required}"
EVIDENCE_DIR="${5:-}"
INCOMPLETE="${6:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$(cd "$CHAIN_DIR/.." && pwd)"
TOOL="$(cd "$TESTS_DIR/../scripts" && pwd)/emit-event"

log() { echo "[hack-skill] $*" >&2; }
ok()  { echo "[hack-skill] ✓ $*" >&2; }
err() { echo "[hack-skill] ✗ $*" >&2; }
warn(){ echo "[hack-skill] ⚠ $*" >&2; }

gen_uuid() { python3 -c "import uuid; print(uuid.uuid4())"; }

# ── Hack.Started ──────────────────────────────────────────────────────────────
log "Emitting Hack.Started (correlation-id=$CORRELATION_ID)"
EXEC_ID_STARTED=$(gen_uuid)

STARTED_INPUT=$(jq -n \
  --arg event          "Delivery.Hack.Started" \
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
    "actor": {"player": $player, "agent": "hack-agent"},
    "payload": {}
  }')

EVIDENCE_FLAG=()
[[ -n "$EVIDENCE_DIR" ]] && EVIDENCE_FLAG=(--evidence-file "$EVIDENCE_DIR/hack-started.json")

set +e
STARTED_OUT=$(echo "$STARTED_INPUT" | bash "$TOOL" "${EVIDENCE_FLAG[@]+"${EVIDENCE_FLAG[@]}"}" 2>/dev/null)
STARTED_EXIT=$?
set -e

if [[ $STARTED_EXIT -ne 0 ]]; then
  err "Hack.Started rejected (exit $STARTED_EXIT)"
  echo "$STARTED_OUT" >&2
  exit 1
fi
STARTED_STATUS=$(echo "$STARTED_OUT" | jq -r '.status')
ok "Hack.Started → status=$STARTED_STATUS"

# ── Incomplete probe: exit after Started ──────────────────────────────────────
if [[ "$INCOMPLETE" == "--incomplete" ]]; then
  warn "Incomplete mode: quality gate not satisfied — Hack.Completed will NOT be emitted"
  warn "Timeline will contain Hack.Started but NOT Hack.Completed"
  echo "$STARTED_OUT"
  exit 2
fi

# ── Hack work (simulated) ─────────────────────────────────────────────────────
log "Hack work: TDD cycle (simulated)..."
log "Hack work: Red → Green → Yellow"
log "Hack work: quality gates — lint OK, no forbidden mocks, Release Trail appended"
ok "Hack work: all quality gates passed"

# ── Hack.Completed ────────────────────────────────────────────────────────────
log "Emitting Hack.Completed (correlation-id=$CORRELATION_ID)"
EXEC_ID_COMPLETED=$(gen_uuid)

COMPLETED_INPUT=$(jq -n \
  --arg event          "Delivery.Hack.Completed" \
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
    "actor": {"player": $player, "agent": "hack-agent"},
    "payload": {}
  }')

EVIDENCE_FLAG=()
[[ -n "$EVIDENCE_DIR" ]] && EVIDENCE_FLAG=(--evidence-file "$EVIDENCE_DIR/hack-completed.json")

set +e
COMPLETED_OUT=$(echo "$COMPLETED_INPUT" | bash "$TOOL" "${EVIDENCE_FLAG[@]+"${EVIDENCE_FLAG[@]}"}" 2>/dev/null)
COMPLETED_EXIT=$?
set -e

if [[ $COMPLETED_EXIT -ne 0 ]]; then
  err "Hack.Completed rejected (exit $COMPLETED_EXIT)"
  echo "$COMPLETED_OUT" >&2
  exit 3
fi
COMPLETED_STATUS=$(echo "$COMPLETED_OUT" | jq -r '.status')
ok "Hack.Completed → status=$COMPLETED_STATUS"

echo "$STARTED_OUT"
echo "$COMPLETED_OUT"
