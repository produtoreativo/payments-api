#!/usr/bin/env bash
set -Eeuo pipefail

# ensure-issues.sh
#
# Idempotently creates all canonical ProdOps issues in the repository,
# adds them to the GitHub Projects v2 project, and sets initial custom fields.
#
# Field setting strategy:
#   TEXT fields     → set via GraphQL updateProjectV2ItemFieldValue (text value)
#   SINGLE_SELECT   → set via GraphQL (requires option ID lookup)
#   NUMBER / DATE   → not set on creation (updated by Runtime)
#
# Prerequisites: project, milestone, fields, and labels must already exist.
# Run ensure-fields.sh and ensure-labels.sh before this script.
#
# Requirements:
#   - gh authenticated with repo + Projects (write) permission
#   - jq
#
# Optional environment variables:
#   GITHUB_ORG=produtoreativo
#   GITHUB_REPO=payments-api
#   PROJECT_NUMBER=24
#   MILESTONE_TITLE=v0.1.0-runtime-pilot
#   ITERATION_ID=IP-RUNTIME-001
#   RELEASE_ID=v0.1.0-runtime-pilot
#   OBC_ID=EXP-013
#   API_VERSION=2026-03-10

GITHUB_ORG="${GITHUB_ORG:-produtoreativo}"
GITHUB_REPO="${GITHUB_REPO:-payments-api}"
PROJECT_NUMBER="${PROJECT_NUMBER:-24}"
MILESTONE_TITLE="${MILESTONE_TITLE:-v0.1.0-runtime-pilot}"
ITERATION_ID="${ITERATION_ID:-IP-RUNTIME-001}"
RELEASE_ID="${RELEASE_ID:-v0.1.0-runtime-pilot}"
OBC_ID="${OBC_ID:-EXP-013}"
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
  >/dev/null || die "Cannot access repository ${REPO_PATH}."

log "Checking project access: ${GITHUB_ORG}/#${PROJECT_NUMBER}..."
gh api "/orgs/${GITHUB_ORG}/projectsV2/${PROJECT_NUMBER}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  >/dev/null || die "Cannot access Project #${PROJECT_NUMBER}."

# ── Project and field metadata ────────────────────────────────────────────────

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

# Fetch all field metadata including SINGLE_SELECT option IDs.
FIELD_META="$(
  gh api graphql \
    -f query='
      query($projectId: ID!) {
        node(id: $projectId) {
          ... on ProjectV2 {
            fields(first: 50) {
              nodes {
                ... on ProjectV2Field {
                  id name dataType
                }
                ... on ProjectV2SingleSelectField {
                  id name dataType
                  options { id name }
                }
                ... on ProjectV2IterationField {
                  id name dataType
                }
              }
            }
          }
        }
      }
    ' \
    -F projectId="${PROJECT_NODE_ID}" \
    --jq '.data.node.fields.nodes'
)"

get_field_id() {
  local name="$1"
  jq -r --arg name "${name}" \
    '.[] | select(.name == $name) | .id' \
    <<<"${FIELD_META}" | head -1
}

get_option_id() {
  local field_name="$1"
  local option_name="$2"
  jq -r \
    --arg field "${field_name}" \
    --arg opt "${option_name}" \
    '.[] | select(.name == $field) | .options[]? | select(.name == $opt) | .id' \
    <<<"${FIELD_META}" | head -1
}

# ── Project item cache ────────────────────────────────────────────────────────

refresh_project_items_cache() {
  PROJECT_ITEMS="$(
    gh project item-list "${PROJECT_NUMBER}" \
      --owner "${GITHUB_ORG}" \
      --format json \
      --limit 200 \
      | jq '.items'
  )"
}

refresh_project_items_cache

item_in_project() {
  local issue_number="$1"
  jq -e --argjson n "${issue_number}" \
    'any(.[]; .content.number == $n)' \
    <<<"${PROJECT_ITEMS}" >/dev/null
}

