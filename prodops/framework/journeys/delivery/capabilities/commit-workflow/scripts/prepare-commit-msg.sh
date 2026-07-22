#!/usr/bin/env bash
# prepare-commit-msg.sh
#
# Adds the commit template when there is no existing message.
# Does NOT overwrite messages from: -m flag, merge commits, squash commits.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="${2:-}"

TEMPLATE="$REPO_ROOT/prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/commit-template.txt"

# Only apply template to blank commits (no -m, no merge, no squash)
if [[ -z "$COMMIT_SOURCE" ]] && [[ -f "$TEMPLATE" ]]; then
  # Preserve any existing content (e.g., from a previous prepare-commit-msg run)
  if ! grep -qE '^[^#]' "$COMMIT_MSG_FILE" 2>/dev/null; then
    cat "$TEMPLATE" >> "$COMMIT_MSG_FILE"
  fi
fi
