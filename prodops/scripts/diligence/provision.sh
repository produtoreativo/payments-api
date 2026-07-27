#!/usr/bin/env bash
set -Eeuo pipefail

# provision.sh
#
# Orchestrates the full ProdOps workspace provisioning sequence.
#
# Project identity rules:
#
# 1. When PROJECT_NUMBER is provided:
#    - use that exact project if it exists;
#    - create a new project if it does not exist;
#    - verify that GitHub assigned the requested number;
#    - never silently redirect to another project with the same title.
#
# 2. When PROJECT_NUMBER is omitted:
#    - locate the project by exact PROJECT_TITLE;
#    - create it when no project with that title exists;
#    - use the number assigned by GitHub.
#
# Important:
# GitHub assigns Project numbers sequentially. The API does not accept a desired
# project number during creation. Therefore, PROJECT_NUMBER=25 can only be
# satisfied if the next Project created by the organization receives #25.
#
# Requirements:
#   - gh authenticated with Projects (write) + repo permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   GITHUB_REPO=payments-api
#   PROJECT_NUMBER=25
#   PROJECT_TITLE="ProdOps — payments-api"
#   MILESTONE_TITLE=v0.1.0-runtime-pilot
#   ITERATION_ID=IP-RUNTIME-001
#   RELEASE_ID=v0.1.0-runtime-pilot
#   OBC_ID=EXP-013
#   API_VERSION=2026-03-10
#   DRY_RUN=0

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
GITHUB_REPO="${GITHUB_REPO:-payments-api}"
PROJECT_TITLE="${PROJECT_TITLE:-ProdOps — payments-api}"
PROJECT_NUMBER="${PROJECT_NUMBER:-}"
MILESTONE_TITLE="${MILESTONE_TITLE:-v0.1.0-runtime-pilot}"
ITERATION_ID="${ITERATION_ID:-IP-RUNTIME-001}"
RELEASE_ID="${RELEASE_ID:-v0.1.0-runtime-pilot}"
OBC_ID="${OBC_ID:-EXP-013}"
API_VERSION="${API_VERSION:-2026-03-10}"
DRY_RUN="${DRY_RUN:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n%s\n' "$*"; }
log_sep() { printf '\n══ %s ══\n' "$1"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 \
    || die "Required command not found: $1"
}

require_script() {
  [[ -x "$1" ]] \
    || die "Required executable script not found: $1"
}

require_command gh
require_command jq

for script_name in \
  ensure-milestone.sh \
  ensure-fields.sh \
  ensure-labels.sh \
  ensure-views.sh \
  ensure-issues.sh
do
  require_script "${SCRIPT_DIR}/${script_name}"
done

log "Checking GitHub authentication..."
gh auth status >/dev/null 2>&1 || die "gh is not authenticated."

project_json_by_number() {
  local number="$1"

  gh project view "${number}" \
    --owner "${GITHUB_ORG}" \
    --format json 2>/dev/null || true
}

project_number_by_title() {
  gh project list \
    --owner "${GITHUB_ORG}" \
    --format json \
    --limit 100 \
    | jq -r \
        --arg title "${PROJECT_TITLE}" \
        '.projects[]
         | select(.title == $title)
         | .number
         | tostring' \
    | head -n 1
}

project_exists_by_number() {
  local number="$1"
  local json

  json="$(project_json_by_number "${number}")"
  [[ -n "${json}" ]] && jq -e '.number != null' <<<"${json}" >/dev/null 2>&1
}

create_project() {
  local output
  local created_number

  log "Creating GitHub Project: \"${PROJECT_TITLE}\""

  output="$(
    gh project create \
      --owner "${GITHUB_ORG}" \
      --title "${PROJECT_TITLE}" \
      --format json
  )"

  created_number="$(jq -r '.number // empty' <<<"${output}")"

  [[ -n "${created_number}" ]] \
    || die "GitHub created the project but did not return its number."

  printf '%s\n' "${created_number}"
}

