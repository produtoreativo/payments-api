#!/usr/bin/env bash
# commit-msg.sh
#
# Validates Conventional Commits format.
# Pattern: <type>(<optional scope>): <summary>
# Types: feat|fix|docs|test|refactor|perf|build|ci|style|chore|revert

set -euo pipefail

COMMIT_MSG_FILE="$1"
MSG=$(head -1 "$COMMIT_MSG_FILE")

# Allow merge commits, revert commits, and fixup/squash
if echo "$MSG" | grep -qE '^(Merge |Revert |fixup! |squash! )'; then
  exit 0
fi

PATTERN='^(feat|fix|docs|test|refactor|perf|build|ci|style|chore|revert)(\([a-zA-Z0-9/_-]+\))?!?: .{1,72}$'

if ! echo "$MSG" | grep -qE "$PATTERN"; then
  echo ""
  echo "  ✗ Commit message does not follow Conventional Commits format."
  echo ""
  echo "  Expected:  <type>(<scope>): <summary>  (summary max 72 chars)"
  echo "  Received:  $MSG"
  echo ""
  echo "  Valid types: feat fix docs test refactor perf build ci style chore revert"
  echo "  Example:   feat(invoices): add credit card hosted flow"
  echo ""
  echo "  See: prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md#conventional-commits"
  echo ""
  exit 1
fi

exit 0
