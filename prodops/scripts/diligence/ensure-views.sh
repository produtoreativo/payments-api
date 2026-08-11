#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-views.sh
#
# Idempotently creates the single canonical Delivery board view for a GitHub Projects v2 project.
# Matches project 25 structure: one board view "01 — Delivery Timeline".
#
# REST API capabilities (verified empirically, 2026-07-26):
#   ✅ name        — settable on creation
#   ✅ layout      — settable on creation (table | board)
#   ✅ filter      — settable on creation
#   ✅ visible_fields — settable on creation (numeric field IDs)
#   ❌ group_by    — 422 "not a permitted key" — configure manually in GitHub UI
#   ❌ sort_by     — 422 "not a permitted key" — configure manually in GitHub UI
#   ❌ delete      — no REST endpoint; no GraphQL mutation — remove via GitHub UI only
#
# Requirements:
#   - gh authenticated with Projects (write) permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   PROJECT_NUMBER=24
#   API_VERSION=2026-03-10

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
PROJECT_NUMBER="${PROJECT_NUMBER:-24}"
API_VERSION="${API_VERSION:-2026-03-10}"

REST_BASE="/orgs/${GITHUB_ORG}/projectsV2/${PROJECT_NUMBER}"

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

log "Checking access to project ${GITHUB_ORG}/#${PROJECT_NUMBER}..."
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  "${REST_BASE}" >/dev/null \
  || die "Cannot access Project #${PROJECT_NUMBER}. Check owner, number, and Projects permission."

# ── Project node ID ───────────────────────────────────────────────────────────

get_project_node_id() {
  gh api graphql \
    -f query='
      query($org: String!, $number: Int!) {
        organization(login: $org) {
          projectV2(number: $number) { id }
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

# ── Views cache ───────────────────────────────────────────────────────────────

refresh_views_cache() {
  VIEWS_JSON="$(
    gh api graphql \
      -f query='
        query($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              views(first: 100) {
                nodes { name number layout }
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

# ── Field ID resolution (for visible_fields) ──────────────────────────────────

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
    warn "Some requested visible fields were not found in the project:"
    jq -r '.[] | "  - \(.)"' <<<"${missing}" >&2
  fi
}

# ── View creation ─────────────────────────────────────────────────────────────

create_view() {
  local name="$1"
  local layout="$2"
  local filter="${3:-}"
  local visible_names_json="${4:-[]}"

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
        { name: $name, layout: $layout }
        + if $filter != "" then { filter: $filter } else {} end
        + if ($visible_fields | length) > 0 then { visible_fields: $visible_fields } else {} end
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

# ── Canonical Delivery view ───────────────────────────────────────────────────
# Single board view matching project 25 canonical structure.
# Column-by (oem-state) must be configured manually in GitHub UI after creation —
# not settable via REST API.

BOARD_FIELDS='[
  "Title",
  "Assignees",
  "witem-feature",
  "witem-release",
  "witem-iteration",
  "oem-state",
  "Cycle",
  "oem-last-event",
  "diligence-status",
  "runtime-sync"
]'

log
log "Ensuring canonical ProdOps view..."
log

create_view \
  "01 — Delivery Timeline" \
  "board" \
  "" \
  "${BOARD_FIELDS}"

log
log "Final views:"
jq -r '.[] | "  ✓ \(.name) — view #\(.number) (\(.layout))"' <<<"${VIEWS_JSON}"

log
log "NOTE: 'Column by' (oem-state) must be configured manually in GitHub UI — not settable via REST API."
log "  Project URL: https://github.com/orgs/${GITHUB_ORG}/projects/${PROJECT_NUMBER}"
log
log "Done."
