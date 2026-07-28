#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-delivery-views.sh
#
# Idempotently creates the canonical Delivery views for an
# organization-owned GitHub Projects v2 project.
#
# Requirements:
#   - gh authenticated with Projects (write) permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   PROJECT_NUMBER=24
#   ITERATION_ID=IP-001
#   JOURNEY_VALUE=Delivery
#   API_VERSION=2026-03-10

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
PROJECT_NUMBER="${PROJECT_NUMBER:-24}"
ITERATION_ID="${ITERATION_ID:-IP-RUNTIME-001}"
JOURNEY_VALUE="${JOURNEY_VALUE:-Delivery}"
API_VERSION="${API_VERSION:-2026-03-10}"

REST_BASE="/orgs/${GITHUB_ORG}/projectsV2/${PROJECT_NUMBER}"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_command gh
require_command jq

log "Checking GitHub authentication..."
gh auth status >/dev/null 2>&1 || die "gh is not authenticated."

log "Checking access to organization project ${GITHUB_ORG}/#${PROJECT_NUMBER}..."
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  "${REST_BASE}" >/dev/null \
  || die "Cannot access Project #${PROJECT_NUMBER}. Check owner, number, and Projects permission."

get_project_node_id() {
  gh api graphql \
    -f query='
      query($org: String!, $number: Int!) {
        organization(login: $org) {
          projectV2(number: $number) {
            id
          }
        }
      }
    ' \
    -F org="${GITHUB_ORG}" \
    -F number="${PROJECT_NUMBER}" \
    --jq '.data.organization.projectV2.id'
}

PROJECT_NODE_ID="$(get_project_node_id)"
[[ -n "${PROJECT_NODE_ID}" && "${PROJECT_NODE_ID}" != "null" ]] \
  || die "Project node ID not found."

# Cache views once per script execution.
refresh_views_cache() {
  VIEWS_JSON="$(
    gh api graphql \
      -f query='
        query($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              views(first: 100) {
                nodes {
                  name
                  number
                  layout
                }
              }
            }
          }
        }
      ' \
      -F projectId="${PROJECT_NODE_ID}" \
      --jq '.data.node.views.nodes'
  )"
}

refresh_views_cache

view_exists() {
  local name="$1"
  jq -e --arg name "${name}" \
    'any(.[]; .name == $name)' <<<"${VIEWS_JSON}" >/dev/null
}

# REST Projects v2 exposes the numeric IDs required by visible_fields.
list_project_fields_rest() {
  gh api --paginate \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    "${REST_BASE}/fields?per_page=100" \
    --slurp \
    | jq 'flatten'
}

FIELDS_JSON="$(list_project_fields_rest)"

resolve_visible_field_ids() {
  local requested_json="$1"

  jq -cn \
    --argjson requested "${requested_json}" \
    --argjson available "${FIELDS_JSON}" '
      [
        $requested[] as $wanted
        | $available[]
        | select(.name == $wanted and .id != null)
        | (.id | tonumber)
      ]
      | unique
    '
}

report_missing_fields() {
  local requested_json="$1"

  local missing
  missing="$(
    jq -cn \
      --argjson requested "${requested_json}" \
      --argjson available "${FIELDS_JSON}" '
        [
          $requested[]
          | select(. as $wanted | any($available[]; .name == $wanted) | not)
        ]
      '
  )"

  if [[ "$(jq 'length' <<<"${missing}")" -gt 0 ]]; then
    warn "Some requested visible fields were not returned by the REST Fields API:"
    jq -r '.[] | "  - \(.)"' <<<"${missing}" >&2
    warn "The view will be created using only the fields whose numeric IDs were resolved."
  fi
}

create_view() {
  local name="$1"
  local layout="$2"
  local filter="$3"
  local visible_names_json="$4"

  if view_exists "${name}"; then
    log "✓ View exists: ${name}"
    return 0
  fi

  report_missing_fields "${visible_names_json}"

  local visible_ids_json
  visible_ids_json="$(resolve_visible_field_ids "${visible_names_json}")"

  local payload
  payload="$(
    jq -cn \
      --arg name "${name}" \
      --arg layout "${layout}" \
      --arg filter "${filter}" \
      --argjson visible_fields "${visible_ids_json}" '
        {
          name: $name,
          layout: $layout,
          filter: $filter
        }
        + if ($visible_fields | length) > 0
          then {visible_fields: $visible_fields}
          else {}
          end
      '
  )"

  log "Creating ${layout} view: ${name}"

  local response
  response="$(
    gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: ${API_VERSION}" \
      "${REST_BASE}/views" \
      --input - <<<"${payload}"
  )"

  jq -r '
    if .value then
      "  created: view #\(.value.number) — \(.value.html_url)"
    else
      "  created"
    end
  ' <<<"${response}"

  refresh_views_cache
}

ITERATION_FILTER="\"witem iteration\":${ITERATION_ID}"
DELIVERY_FILTER="\"oem journey\":${JOURNEY_VALUE} \"witem iteration\":${ITERATION_ID}"
BLOCKED_FILTER="${DELIVERY_FILTER} \"oem state\":BLOCKED"
DONE_FILTER="${DELIVERY_FILTER} \"oem state\":DONE"

COMMON_FIELDS='[
  "Title",
  "Assignees",
  "witem feature",
  "witem release",
  "witem iteration",
  "oem state",
  "oem cycle",
  "oem phase",
  "oem last-event",
  "runtime last-sync"
]'

BLOCKED_FIELDS='[
  "Title",
  "Assignees",
  "witem feature",
  "oem state",
  "oem cycle",
  "oem phase",
  "oem blocked-since",
  "oem last-event",
  "oem rework-count"
]'

DONE_FIELDS='[
  "Title",
  "Assignees",
  "witem feature",
  "witem release",
  "witem iteration",
  "oem state",
  "oem cycle",
  "oem phase",
  "oem last-event",
  "runtime last-sync",
  "oem rework-count"
]'

log
log "Ensuring canonical Delivery views..."

create_view \
  "Iteration Backlog" \
  "table" \
  "${ITERATION_FILTER}" \
  "${COMMON_FIELDS}"

create_view \
  "Delivery Board" \
  "board" \
  "${DELIVERY_FILTER}" \
  "${COMMON_FIELDS}"

create_view \
  "Delivery Blocked" \
  "table" \
  "${BLOCKED_FILTER}" \
  "${BLOCKED_FIELDS}"

create_view \
  "Delivery Done" \
  "table" \
  "${DONE_FILTER}" \
  "${DONE_FIELDS}"

log
log "Final Delivery views:"

jq -r '
  .[]
  | select(
      .name == "Iteration Backlog"
      or .name == "Delivery Board"
      or .name == "Delivery Blocked"
      or .name == "Delivery Done"
    )
  | "  ✓ \(.name) — view #\(.number) (\(.layout))"
' <<<"${VIEWS_JSON}"

log
log "Done."
