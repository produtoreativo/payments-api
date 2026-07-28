#!/usr/bin/env bash
set -Eeuo pipefail

# delete-project.sh
#
# Permanently deletes an organization-owned GitHub Projects v2 project.
# This operation is IRREVERSIBLE — all views, field values, and item memberships
# are destroyed. Issues in the repository are NOT deleted.
#
# Requires explicit confirmation unless --force is passed.
#
# Requirements:
#   - gh authenticated with Projects (admin:org or project:admin) permission
#   - jq
#
# Usage:
#   ./delete-project.sh
#   ./delete-project.sh --force
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   PROJECT_NUMBER=24

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
PROJECT_NUMBER="${PROJECT_NUMBER:-24}"
FORCE=0

for arg in "$@"; do
  case "${arg}" in
    --force|-f) FORCE=1 ;;
    *) printf 'ERROR: Unknown argument: %s\n' "${arg}" >&2; exit 1 ;;
  esac
done

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

log "Resolving project ${GITHUB_ORG}/#${PROJECT_NUMBER}..."

project_info="$(
  gh api graphql \
    -f query='
      query($org: String!, $number: Int!) {
        organization(login: $org) {
          projectV2(number: $number) {
            id
            title
            url
            items(first: 1) { totalCount }
            views(first: 1) { totalCount }
          }
        }
      }
    ' \
    -F org="${GITHUB_ORG}" \
    -F number="${PROJECT_NUMBER}" \
    --jq '.data.organization.projectV2'
)"

project_id="$(jq -r '.id' <<<"${project_info}")"
project_title="$(jq -r '.title' <<<"${project_info}")"
project_url="$(jq -r '.url' <<<"${project_info}")"
item_count="$(jq -r '.items.totalCount' <<<"${project_info}")"
view_count="$(jq -r '.views.totalCount' <<<"${project_info}")"

[[ -n "${project_id}" && "${project_id}" != "null" ]] \
  || die "Project #${PROJECT_NUMBER} not found in org ${GITHUB_ORG}."

log
log "Project to delete:"
log "  Title  : ${project_title}"
log "  Number : #${PROJECT_NUMBER}"
log "  ID     : ${project_id}"
log "  URL    : ${project_url}"
log "  Items  : ${item_count}"
log "  Views  : ${view_count}"
log
warn "This operation is IRREVERSIBLE."
warn "Issues in the repository will NOT be deleted — only project metadata."

if [[ "${FORCE}" -ne 1 ]]; then
  printf '\nType the project title to confirm deletion: '
  read -r confirmation
  if [[ "${confirmation}" != "${project_title}" ]]; then
    die "Confirmation did not match. Aborting."
  fi
fi

log
log "Deleting project \"${project_title}\" (#${PROJECT_NUMBER})..."

gh api graphql \
  -f query='
    mutation($projectId: ID!) {
      deleteProjectV2(input: { projectId: $projectId }) {
        projectV2 { id title }
      }
    }
  ' \
  -f projectId="${project_id}" \
  --jq '"  deleted: \(.data.deleteProjectV2.projectV2.title) [\(.data.deleteProjectV2.projectV2.id)]"'

log
log "Done."