get_project_item_id() {
  local issue_number="$1"
  jq -r --argjson n "${issue_number}" \
    '.[] | select(.content.number == $n) | .id' \
    <<<"${PROJECT_ITEMS}" | head -1
}

# ── Field value setters ───────────────────────────────────────────────────────

set_text_field() {
  local item_id="$1"
  local field_name="$2"
  local value="$3"

  local field_id
  field_id="$(get_field_id "${field_name}")"
  if [[ -z "${field_id}" || "${field_id}" == "null" ]]; then
    warn "Field not found: \"${field_name}\" — skipping"
    return 0
  fi

  gh api graphql \
    -f query='
      mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: { text: $text }
        }) { projectV2Item { id } }
      }
    ' \
    -f projectId="${PROJECT_NODE_ID}" \
    -f itemId="${item_id}" \
    -f fieldId="${field_id}" \
    -f text="${value}" \
    >/dev/null
}

set_single_select_field() {
  local item_id="$1"
  local field_name="$2"
  local option_name="$3"

  local field_id option_id
  field_id="$(get_field_id "${field_name}")"
  if [[ -z "${field_id}" || "${field_id}" == "null" ]]; then
    warn "Field not found: \"${field_name}\" — skipping"
    return 0
  fi

  option_id="$(get_option_id "${field_name}" "${option_name}")"
  if [[ -z "${option_id}" || "${option_id}" == "null" ]]; then
    warn "Option \"${option_name}\" not found in field \"${field_name}\" — skipping"
    return 0
  fi

  gh api graphql \
    -f query='
      mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: { singleSelectOptionId: $optionId }
        }) { projectV2Item { id } }
      }
    ' \
    -f projectId="${PROJECT_NODE_ID}" \
    -f itemId="${item_id}" \
    -f fieldId="${field_id}" \
    -f optionId="${option_id}" \
    >/dev/null
}

# ── Issue helpers ─────────────────────────────────────────────────────────────

issue_exists() {
  local title="$1"
  gh issue list \
    --repo "${REPO_PATH}" \
    --search "\"${title}\" in:title" \
    --state all \
    --json title \
    --limit 5 \
    | jq -e --arg title "${title}" \
      'any(.[]; .title == $title)' \
      >/dev/null
}

get_issue_number_and_url() {
  local title="$1"
  gh issue list \
    --repo "${REPO_PATH}" \
    --search "\"${title}\" in:title" \
    --state all \
    --json number,url,title \
    --limit 5 \
    | jq -r --arg title "${title}" \
      '.[] | select(.title == $title) | "\(.number) \(.url)"' \
    | head -1
}

ensure_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local feature="$4"
  local journey="$5"

  local issue_number issue_url item_id

  if issue_exists "${title}"; then
    read -r issue_number issue_url <<<"$(get_issue_number_and_url "${title}")"
    log "✓ Issue exists: \"${title}\" (#${issue_number})"
  else
    log "+ Creating issue: \"${title}\""
    local body_file
    body_file="$(mktemp)"
    printf '%s' "${body}" > "${body_file}"
    issue_url="$(
      gh issue create \
        --repo "${REPO_PATH}" \
        --title "${title}" \
        --body-file "${body_file}" \
        --label "${labels}" \
        --milestone "${MILESTONE_TITLE}"
    )"
    rm -f "${body_file}"
    read -r issue_number issue_url <<<"$(get_issue_number_and_url "${title}")"
    log "  created: #${issue_number} — ${issue_url}"
  fi

  if item_in_project "${issue_number}"; then
    item_id="$(get_project_item_id "${issue_number}")"
    log "  ✓ Already in project"
  else
    log "  + Adding to project..."
    local add_result
    add_result="$(
      gh project item-add "${PROJECT_NUMBER}" \
        --owner "${GITHUB_ORG}" \
        --url "${issue_url}" \
        --format json
    )"
    item_id="$(jq -r '.id' <<<"${add_result}")"
    refresh_project_items_cache
    log "  added: item ${item_id}"
  fi

  log "  Setting TEXT fields..."
  set_text_field "${item_id}" "witem repository" "${GITHUB_REPO}"
  set_text_field "${item_id}" "witem feature"    "${feature}"
  set_text_field "${item_id}" "witem obc"        "${OBC_ID}"
  set_text_field "${item_id}" "witem release"    "${RELEASE_ID}"
  set_text_field "${item_id}" "witem iteration"  "${ITERATION_ID}"

  log "  Setting SINGLE_SELECT fields..."
  set_single_select_field "${item_id}" "witem type"          "Feature"
  set_single_select_field "${item_id}" "oem journey"        "${journey}"
  set_single_select_field "${item_id}" "oem state"          "BOOTSTRAPPING"
  set_single_select_field "${item_id}" "diligence evidence" "Missing"
  set_single_select_field "${item_id}" "runtime sync"       "Pending"
  set_single_select_field "${item_id}" "runtime timeline-state" "Empty"
}

