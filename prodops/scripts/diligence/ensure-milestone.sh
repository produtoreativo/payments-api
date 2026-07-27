#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-milestone.sh
#
# Idempotently creates a repository milestone for the ProdOps iteration.
#
# Requirements:
#   - gh authenticated with repo permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   GITHUB_REPO=payments-api
#   MILESTONE_TITLE=v0.1.0-runtime-pilot
#   MILESTONE_DESCRIPTION="..."
#   API_VERSION=2026-03-10

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
GITHUB_REPO="${GITHUB_REPO:-payments-api}"
MILESTONE_TITLE="${MILESTONE_TITLE:-v0.1.0-runtime-pilot}"
MILESTONE_DESCRIPTION="${MILESTONE_DESCRIPTION:-Runtime Validation Pilot — EXP-013. Agrupa Features, Runtime Tasks e Findings da Iteration IP-RUNTIME-001.}"
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

find_milestone_number() {
  gh api "repos/${REPO_PATH}/milestones?per_page=100&state=all" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    | jq -r --arg title "${MILESTONE_TITLE}" \
      '.[] | select(.title == $title) | .number | tostring' \
    | head -1
}

existing="$(find_milestone_number)"

if [[ -n "${existing}" ]]; then
  log "✓ Milestone exists: \"${MILESTONE_TITLE}\" (#${existing})"
  log
  log "Done."
  exit 0
fi

log "Creating milestone: \"${MILESTONE_TITLE}\"..."
result="$(
  gh api "repos/${REPO_PATH}/milestones" \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    -f title="${MILESTONE_TITLE}" \
    -f description="${MILESTONE_DESCRIPTION}" \
    -f state="open"
)"

number="$(jq -r '.number' <<<"${result}")"
url="$(jq -r '.html_url' <<<"${result}")"

log "  created: milestone #${number} — ${MILESTONE_TITLE}"
log "  url: ${url}"
log
log "Done."