ensure_target_project() {
  local requested_number="${PROJECT_NUMBER}"
  local existing_title=""
  local created_number=""
  local detected_number=""

  # Explicit project number: number is authoritative.
  if [[ -n "${requested_number}" ]]; then
    if project_exists_by_number "${requested_number}"; then
      existing_title="$(
        project_json_by_number "${requested_number}" \
          | jq -r '.title // empty'
      )"

      if [[ "${existing_title}" != "${PROJECT_TITLE}" ]]; then
        warn "Project #${requested_number} exists with title \"${existing_title}\"."
        warn "The configured title is \"${PROJECT_TITLE}\"; the existing project number remains authoritative."
      fi

      PROJECT_NUMBER="${requested_number}"
      export PROJECT_NUMBER
      log "✓ Target Project exists: #${PROJECT_NUMBER} (${existing_title})"
      return 0
    fi

    log "Project #${requested_number} does not exist."
    log "GitHub does not allow selecting a number during creation."
    log "Creating a new Project and validating that GitHub assigns #${requested_number}..."

    created_number="$(create_project)"

    if [[ "${created_number}" != "${requested_number}" ]]; then
      die "Requested Project #${requested_number}, but GitHub assigned #${created_number}. \
Project numbers are server-assigned and cannot be forced. \
The new project was created as #${created_number}; review it before continuing."
    fi

    PROJECT_NUMBER="${created_number}"
    export PROJECT_NUMBER
    log "✓ Created requested Project #${PROJECT_NUMBER}: \"${PROJECT_TITLE}\""
    return 0
  fi

  # No explicit number: title is authoritative.
  detected_number="$(project_number_by_title || true)"

  if [[ -n "${detected_number}" ]]; then
    PROJECT_NUMBER="${detected_number}"
    export PROJECT_NUMBER
    log "✓ Project exists by title: \"${PROJECT_TITLE}\" (#${PROJECT_NUMBER})"
    return 0
  fi

  PROJECT_NUMBER="$(create_project)"
  export PROJECT_NUMBER
  log "✓ Project created: \"${PROJECT_TITLE}\" (#${PROJECT_NUMBER})"
}

if [[ "${DRY_RUN}" == "1" ]]; then
  log "DRY_RUN=1 — validating target Project only."

  if [[ -n "${PROJECT_NUMBER}" ]]; then
    if project_exists_by_number "${PROJECT_NUMBER}"; then
      log "✓ Project #${PROJECT_NUMBER} exists."
    else
      log "Project #${PROJECT_NUMBER} does not exist and would be created."
      log "Note: GitHub must assign exactly #${PROJECT_NUMBER}; this cannot be forced."
    fi
  else
    detected="$(project_number_by_title || true)"
    if [[ -n "${detected}" ]]; then
      log "✓ Project found by title: #${detected}"
    else
      log "Project \"${PROJECT_TITLE}\" does not exist and would be created."
    fi
  fi

  exit 0
fi

# ── Step 1: Project ───────────────────────────────────────────────────────────

log_sep "Step 1/6 — Project"
ensure_target_project

[[ -n "${PROJECT_NUMBER}" ]] \
  || die "PROJECT_NUMBER was not resolved."

export GITHUB_ORG
export GITHUB_REPO
export PROJECT_TITLE
export PROJECT_NUMBER
export MILESTONE_TITLE
export ITERATION_ID
export RELEASE_ID
export OBC_ID
export API_VERSION

log "Using target Project: #${PROJECT_NUMBER}"

gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  "/orgs/${GITHUB_ORG}/projectsV2/${PROJECT_NUMBER}" >/dev/null \
  || die "Cannot access Project #${PROJECT_NUMBER} after creation/resolution."

# ── Step 2: Milestone ─────────────────────────────────────────────────────────

log_sep "Step 2/6 — Milestone"
"${SCRIPT_DIR}/ensure-milestone.sh"

# ── Step 3: Fields ────────────────────────────────────────────────────────────

log_sep "Step 3/6 — Fields"
"${SCRIPT_DIR}/ensure-fields.sh"

# ── Step 4: Labels ────────────────────────────────────────────────────────────

log_sep "Step 4/6 — Labels"
"${SCRIPT_DIR}/ensure-labels.sh"

# ── Step 5: Views ─────────────────────────────────────────────────────────────

log_sep "Step 5/6 — Views"
"${SCRIPT_DIR}/ensure-views.sh"

# ── Step 6: Issues ────────────────────────────────────────────────────────────

log_sep "Step 6/6 — Issues"
"${SCRIPT_DIR}/ensure-issues.sh"

# ── Summary ───────────────────────────────────────────────────────────────────

log_sep "Summary"

printf '
  Organization : %s
  Repository   : %s
  Project      : %s (#%s)
  Milestone    : %s
  Iteration    : %s
  Release      : %s
  OBC          : %s

  Project URL  : https://github.com/orgs/%s/projects/%s
' \
  "${GITHUB_ORG}" \
  "${GITHUB_REPO}" \
  "${PROJECT_TITLE}" \
  "${PROJECT_NUMBER}" \
  "${MILESTONE_TITLE}" \
  "${ITERATION_ID}" \
  "${RELEASE_ID}" \
  "${OBC_ID}" \
  "${GITHUB_ORG}" \
  "${PROJECT_NUMBER}"

log "Done."