ensure_runtime_task() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local feature="$4"
  local journey="$5"

  local issue_number issue_url item_id

  if issue_exists "${title}"; then
    read -r issue_number issue_url <<<"$(get_issue_number_and_url "${title}")"
    log "✓ Issue exists: \"${title}\" (#${issue_number})"
  else
    log "+ Creating issue: \"${title}\""
    local body_file
    body_file="$(mktemp)"
    printf '%s' "${body}" > "${body_file}"
    issue_url="$(
      gh issue create \
        --repo "${REPO_PATH}" \
        --title "${title}" \
        --body-file "${body_file}" \
        --label "${labels}" \
        --milestone "${MILESTONE_TITLE}"
    )"
    rm -f "${body_file}"
    read -r issue_number issue_url <<<"$(get_issue_number_and_url "${title}")"
    log "  created: #${issue_number} — ${issue_url}"
  fi

  if item_in_project "${issue_number}"; then
    item_id="$(get_project_item_id "${issue_number}")"
    log "  ✓ Already in project"
  else
    log "  + Adding to project..."
    local add_result
    add_result="$(
      gh project item-add "${PROJECT_NUMBER}" \
        --owner "${GITHUB_ORG}" \
        --url "${issue_url}" \
        --format json
    )"
    item_id="$(jq -r '.id' <<<"${add_result}")"
    refresh_project_items_cache
    log "  added: item ${item_id}"
  fi

  set_text_field "${item_id}" "witem repository" "${GITHUB_REPO}"
  set_text_field "${item_id}" "witem feature"    "${feature}"
  set_text_field "${item_id}" "witem obc"        "${OBC_ID}"
  set_text_field "${item_id}" "witem release"    "${RELEASE_ID}"
  set_text_field "${item_id}" "witem iteration"  "${ITERATION_ID}"
  set_single_select_field "${item_id}" "witem type"   "Runtime Task"
  set_single_select_field "${item_id}" "oem journey"  "${journey}"
  set_single_select_field "${item_id}" "runtime sync" "Pending"
}

# ── Canonical issues ──────────────────────────────────────────────────────────
# Source of truth: runtime/workspace/workspace.yaml > issues

log
log "Ensuring canonical ProdOps issues..."
log

log "── Epic ─────────────────────────────────────────────────────────────────"

ensure_issue \
  "EPIC: ProdOps Runtime MVP" \
  "Executar o piloto completo de validação do Runtime do ProdOps Framework no payments-api.

**Experimento:** EXP-013
**Iteration:** IP-RUNTIME-001
**Release:** v0.1.0-runtime-pilot" \
  "runtime:pilot,journey:delivery" \
  "EPIC-RUNTIME-001" \
  "Delivery"

log
log "── Features ─────────────────────────────────────────────────────────────"

ensure_issue \
  "FTR-RUNTIME-001: Split Payment Creation — Happy Path" \
  "Executar o ciclo completo de Delivery para Split Payment Creation sem interrupções.

**Cenário:** Happy Path — Bootstrap → Promote sem Gate.Failed nem Impediment
**Responde:** Q1 (OEM), Q2 (Derived State), Q3 (Replay)

