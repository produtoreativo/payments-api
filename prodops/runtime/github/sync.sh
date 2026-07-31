#!/usr/bin/env bash
# GitHub Project Sync — updates oem-state, oem-last-event and Cycle for the pilot issue
# Usage: sync.sh --issue <number> --state <STATE> --last-event <event> --correlation-id <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"
LOG_FILE="$PRODOPS_DIR/artifacts/runtime/github-sync.log"

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

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"; }

CORR="${CORRELATION_ID:-no-correlation-id}"
log "GitHub sync — issue=#${ISSUE_NUMBER} state=${STATE} correlation-id=${CORR}"

# Get project node ID — try as organization first, then user
PROJECT_ID=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    organization(login: $owner) {
      projectV2(number: $number) { id }
    }
  }' -f owner="$OWNER" -F number="$PROJECT_NUMBER" \
  2>/dev/null | jq -r '.data.organization.projectV2.id // empty') || true

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(gh api graphql -f query='
    query($owner: String!, $number: Int!) {
      user(login: $owner) {
        projectV2(number: $number) { id }
      }
    }' -f owner="$OWNER" -F number="$PROJECT_NUMBER" \
    2>/dev/null | jq -r '.data.user.projectV2.id // empty') || true
fi

if [[ -z "$PROJECT_ID" ]]; then
  log "ERROR: Could not find project #${PROJECT_NUMBER} for owner ${OWNER}"
  exit 1
fi
log "Project ID: $PROJECT_ID"

# Get issue node ID
ISSUE_NODE_ID=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" -q '.node_id' 2>/dev/null)
if [[ -z "$ISSUE_NODE_ID" ]]; then
  log "ERROR: Could not get node_id for issue #${ISSUE_NUMBER}"
  exit 1
fi
log "Issue node ID: $ISSUE_NODE_ID"

# Add issue to project (idempotent)
ITEM_ID=$(gh api graphql -f query='
  mutation($project: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: {projectId: $project, contentId: $contentId}) {
      item { id }
    }
  }' -f project="$PROJECT_ID" -f contentId="$ISSUE_NODE_ID" \
  -q '.data.addProjectV2ItemById.item.id' 2>/dev/null)

if [[ -z "$ITEM_ID" ]]; then
  log "ERROR: Could not add issue to project or get item ID"
  exit 1
fi
log "Project item ID: $ITEM_ID"

# Fetch all fields
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
    }' -f project="$PROJECT_ID" 2>/dev/null)
}

refresh_fields

STATE_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r --arg n "$STATE_FIELD_NAME" \
  '.data.node.fields.nodes[] | select(.name == $n) | .id' 2>/dev/null)
LAST_EVENT_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r --arg n "$LAST_EVENT_FIELD_NAME" \
  '.data.node.fields.nodes[] | select(.name == $n) | .id' 2>/dev/null)
CYCLE_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r --arg n "$CYCLE_FIELD_NAME" \
  '.data.node.fields.nodes[] | select(.name == $n) | .id' 2>/dev/null)

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
  STATE_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r --arg n "$STATE_FIELD_NAME" \
    '.data.node.fields.nodes[] | select(.name == $n) | .id' 2>/dev/null)
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
  LAST_EVENT_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r --arg n "$LAST_EVENT_FIELD_NAME" \
    '.data.node.fields.nodes[] | select(.name == $n) | .id' 2>/dev/null)
fi

log "oem-state field ID:      ${STATE_FIELD_ID:-NOT_FOUND}"
log "oem-last-event field ID: ${LAST_EVENT_FIELD_ID:-NOT_FOUND}"
log "Cycle field ID:          ${CYCLE_FIELD_ID:-NOT_FOUND}"

