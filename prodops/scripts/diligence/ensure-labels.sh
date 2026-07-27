#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-labels.sh
#
# Idempotently creates or updates all canonical ProdOps labels in the repository.
# If a label exists with a different color or description, it is updated.
#
# Requirements:
#   - gh authenticated with repo permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   GITHUB_REPO=payments-api
#   API_VERSION=2026-03-10

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
GITHUB_REPO="${GITHUB_REPO:-payments-api}"
API_VERSION="${API_VERSION:-2026-03-10}"

REPO_PATH="${GITHUB_ORG}/${GITHUB_REPO}"

log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_command gh
require_command jq

log "Checking GitHub authentication..."
gh auth status >/dev/null 2>&1 || die "gh is not authenticated."

log "Checking repository access: ${REPO_PATH}..."
gh api "repos/${REPO_PATH}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  >/dev/null \
  || die "Cannot access repository ${REPO_PATH}."

# ── Label cache ──────────────────────────────────────────────────────────────

refresh_labels_cache() {
  EXISTING_LABELS="$(
    gh label list \
      --repo "${REPO_PATH}" \
      --json name,color,description \
      --limit 200
  )"
}

refresh_labels_cache

# ── Label helpers ─────────────────────────────────────────────────────────────

ensure_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  local existing_color existing_description
  existing_color="$(
    jq -r --arg name "${name}" \
      '.[] | select(.name == $name) | .color' \
      <<<"${EXISTING_LABELS}" | head -1
  )"
  existing_description="$(
    jq -r --arg name "${name}" \
      '.[] | select(.name == $name) | .description' \
      <<<"${EXISTING_LABELS}" | head -1
  )"

  if [[ -z "${existing_color}" ]]; then
    log "+ Creating label: \"${name}\""
    gh label create "${name}" \
      --repo "${REPO_PATH}" \
      --color "${color}" \
      --description "${description}"
    refresh_labels_cache
    return 0
  fi

  # Normalize colors for comparison (strip leading '#' if present).
  local norm_existing norm_expected
  norm_existing="${existing_color/#\#/}"
  norm_expected="${color/#\#/}"

  if [[ "${norm_existing,,}" == "${norm_expected,,}" && "${existing_description}" == "${description}" ]]; then
    log "✓ Label exists: \"${name}\""
    return 0
  fi

  log "~ Updating label: \"${name}\""
  gh label edit "${name}" \
    --repo "${REPO_PATH}" \
    --color "${color}" \
    --description "${description}"
  refresh_labels_cache
}

# ── Canonical ProdOps labels ──────────────────────────────────────────────────
# Source of truth: runtime/workspace/workspace.yaml > labels

log
log "Ensuring canonical ProdOps labels..."
log

log "── Journey ──────────────────────────────────────────────────────────────"
ensure_label "journey:delivery"   "0075ca" "Delivery Journey"
ensure_label "journey:diligence"  "e4e669" "Diligence Journey"
ensure_label "journey:assessment" "d93f0b" "Assessment Journey"

log
log "── Phase ────────────────────────────────────────────────────────────────"
ensure_label "phase:bootstrap" "bfd4f2" "Fase Bootstrap"
ensure_label "phase:hack"      "bfd4f2" "Fase Hack"
ensure_label "phase:sync"      "bfd4f2" "Fase Sync"
ensure_label "phase:finish"    "bfd4f2" "Fase Finish"
ensure_label "phase:ship"      "bfd4f2" "Fase Ship"
ensure_label "phase:validate"  "bfd4f2" "Fase Validate"
ensure_label "phase:promote"   "bfd4f2" "Fase Promote"

log
log "── Runtime ──────────────────────────────────────────────────────────────"
ensure_label "runtime:pilot"   "5319e7" "Piloto EXP-013"
ensure_label "runtime:task"    "8b5cf6" "Runtime Task (RT-01..RT-06)"
ensure_label "runtime:blocked" "b60205" "BLOCKED — Impediment ativo"
ensure_label "runtime:rework"  "fbca04" "Passou por ciclo de Rework"

log
log "── Severity ─────────────────────────────────────────────────────────────"
ensure_label "severity:high"   "b60205" "Severidade Alta — bloqueia fase ou critério de fracasso"
ensure_label "severity:medium" "fbca04" "Severidade Média — reparável, não bloqueia automaticamente"
ensure_label "severity:low"    "0e8a16" "Severidade Baixa — observacional"

log
log "── Finding ──────────────────────────────────────────────────────────────"
ensure_label "finding:drift"           "e11d48" "Drift entre COR e Derived State"
ensure_label "finding:missing-evidence" "dc2626" "Evidência obrigatória ausente"
ensure_label "finding:missing-event"   "ea580c" "Evento esperado ausente na Timeline"
ensure_label "finding:runtime-error"   "991b1b" "Falha no mecanismo do Runtime"
ensure_label "finding:manual-review"   "6b7280" "Revisão manual necessária"

log
log "── Evidence ─────────────────────────────────────────────────────────────"
ensure_label "evidence:missing"  "b60205" "Evidência obrigatória ainda não coletada"
ensure_label "evidence:partial"  "fbca04" "Evidência coletada parcialmente"
ensure_label "evidence:complete" "0e8a16" "Evidência completa e verificada"

log
log "Final labels:"
gh label list --repo "${REPO_PATH}" \
  --json name \
  --limit 200 \
  | jq -r '[.[] | .name] | sort | .[] | "  ✓ \(.)"'

log
log "Done."
