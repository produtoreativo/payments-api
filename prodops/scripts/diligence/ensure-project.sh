#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-project.sh
#
# Idempotently creates an organization-owned GitHub Projects v2 project
# with title, short description, and public visibility.
#
# Requirements:
#   - gh authenticated with Projects (admin:org or project:write) permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   PROJECT_TITLE="ProdOps — payments-api"
#   PROJECT_DESCRIPTION="..."

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
PROJECT_TITLE="${PROJECT_TITLE:-ProdOps — payments-api}"
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-Canonical Operational Representation do ProdOps Runtime no payments-api. Espelho de Derived State calculado a partir da Operational Timeline — não é fonte de verdade.}"

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

find_project_number() {
  gh project list --owner "${GITHUB_ORG}" --format json --limit 100 \
    | jq -r --arg title "${PROJECT_TITLE}" \
      '.projects[] | select(.title == $title) | .number | tostring' \
    | head -1
}

existing="$(find_project_number)"

if [[ -n "${existing}" ]]; then
  log "✓ Project exists: \"${PROJECT_TITLE}\" (#${existing})"
  log
  log "Done."
  exit 0
fi

log "Creating project: \"${PROJECT_TITLE}\"..."
result="$(gh project create --owner "${GITHUB_ORG}" --title "${PROJECT_TITLE}" --format json)"
project_id="$(jq -r '.id' <<<"${result}")"
project_number="$(jq -r '.number' <<<"${result}")"

[[ -n "${project_id}" && "${project_id}" != "null" ]] \
  || die "Project created but node ID not returned."

log "Setting short description..."
gh api graphql \
  -f query='
    mutation($id: ID!, $desc: String!) {
      updateProjectV2(input: { projectId: $id, shortDescription: $desc }) {
        projectV2 { number title }
      }
    }
  ' \
  -f id="${project_id}" \
  -f desc="${PROJECT_DESCRIPTION:0:255}" \
  --jq '"  created: project #\(.data.updateProjectV2.projectV2.number) — \(.data.updateProjectV2.projectV2.title)"'

log
log "Project URL: https://github.com/orgs/${GITHUB_ORG}/projects/${project_number}"
log
log "Done."
