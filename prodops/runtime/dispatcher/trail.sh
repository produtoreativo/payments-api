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
    TITLE="🚀 Plan Bootstrap — Concluído"
    BODY="Ambiente compartilhado pronto para a iteração **${ITERATION_ID}**."$'\n'"**Issues no plano:** #${ISSUES}"
    ISSUE_LINE=""
    ;;
  prodops.delivery.plan.bootstrap.issue.entered)
    TITLE="📋 Issue Entrou no Plano"
    BODY="Issue registrada no plano da iteração **${ITERATION_ID}** com \`oem-state: PENDING\`. Diligence.Capture acionado."
    ;;
  prodops.delivery.bootstrap.completed)
    TITLE="⚙️ Bootstrap — Concluído"
    BODY="Ambiente local validado. \`oem-state: BOOTSTRAPPING\`. Pronto para Hack."
    ;;
  prodops.delivery.hack.completed)
    TITLE="🔨 Hack — Implementação Concluída"
    BODY="Todos os cenários BDD verdes. Pronto para Sync."
    ;;
  prodops.delivery.sync.completed)
    TITLE="🔀 Sync — PR Aprovado e Merged"
    BODY="Branch integrada ao \`master\`. Pronto para Finish."
    ;;
  prodops.delivery.finish.completed)
    TITLE="✅ Finish — Quality Gates Passaram"
    BODY="Testes, lint e build limpos. PR pronto para Ship."
    ;;
  prodops.delivery.ship.completed)
    TITLE="🚢 Ship — Deploy Staging Concluído"
    BODY="\`infra-scope\` confirmado. Pronto para Validate."
    ;;
  prodops.delivery.validate.completed)
    TITLE="🔍 Validate — Critérios Confirmados"
    BODY="Critérios OBC verificados no ambiente de staging."
    ;;
  prodops.delivery.plan.validated)
    TITLE="🎯 Plan Validated — Gate de Promote Aberto"
    BODY="Todas as issues da iteração **${ITERATION_ID}** validadas. Promote liberado para todas."
    ISSUE_LINE=""
    ;;
  prodops.delivery.promote.completed)
    TITLE="🏁 Promote — DONE"
    BODY="\`oem-state: DONE\`. Issue fechada no GitHub."
    ;;
  prodops.delivery.block.declared)
    TITLE="🚨 BLOQUEIO DECLARADO"
    BODY="Issue bloqueada. Verificar \`Block.Declared\` na timeline para detalhes e ação corretiva."
    ;;
  prodops.delivery.block.resolved)
    TITLE="✅ Bloqueio Resolvido"
    BODY="Issue desbloqueada. Flow retomado a partir do Bootstrap."
    ;;
  prodops.delivery.restart.completed)
    TITLE="🔄 Restart Concluído"
    BODY="Novo \`correlation-id\` gerado. Timeline preservada. Fluxo reiniciado."
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