# Update oem-state (SingleSelect)
if [[ -n "$STATE_FIELD_ID" ]]; then
  OPTION_ID=$(echo "$FIELDS_JSON" | jq -r \
    --arg n "$STATE_FIELD_NAME" \
    --arg state "$STATE" \
    '.data.node.fields.nodes[] | select(.name == $n) | .options[]? | select(.name == $state) | .id' 2>/dev/null)

  if [[ -n "$OPTION_ID" ]]; then
    gh api graphql -f query='
      mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $project, itemId: $item, fieldId: $field,
          value: { singleSelectOptionId: $option }
        }) { projectV2Item { id } }
      }' -f project="$PROJECT_ID" -f item="$ITEM_ID" \
         -f field="$STATE_FIELD_ID" -f option="$OPTION_ID" > /dev/null 2>&1
    log "oem-state updated to: $STATE"
  else
    log "WARNING: option '$STATE' not found in \"${STATE_FIELD_NAME}\" — field may need re-creation"
  fi
fi

# Update oem-last-event (Text)
if [[ -n "$LAST_EVENT_FIELD_ID" ]]; then
  gh api graphql -f query='
    mutation($project: ID!, $item: ID!, $field: ID!, $value: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field,
        value: { text: $value }
      }) { projectV2Item { id } }
    }' -f project="$PROJECT_ID" -f item="$ITEM_ID" \
       -f field="$LAST_EVENT_FIELD_ID" -f value="$LAST_EVENT" > /dev/null 2>&1
  log "oem-last-event updated to: $LAST_EVENT"
fi

# Update Cycle (SingleSelect) — derived from oem-state; skip BLOCKED/REWORKING
DERIVED_CYCLE=$(derive_cycle "$STATE")
if [[ -n "$DERIVED_CYCLE" && -n "$CYCLE_FIELD_ID" ]]; then
  CYCLE_OPTION_ID=$(echo "$FIELDS_JSON" | jq -r \
    --arg n "$CYCLE_FIELD_NAME" \
    --arg cycle "$DERIVED_CYCLE" \
    '.data.node.fields.nodes[] | select(.name == $n) | .options[]? | select(.name == $cycle) | .id' 2>/dev/null)

  if [[ -n "$CYCLE_OPTION_ID" ]]; then
    gh api graphql -f query='
      mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $project, itemId: $item, fieldId: $field,
          value: { singleSelectOptionId: $option }
        }) { projectV2Item { id } }
      }' -f project="$PROJECT_ID" -f item="$ITEM_ID" \
         -f field="$CYCLE_FIELD_ID" -f option="$CYCLE_OPTION_ID" > /dev/null 2>&1
    log "Cycle updated to: $DERIVED_CYCLE"
  else
    log "WARNING: Cycle option '$DERIVED_CYCLE' not found — field may need update"
  fi
else
  [[ -z "$DERIVED_CYCLE" ]] && log "Cycle: no override for state $STATE (BLOCKED/REWORKING)"
fi

# Sync native issue state — closed when DONE, open otherwise
CURRENT_ISSUE_STATE=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" -q '.state' 2>/dev/null)
if [[ "$STATE" == "DONE" ]]; then
  if [[ "$CURRENT_ISSUE_STATE" != "closed" ]]; then
    gh issue close "$ISSUE_NUMBER" --repo "${OWNER}/${REPO}" > /dev/null 2>&1 && \
      log "Issue #${ISSUE_NUMBER} closed (state=DONE)" || \
      log "WARNING: failed to close issue #${ISSUE_NUMBER}"
  else
    log "Issue #${ISSUE_NUMBER} already closed"
  fi
else
  if [[ "$CURRENT_ISSUE_STATE" == "closed" ]]; then
    gh issue reopen "$ISSUE_NUMBER" --repo "${OWNER}/${REPO}" > /dev/null 2>&1 && \
      log "Issue #${ISSUE_NUMBER} reopened (state=${STATE})" || \
      log "WARNING: failed to reopen issue #${ISSUE_NUMBER}"
  fi
fi

log "GitHub sync complete"
