#!/usr/bin/env bash
# GitHub Project Sync — updates oem-state, oem-last-event and Cycle for the pilot issue
# Usage: sync.sh --issue <number> --state <STATE> --last-event <event> --correlation-id <id>
#
# Exit codes:
#   0  every update succeeded (or GITHUB_SYNC_DRY_RUN=1)
#   1  invalid arguments, project/issue not found, or ANY update failed.
#      A failed update is never reported as success: each mutation is checked and
#      the script exits non-zero if one of them did not apply (DS-57).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"
LOG_FILE="${GITHUB_SYNC_LOG_FILE:-$PRODOPS_DIR/artifacts/runtime/github-sync.log}"

yaml_get() {
  python3 - "$CONFIG" "$1" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
keys = sys.argv[2].split('.')
val = data
for k in keys:
    val = val[k]
print(val)
PYEOF
}

OWNER=$(yaml_get "github.owner")
PROJECT_NUMBER=$(yaml_get "github.project-number")
REPO=$(yaml_get "github.repository")

STATE_FIELD_NAME="oem-state"
LAST_EVENT_FIELD_NAME="oem-last-event"
CYCLE_FIELD_NAME="Cycle"

# Derive delivery cycle from oem-state
derive_cycle() {
  case "$1" in
    PENDING|BOOTSTRAPPING|HACKING|SYNCING|FINISHING) echo "CI Sync" ;;
    SHIPPING|VALIDATING|PROMOTING|DONE)              echo "CI Async" ;;
    *)                                               echo "" ;; # BLOCKED/REWORKING: no override
  esac
}

ISSUE_NUMBER=""
STATE=""
LAST_EVENT=""
CORRELATION_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)          ISSUE_NUMBER="$2"; shift 2 ;;
    --state)          STATE="$2"; shift 2 ;;
    --last-event)     LAST_EVENT="$2"; shift 2 ;;
    --correlation-id) CORRELATION_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ISSUE_NUMBER" ]] && { echo "Error: --issue required" >&2; exit 1; }
[[ -z "$STATE" ]]        && { echo "Error: --state required" >&2; exit 1; }
[[ -z "$LAST_EVENT" ]]   && { echo "Error: --last-event required" >&2; exit 1; }

mkdir -p "$(dirname "$LOG_FILE")"
# Logs go to stderr (and the log file) so that command substitutions never swallow them.
log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE" >&2; }

# Dry-run mode: skip all GitHub API calls (used in emit-event tests to avoid polluting real projects)
if [[ "${GITHUB_SYNC_DRY_RUN:-0}" == "1" ]]; then
  echo '{"result":"dry-run","issue":"'"${ISSUE_NUMBER}"'","state":"'"${STATE}"'"}'
  exit 0
fi

CORR="${CORRELATION_ID:-no-correlation-id}"
log "GitHub sync — issue=#${ISSUE_NUMBER} state=${STATE} correlation-id=${CORR}"

# Number of updates that did not apply. The script exits 1 at the end if > 0.
FAILURES=0
fail() { log "ERROR: $*"; FAILURES=$((FAILURES + 1)); }

SCOPE_HINT="The gh token needs the 'project' scope: run 'gh auth refresh -s read:project,project' (or use a token that has it)."

# Run a GraphQL call and fail loudly. Prints the response body on success; on failure
# logs the real reason (including a missing-scope hint) and returns 1.
#   gql <description> <gh api graphql args...>
gql() {
  local desc="$1"; shift
  local out status=0
  out=$(gh api graphql "$@" 2>&1) || status=$?
  if [[ $status -ne 0 ]] || { echo "$out" | jq -e 'type == "object" and has("errors")' >/dev/null 2>&1; }; then
    local reason
    reason=$(echo "$out" | jq -r '.errors[0].message // empty' 2>/dev/null || true)
    [[ -z "$reason" ]] && reason=$(echo "$out" | head -c 300)
    log "ERROR: ${desc}: ${reason}"
    if echo "$out" | grep -q "INSUFFICIENT_SCOPES"; then
      log "HINT: ${SCOPE_HINT}"
    fi
    FAILURES=$((FAILURES + 1))
    return 1
  fi
  printf '%s' "$out"
}

