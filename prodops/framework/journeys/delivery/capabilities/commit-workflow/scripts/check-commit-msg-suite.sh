#!/usr/bin/env bash
# check-commit-msg-suite.sh — Runs the commit-msg regression suite, but only
# when the commit-workflow scripts are actually part of this branch's diff.
#
# Why this exists as a script instead of an inline `git diff | grep`:
# the inline form FAILS OPEN. If the base ref cannot be resolved (stale fetch,
# a placeholder pasted literally, a branch with no upstream), `git diff` aborts,
# the pipe yields nothing, `grep` does not match, and the suite is skipped
# silently — precisely when something unusual is going on. Here, an
# undeterminable base means "run it anyway".
#
# Usage:  ./check-commit-msg-suite.sh [base-ref]
#
# Exit codes:
#   0   Suite passed, or correctly skipped (scripts untouched)
#   1   Suite failed — a validator rule regressed
#   2   Base could not be determined; suite was run anyway and passed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="${SCRIPT_DIR}/test-commit-msg.sh"
WATCH_PATH="commit-workflow/scripts/"

[[ -x "${SUITE}" ]] || { echo "check-commit-msg-suite: suite not found: ${SUITE}" >&2; exit 1; }

# ── Resolve the base to diff against ──────────────────────────────────────────
# Precedence: explicit argument > upstream tracker > nothing.
BASE="${1:-}"
BASE_KNOWN=1

if [[ -n "${BASE}" ]]; then
  git rev-parse --verify --quiet "${BASE}" >/dev/null || BASE_KNOWN=0
else
  BASE="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || true)"
  [[ -n "${BASE}" ]] && git rev-parse --verify --quiet "${BASE}" >/dev/null || BASE_KNOWN=0
fi

# ── Decide ────────────────────────────────────────────────────────────────────
# The working tree counts too: a hook script edited but not yet committed still
# means the validator changed.
CHANGED=""
if [[ ${BASE_KNOWN} -eq 1 ]]; then
  CHANGED="$(git diff --name-only "${BASE}...HEAD" 2>/dev/null || true)"
fi
CHANGED+=$'\n'"$(git status --porcelain 2>/dev/null | awk '{print $NF}')"

if [[ ${BASE_KNOWN} -eq 0 ]]; then
  echo "check-commit-msg-suite: base ref undeterminable — running the suite anyway."
  "${SUITE}" || exit 1
  exit 2
fi

if ! grep -q "${WATCH_PATH}" <<<"${CHANGED}"; then
  echo "check-commit-msg-suite: commit-workflow scripts untouched vs ${BASE} — skipping."
  exit 0
fi

echo "check-commit-msg-suite: commit-workflow scripts changed vs ${BASE} — running the suite."
exec "${SUITE}"
