#!/usr/bin/env bash
# Diligence Trail — posts a phase comment on the iteration tracking issue.
# Called by dispatch.sh whenever a subscribed Delivery event matches diligence.trail.
#
# Usage:
#   bash trail.sh --event-type <cloud-event-type>
#                 --work-item-id <id|null>
#                 --iteration-id <id>
#                 --correlation-id <uuid>
#                 --player <claude|codex|copilot>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$RUNTIME_DIR/.." && pwd)"

EVENT_TYPE=""
WORK_ITEM_ID=""
ITERATION_ID=""
CORRELATION_ID=""
PLAYER="claude"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-type)     EVENT_TYPE="$2";     shift 2 ;;
    --work-item-id)   WORK_ITEM_ID="$2";   shift 2 ;;
    --iteration-id)   ITERATION_ID="$2";   shift 2 ;;
    --correlation-id) CORRELATION_ID="$2"; shift 2 ;;
    --player)         PLAYER="$2";         shift 2 ;;
    *) echo "[trail] Unknown arg: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[trail] $*" >&2; }

[[ -z "$EVENT_TYPE" ]]     && { log "Error: --event-type required"; exit 1; }
[[ -z "$ITERATION_ID" ]]   && { log "No --iteration-id — skipping trail"; exit 0; }

# ── Locate plan-bootstrap.json ───────────────────────────────────────────────
PLAN_BOOTSTRAP="$PRODOPS_DIR/artifacts/iterations/${ITERATION_ID}/runtime/plan-bootstrap.json"

if [[ ! -f "$PLAN_BOOTSTRAP" ]]; then
  log "plan-bootstrap.json not found — skipping trail (non-fatal)"
  exit 0
fi

PLAN_ISSUE=$(jq -r '."plan-issue" // empty' "$PLAN_BOOTSTRAP")
if [[ -z "$PLAN_ISSUE" ]]; then
  log "plan-issue not set in plan-bootstrap.json — skipping trail"
  exit 0
fi

# ── Select template by event type ────────────────────────────────────────────
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
ISSUE_LINE=""
[[ -n "$WORK_ITEM_ID" && "$WORK_ITEM_ID" != "null" && "$WORK_ITEM_ID" != "0" ]] \
  && ISSUE_LINE="**Issue:** #${WORK_ITEM_ID}"

case "$EVENT_TYPE" in
  prodops.delivery.plan.bootstrap.completed)
    ISSUES=$(jq -r '.issues // [] | join(", #")' "$PLAN_BOOTSTRAP")
    TITLE="Plan Bootstrap — Completed"
    BODY="Shared environment ready for iteration **${ITERATION_ID}**."$'\n'"**Issues in plan:** #${ISSUES}"
    ISSUE_LINE=""
    ;;
  prodops.delivery.plan.bootstrap.issue.entered)
    TITLE="Issue Entered Plan"
    BODY="Issue registered in iteration **${ITERATION_ID}** plan with \`oem-state: PENDING\`. Diligence.Capture triggered."
    ;;
  prodops.delivery.bootstrap.completed)
    TITLE="Bootstrap — Completed"
    BODY="Local environment validated. \`oem-state: BOOTSTRAPPING\`. Ready for Hack."
    ;;
  prodops.delivery.hack.completed)
    TITLE="Hack — Implementation Completed"
    BODY="All BDD scenarios green. Ready for Sync."
    ;;
  prodops.delivery.sync.completed)
    TITLE="Sync — PR Merged"
    BODY="Branch integrated. Ready for Finish."
    ;;
  prodops.delivery.finish.completed)
    TITLE="Finish — Quality Gates Passed"
    BODY="Tests, lint, and build clean. PR ready for Ship."
    ;;
  prodops.delivery.ship.completed)
    TITLE="Ship — Staging Deploy Completed"
    BODY="\`infra-scope\` confirmed. Ready for Validate."
    ;;
  prodops.delivery.validate.completed)
    TITLE="Validate — Criteria Confirmed"
    BODY="OBC criteria verified in staging environment."
    ;;
  prodops.delivery.plan.validated)
    TITLE="Plan Validated — Promote Gate Open"
    BODY="All issues in iteration **${ITERATION_ID}** validated. Promote unlocked for all."
    ISSUE_LINE=""
    ;;
  prodops.delivery.promote.completed)
    TITLE="Promote — DONE"
    BODY="\`oem-state: DONE\`. Issue closed on GitHub."
    ;;
  prodops.delivery.block.declared)
    TITLE="BLOCK DECLARED"
    BODY="Issue blocked. Check \`Block.Declared\` in the timeline for details and corrective action."
    ;;
  prodops.delivery.block.resolved)
    TITLE="Block Resolved"
    BODY="Issue unblocked. Flow resumed from Bootstrap."
    ;;
  prodops.delivery.restart.completed)
    TITLE="Restart Completed"
    BODY="New \`correlation-id\` generated. Timeline preserved. Flow restarted."
    ;;
  *)
    log "No trail template for event '$EVENT_TYPE' — skipping"
    exit 0
    ;;
esac

# ── Build comment body ────────────────────────────────────────────────────────
COMMENT="## ${TITLE} — ${NOW}"$'\n'
[[ -n "$ISSUE_LINE" ]] && COMMENT+="${ISSUE_LINE}"$'\n'
COMMENT+="**Event:** \`${EVENT_TYPE}\`"$'\n'
COMMENT+="**correlation-id:** \`${CORRELATION_ID}\`"$'\n\n'
COMMENT+="${BODY}"$'\n\n'
COMMENT+="---"$'\n'
COMMENT+="*iteration: ${ITERATION_ID} · actor: ${PLAYER} · diligence.trail*"

# ── Post comment ──────────────────────────────────────────────────────────────
log "Posting trail on issue #${PLAN_ISSUE} — ${TITLE}"
if gh issue comment "$PLAN_ISSUE" --body "$COMMENT" >/dev/null 2>&1; then
  log "✓ Comment posted on #${PLAN_ISSUE}"
else
  log "Warning: gh issue comment failed for #${PLAN_ISSUE} (non-fatal)"
fi