# Get project node ID — try as organization first, then user
PROJECT_ID=""
out=$(gql "lookup of project #${PROJECT_NUMBER} (organization ${OWNER})" -f query='
  query($owner: String!, $number: Int!) {
    organization(login: $owner) {
      projectV2(number: $number) { id }
    }
  }' -f owner="$OWNER" -F number="$PROJECT_NUMBER") && \
  PROJECT_ID=$(echo "$out" | jq -r '.data.organization.projectV2.id // empty') || true

if [[ -z "$PROJECT_ID" ]]; then
  # The org lookup may fail only because the owner is a user — retry as user, keeping a clean failure count.
  FAILURES=0
  out=$(gql "lookup of project #${PROJECT_NUMBER} (user ${OWNER})" -f query='
    query($owner: String!, $number: Int!) {
      user(login: $owner) {
        projectV2(number: $number) { id }
      }
    }' -f owner="$OWNER" -F number="$PROJECT_NUMBER") && \
    PROJECT_ID=$(echo "$out" | jq -r '.data.user.projectV2.id // empty') || true
fi

if [[ -z "$PROJECT_ID" ]]; then
  log "ERROR: Could not find project #${PROJECT_NUMBER} for owner ${OWNER}"
  exit 1
fi
FAILURES=0
log "Project ID: $PROJECT_ID"

# Get issue node ID
ISSUE_NODE_ID=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" -q '.node_id' 2>/dev/null) || true
if [[ -z "$ISSUE_NODE_ID" ]]; then
  log "ERROR: Could not get node_id for issue #${ISSUE_NUMBER}"
  exit 1
fi
log "Issue node ID: $ISSUE_NODE_ID"

# Add issue to project (idempotent)
ITEM_ID=""
out=$(gql "add issue #${ISSUE_NUMBER} to project" -f query='
  mutation($project: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: {projectId: $project, contentId: $contentId}) {
      item { id }
    }
  }' -f project="$PROJECT_ID" -f contentId="$ISSUE_NODE_ID") && \
  ITEM_ID=$(echo "$out" | jq -r '.data.addProjectV2ItemById.item.id // empty') || true
if [[ -z "$ITEM_ID" ]]; then
  log "ERROR: Could not add issue to project or get item ID"
  exit 1
fi
log "Project item ID: $ITEM_ID"

# Fetch all fields
FIELDS_JSON=""
refresh_fields() {
  FIELDS_JSON=$(gh api graphql -f query='
    query($project: ID!) {
      node(id: $project) {
        ... on ProjectV2 {
          fields(first: 50) {
            nodes {
              ... on ProjectV2Field { id name }
              ... on ProjectV2SingleSelectField { id name options { id name } }
            }
          }
        }
      }
    }' -f project="$PROJECT_ID" 2>/dev/null) || FIELDS_JSON=""
}
field_id() {
  echo "$FIELDS_JSON" | jq -r --arg n "$1" '.data.node.fields.nodes[]? | select(.name == $n) | .id // empty' 2>/dev/null || true
}
option_id() {
  echo "$FIELDS_JSON" | jq -r --arg n "$1" --arg o "$2" \
    '.data.node.fields.nodes[]? | select(.name == $n) | .options[]? | select(.name == $o) | .id' 2>/dev/null || true
}

refresh_fields
STATE_FIELD_ID=$(field_id "$STATE_FIELD_NAME")
LAST_EVENT_FIELD_ID=$(field_id "$LAST_EVENT_FIELD_NAME")
CYCLE_FIELD_ID=$(field_id "$CYCLE_FIELD_NAME")

# Create oem-state field if absent
if [[ -z "$STATE_FIELD_ID" ]]; then
  log "\"${STATE_FIELD_NAME}\" field not found — creating..."
  gh project field-create "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --name "$STATE_FIELD_NAME" \
    --data-type "SINGLE_SELECT" \
    --single-select-options "PENDING,BOOTSTRAPPING,HACKING,SYNCING,FINISHING,SHIPPING,VALIDATING,PROMOTING,DONE,BLOCKED,REWORKING" \
    2>&1 | tee -a "$LOG_FILE" || true
  refresh_fields
  STATE_FIELD_ID=$(field_id "$STATE_FIELD_NAME")
fi

# Create oem-last-event field if absent
if [[ -z "$LAST_EVENT_FIELD_ID" ]]; then
  log "\"${LAST_EVENT_FIELD_NAME}\" field not found — creating..."
  gh project field-create "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --name "$LAST_EVENT_FIELD_NAME" \
    --data-type "TEXT" \
    2>&1 | tee -a "$LOG_FILE" || true
  refresh_fields
  LAST_EVENT_FIELD_ID=$(field_id "$LAST_EVENT_FIELD_NAME")
fi

log "oem-state field ID:      ${STATE_FIELD_ID:-NOT_FOUND}"
log "oem-last-event field ID: ${LAST_EVENT_FIELD_ID:-NOT_FOUND}"
log "Cycle field ID:          ${CYCLE_FIELD_ID:-NOT_FOUND}"

set_single_select() { # <field-name> <field-id> <option-id> <value-label>
  gql "update \"$1\" to ${4}" -f query='
    mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field,
        value: { singleSelectOptionId: $option }
      }) { projectV2Item { id } }
    }' -f project="$PROJECT_ID" -f item="$ITEM_ID" -f field="$2" -f option="$3" >/dev/null
}

