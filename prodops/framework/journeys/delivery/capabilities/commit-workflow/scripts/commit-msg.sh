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

# Conventional Commits shape. The trailing `.+` only asserts a non-empty
# summary — the length limit is enforced separately below over the WHOLE
# subject line, because `.{1,72}` here would measure only the text after
# `type(scope): `, letting the prefix push the real subject past 72 chars.
PATTERN='^(feat|fix|docs|test|refactor|perf|build|ci|style|chore|revert)(\([a-zA-Z0-9/_-]+\))?!?: .+$'

if ! echo "$MSG" | grep -qE "$PATTERN"; then
  echo ""
  echo "  ✗ Commit message does not follow Conventional Commits format."
  echo ""
  echo "  Expected:  <type>(<scope>): <summary>  (subject max 72 chars)"
  echo "  Received:  $MSG"
  echo ""
  echo "  Valid types: feat fix docs test refactor perf build ci style chore revert"
  echo "  Example:   feat(invoices): add credit card hosted flow"
  echo ""
  echo "  See: prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md#conventional-commits"
  echo ""
  exit 1
fi

# Enforce the summary limit over the entire subject line, prefix included
# (Conventional Commits convention; mirrors commit_summary_max in the manifest).
MAX_SUMMARY=72
if [ "${#MSG}" -gt "$MAX_SUMMARY" ]; then
  echo ""
  echo "  ✗ Commit subject too long: ${#MSG} chars (max ${MAX_SUMMARY})."
  echo ""
  echo "  The limit covers the whole subject line, including the"
  echo "  \"<type>(<scope>): \" prefix — not just the text after it."
  echo "  Received:  $MSG"
  echo ""
  echo "  See: prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md#conventional-commits"
  echo ""
  exit 1
fi

exit 0
