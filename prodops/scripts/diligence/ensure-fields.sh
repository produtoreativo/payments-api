#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-fields.sh
#
# Idempotently creates all canonical custom fields for the ProdOps project.
#
# Field name convention: hyphen-separated (e.g. oem-state, diligence-status).
# Matches sync.sh field name expectations and project 25 canonical structure.
#
# Native field conflict policy:
#   GitHub Projects v2 native fields: Title, Assignees, Status, Labels,
#   Linked pull requests, Milestone, Repository, Reviewers.
#   ProdOps fields use namespaced names ('oem-', 'witem-', 'diligence-', 'runtime-')
#   that do NOT shadow these native fields.
#
#   Filter distinction:
#     state:open / state:closed  → native GitHub issue state (open/closed)
#     "oem-state":DONE           → ProdOps custom field (SINGLE_SELECT)
#   These two qualifiers are unambiguous and do not conflict.
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
  "/orgs/${GITHUB_ORG}/projectsV2/${PROJECT_NUMBER}" >/dev/null \
  || die "Cannot access Project #${PROJECT_NUMBER}."

# ── Field cache ──────────────────────────────────────────────────────────────

refresh_fields_cache() {
  EXISTING_FIELDS="$(
    gh project field-list "${PROJECT_NUMBER}" \
      --owner "${GITHUB_ORG}" \
      --format json \
      --limit 100 \
      | jq '.fields'
  )"
}

refresh_fields_cache

field_exists() {
  local name="$1"
  jq -e --arg name "${name}" \
    'any(.[]; .name == $name)' <<<"${EXISTING_FIELDS}" >/dev/null
}

# ── Field creation helpers ───────────────────────────────────────────────────

create_text_field() {
  local name="$1"
  if field_exists "${name}"; then
    log "✓ Field exists: \"${name}\""
    return 0
  fi
  log "+ Creating TEXT field: \"${name}\""
  gh project field-create "${PROJECT_NUMBER}" \
    --owner "${GITHUB_ORG}" \
    --name "${name}" \
    --data-type TEXT
  refresh_fields_cache
}

create_number_field() {
  local name="$1"
  if field_exists "${name}"; then
    log "✓ Field exists: \"${name}\""
    return 0
  fi
  log "+ Creating NUMBER field: \"${name}\""
  gh project field-create "${PROJECT_NUMBER}" \
    --owner "${GITHUB_ORG}" \
    --name "${name}" \
    --data-type NUMBER
  refresh_fields_cache
}

create_date_field() {
  local name="$1"
  if field_exists "${name}"; then
    log "✓ Field exists: \"${name}\""
    return 0
  fi
  log "+ Creating DATE field: \"${name}\""
  gh project field-create "${PROJECT_NUMBER}" \
    --owner "${GITHUB_ORG}" \
    --name "${name}" \
    --data-type DATE
  refresh_fields_cache
}

create_single_select_field() {
  local name="$1"
  local options="$2"
  if field_exists "${name}"; then
    log "✓ Field exists: \"${name}\""
    return 0
  fi
  log "+ Creating SINGLE_SELECT field: \"${name}\" [${options}]"
  gh project field-create "${PROJECT_NUMBER}" \
    --owner "${GITHUB_ORG}" \
    --name "${name}" \
    --data-type SINGLE_SELECT \
    --single-select-options "${options}"
  refresh_fields_cache
}

# ── Canonical ProdOps fields ─────────────────────────────────────────────────
# Naming: workspace.yaml name with ':' replaced by ' ' (GitHub constraint).
# Source of truth: runtime/workspace/workspace.yaml > fields

log
log "Ensuring canonical ProdOps fields..."
log

log "── Identity ─────────────────────────────────────────────────────────────"

create_single_select_field "witem-type" \
  "Feature,Runtime Task,Finding"

create_text_field "witem-repository"
create_text_field "witem-feature"
create_text_field "witem-obc"
create_text_field "witem-release"
create_text_field "witem-iteration"

log
log "── Delivery ─────────────────────────────────────────────────────────────"

create_single_select_field "oem-journey" \
  "Delivery,Diligence,Assessment"

# "Cycle" matches sync.sh field name and project 25 canonical structure
create_single_select_field "Cycle" \
  "CI Sync,CI Async"

create_single_select_field "oem-phase" \
  "Started,Completed"

# NOTE: 'oem-state' not 'state' — 'state:open' targets native GitHub issue state
create_single_select_field "oem-state" \
  "BOOTSTRAPPING,HACKING,SYNCING,FINISHING,SHIPPING,VALIDATING,PROMOTING,DONE,BLOCKED,REWORKING"

create_number_field "oem-rework-count"
create_date_field "oem-blocked-since"
create_text_field "oem-last-event"

log
log "── Diligence ────────────────────────────────────────────────────────────"

create_single_select_field "diligence-status" \
  "Pending,Sync In Progress,Async In Progress,Compliant,Non-Compliant"

create_single_select_field "diligence-evidence" \
  "Missing,Partial,Complete"

log
log "── Runtime ──────────────────────────────────────────────────────────────"

create_single_select_field "runtime-sync" \
  "Pending,In Sync,Drift Detected,Repair In Progress,Reconciled"

create_single_select_field "runtime-timeline-state" \
  "Empty,In Progress,Complete,Replay Verified"

create_date_field "runtime-last-sync"

log
log "Final field list:"
gh project field-list "${PROJECT_NUMBER}" \
  --owner "${GITHUB_ORG}" \
  --format json \
  --limit 100 \
  | jq -r '.fields[] | "  ✓ \(.name) (\(.type))"'

log
log "Done."