# Update oem-state (SingleSelect)
if [[ -z "$STATE_FIELD_ID" ]]; then
  fail "\"${STATE_FIELD_NAME}\" field not found and could not be created — card state NOT updated"
else
  OPTION_ID=$(option_id "$STATE_FIELD_NAME" "$STATE")
  if [[ -z "$OPTION_ID" ]]; then
    fail "option '${STATE}' not found in \"${STATE_FIELD_NAME}\" — card state NOT updated (re-run provisioning: prodops/scripts/diligence/ensure-fields.sh)"
  elif set_single_select "$STATE_FIELD_NAME" "$STATE_FIELD_ID" "$OPTION_ID" "$STATE"; then
    log "oem-state updated to: $STATE"
  fi
fi

# Update oem-last-event (Text)
if [[ -z "$LAST_EVENT_FIELD_ID" ]]; then
  fail "\"${LAST_EVENT_FIELD_NAME}\" field not found and could not be created — last event NOT updated"
elif gql "update \"${LAST_EVENT_FIELD_NAME}\"" -f query='
    mutation($project: ID!, $item: ID!, $field: ID!, $value: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field,
        value: { text: $value }
      }) { projectV2Item { id } }
    }' -f project="$PROJECT_ID" -f item="$ITEM_ID" -f field="$LAST_EVENT_FIELD_ID" -f value="$LAST_EVENT" >/dev/null; then
  log "oem-last-event updated to: $LAST_EVENT"
fi

# Update Cycle (SingleSelect) — derived from oem-state; skip BLOCKED/REWORKING
DERIVED_CYCLE=$(derive_cycle "$STATE")
if [[ -z "$DERIVED_CYCLE" ]]; then
  log "Cycle: no override for state $STATE (BLOCKED/REWORKING)"
elif [[ -z "$CYCLE_FIELD_ID" ]]; then
  fail "\"${CYCLE_FIELD_NAME}\" field not found — Cycle NOT updated"
else
  CYCLE_OPTION_ID=$(option_id "$CYCLE_FIELD_NAME" "$DERIVED_CYCLE")
  if [[ -z "$CYCLE_OPTION_ID" ]]; then
    fail "option '${DERIVED_CYCLE}' not found in \"${CYCLE_FIELD_NAME}\" — Cycle NOT updated"
  elif set_single_select "$CYCLE_FIELD_NAME" "$CYCLE_FIELD_ID" "$CYCLE_OPTION_ID" "$DERIVED_CYCLE"; then
    log "Cycle updated to: $DERIVED_CYCLE"
  fi
fi

# Sync native issue state — closed when DONE, open otherwise
CURRENT_ISSUE_STATE=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" -q '.state' 2>/dev/null) || CURRENT_ISSUE_STATE=""
if [[ "$STATE" == "DONE" ]]; then
  if [[ "$CURRENT_ISSUE_STATE" != "closed" ]]; then
    if gh issue close "$ISSUE_NUMBER" --repo "${OWNER}/${REPO}" > /dev/null 2>&1; then
      log "Issue #${ISSUE_NUMBER} closed (state=DONE)"
    else
      fail "failed to close issue #${ISSUE_NUMBER}"
    fi
  else
    log "Issue #${ISSUE_NUMBER} already closed"
  fi
else
  if [[ "$CURRENT_ISSUE_STATE" == "closed" ]]; then
    if gh issue reopen "$ISSUE_NUMBER" --repo "${OWNER}/${REPO}" > /dev/null 2>&1; then
      log "Issue #${ISSUE_NUMBER} reopened (state=${STATE})"
    else
      fail "failed to reopen issue #${ISSUE_NUMBER}"
    fi
  fi
fi

if [[ "$FAILURES" -gt 0 ]]; then
  log "GitHub sync FAILED — ${FAILURES} update(s) did not apply (issue #${ISSUE_NUMBER}, state=${STATE})"
  exit 1
fi
log "GitHub sync complete"