**Critérios de aceite:**
- Feature em estado DONE ao final
- 15 eventos registrados na Timeline
- Derived State correto em cada transição
- GitHub COR sincronizado (oem:state = DONE)" \
  "runtime:pilot,journey:delivery,phase:bootstrap,evidence:missing" \
  "FTR-RUNTIME-001" \
  "Delivery"

ensure_issue \
  "FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework" \
  "Executar Delivery Journey com Gate.Failed durante VALIDATING e ciclo de Rework completo.

**Cenário:** Gate Failed → Rework.Declared → Rework.Completed → Gate.Passed
**Responde:** Q1 (Rework events), Q2 (REWORKING state)

**Critérios de aceite:**
- Shared.Gate.Failed registrado
- Delivery.Rework.Declared → REWORKING state
- Delivery.Rework.Completed → retorno a VALIDATING
- oem:rework-count = 1 ao final" \
  "runtime:pilot,journey:delivery,runtime:rework,evidence:missing" \
  "FTR-RUNTIME-002" \
  "Delivery"

ensure_issue \
  "FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift" \
  "Executar Delivery com Blocking via Impediment.Declared + Lookback + Diligence Async com Drift.

**Cenário:** HACKING → BLOCKED → Lookback → HACKING → DONE + Drift detectado e reparado
**Responde:** Q2 (Lookback), Q4 (COR), Q5 (Diligence), Q7 (Shared Types)

**Critérios de aceite:**
- Impediment.Declared → BLOCKED
- Impediment.Resolved (alters_state: false) com Lookback → HACKING
- Drift introduzido e reparado pela Diligence Async" \
  "runtime:pilot,journey:delivery,runtime:blocked,journey:diligence,evidence:missing" \
  "FTR-RUNTIME-003" \
  "Delivery"

log
log "── Runtime Tasks ─────────────────────────────────────────────────────────"

ensure_runtime_task \
  "RT-01: Event Producer" \
  "Mecanismo de emissão de Event Instances em formato canônico (OEM).

**DoD:** Schema validado; primeiro evento emitido; arquivo em evidence/timelines/" \
  "runtime:pilot,runtime:task" \
  "RT-01" \
  "Delivery"

ensure_runtime_task \
  "RT-02: Timeline Processor" \
  "Consumer que calcula Derived State a partir da Timeline, incluindo algoritmo de Lookback.

**DoD:** Derived State correto para FTR-001; Replay idempotente; Lookback para FTR-003" \
  "runtime:pilot,runtime:task" \
  "RT-02" \
  "Delivery"

ensure_runtime_task \
  "RT-03: GitHub Synchronizer" \
  "Atualiza Custom Fields do GitHub Project com Derived State calculado pelo Timeline Processor.

**DoD:** oem:state sincronizado após cada transição; oem:rework-count e oem:blocked-since corretos" \
  "runtime:pilot,runtime:task" \
  "RT-03" \
  "Delivery"

ensure_runtime_task \
  "RT-04: Datadog Integration" \
  "Envia métricas derivadas da Timeline para Datadog via API.

**DoD:** Primeira métrica (events_emitted) visível no Datadog com trace até evento da Timeline" \
  "runtime:pilot,runtime:task" \
  "RT-04" \
  "Delivery"

ensure_runtime_task \
  "RT-05: Delivery Dashboard" \
  "Dashboard Datadog com Lead Time, Cycle Time, Block Time, Gate Failure Rate.

**DoD:** Dashboard com pelo menos Lead Time e Gate Failure Rate; screenshots em evidence/" \
  "runtime:pilot,runtime:task" \
  "RT-05" \
  "Delivery"

ensure_runtime_task \
  "RT-06: Diligence Dashboard" \
  "Dashboard Datadog com Drift Detection Rate e Repair Time.

**DoD:** Dashboard com pelo menos Drift Detection Rate; screenshots em evidence/" \
  "runtime:pilot,runtime:task" \
  "RT-06" \
  "Diligence"

log
log "Done."
