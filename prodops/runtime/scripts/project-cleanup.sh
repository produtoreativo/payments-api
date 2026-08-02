#!/usr/bin/env bash
# project-cleanup.sh — remove all items from the managed GitHub Project
#
# Usage: project-cleanup.sh [--dry-run]
#
# Reads project-number and owner from prodops/runtime/runtime.yaml.
# Safe to run when the project is empty — exits 0 with a message.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"

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

PROJECT_NUMBER=$(yaml_get "github.project-number")
PROJECT_OWNER=$(yaml_get "github.owner")

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[project-cleanup] $*"; }

log "Project: $PROJECT_OWNER #$PROJECT_NUMBER${DRY_RUN:+ (dry-run)}"
log "Fetching items..."

ITEM_IDS=$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
  | jq -r '.items[].id')

COUNT=$(echo "$ITEM_IDS" | grep -c . || true)

if [[ -z "$ITEM_IDS" || "$COUNT" -eq 0 ]]; then
  log "Project is empty — nothing to remove"
  exit 0
fi

log "Found $COUNT item(s) to remove"

while IFS= read -r ITEM_ID; do
  [[ -z "$ITEM_ID" ]] && continue
  if [[ "$DRY_RUN" == "true" ]]; then
    log "Would delete: $ITEM_ID"
  else
    log "Deleting: $ITEM_ID"
    gh project item-delete "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --id "$ITEM_ID"
  fi
done <<< "$ITEM_IDS"

log "Done${DRY_RUN:+ (dry-run — no items deleted)}"
