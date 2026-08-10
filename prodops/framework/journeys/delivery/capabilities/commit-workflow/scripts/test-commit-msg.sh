#!/usr/bin/env bash
# test-commit-msg.sh — Regression suite for commit-msg.sh
#
# Runs the validator through a REAL `git commit` in a throwaway repository,
# wired exactly as this repo wires it (core.hooksPath -> hooks/commit-msg,
# which execs scripts/commit-msg.sh). Calling the script directly would not
# prove the hook is reachable, so the suite exercises the integration path.
#
# The load-bearing property: Conventional Commits rules apply to the SUBJECT
# only. A body sentence ending in a period, a Co-Authored-By trailer, or a long
# body line must never reject a commit whose subject is valid. Reading the whole
# message (`cat "$1"`) instead of the subject (`head -1 "$1"`) breaks exactly
# that, and every ProdOps commit carries a trailer — so the suite pins it.
#
# Usage: ./test-commit-msg.sh      # 0 = all passed, 1 = a case regressed

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPABILITY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CAPABILITY_REL="prodops/framework/journeys/delivery/capabilities/commit-workflow"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "${SANDBOX}"' EXIT

PASSED=0; FAILED=0

# ── Throwaway repo wired like the real one ────────────────────────────────────
cd "${SANDBOX}"
git init -q .
git config user.email "test@prodops.local"
git config user.name "ProdOps Test"
mkdir -p "${CAPABILITY_REL}"
cp -r "${CAPABILITY_DIR}/hooks" "${CAPABILITY_DIR}/scripts" "${CAPABILITY_REL}/"
git config core.hooksPath "${CAPABILITY_REL}/hooks"
echo "seed" > file.txt

# expect <accept|reject> <description> <message>
expect() {
  local want="$1" desc="$2" msg="$3"
  printf '%b' "${msg}" > "${SANDBOX}/.msg"
  echo "${RANDOM}" >> "${SANDBOX}/file.txt"
  git -C "${SANDBOX}" add -A

  local got
  if git -C "${SANDBOX}" commit -F "${SANDBOX}/.msg" >/dev/null 2>&1; then
    got="accept"
  else
    got="reject"
    git -C "${SANDBOX}" reset -q HEAD -- . 2>/dev/null || true
  fi

  if [[ "${got}" == "${want}" ]]; then
    echo -e "  ${GREEN}✓${RESET} ${desc}"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗${RESET} ${desc}  (expected ${want}, got ${got})"
    FAILED=$((FAILED + 1))
  fi
}

echo -e "\n${BOLD}Subject-only scope — the rules must not read the body${RESET}"
# These are the cases a `cat "$1"` regression would break.
expect accept "body sentence ending in a period" \
  'fix(payments): retry on gateway timeout\n\nThe provider retries on timeout.\n'
expect accept "Co-Authored-By trailer (every ProdOps commit has one)" \
  'feat(invoices): add hosted flow\n\nCo-Authored-By: Claude Opus 5 <noreply@anthropic.com>\n'
expect accept "body line far longer than the 72-char subject limit" \
  'docs(finish): clarify push refspec\n\nThis body line is deliberately much longer than seventy-two characters to prove the limit is scoped to the subject.\n'
expect accept "body + trailer together, subject valid" \
  'fix(x): short subject\n\nBody sentence.\n\nCo-Authored-By: Claude Opus 5 <n@a.com>\n'

echo -e "\n${BOLD}Subject rules still enforced${RESET}"
expect reject "subject ends with a period" \
  'fix(payments): ends with a period.\n'
expect reject "subject longer than 72 chars, prefix included" \
  'fix(scope): aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
expect reject "uppercase scope" \
  'fix(Scope): thing\n'
expect reject "unknown type" \
  'wip(x): not a conventional type\n'
expect reject "no type prefix at all" \
  'just a plain message\n'
expect reject "empty summary after the colon" \
  'fix(x): \n'

echo -e "\n${BOLD}Boundaries and exemptions${RESET}"
expect accept "subject exactly 72 chars" \
  'fix(scope): aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
expect accept "breaking-change marker (!)" \
  'feat(api)!: drop v1 endpoint\n'
expect accept "type without scope" \
  'docs: update readme\n'
expect accept "merge commit is exempt" \
  'Merge branch master into feature\n'
expect accept "revert commit is exempt" \
  'Revert "feat(x): something"\n'
expect accept "fixup! commit is exempt" \
  'fixup! fix(x): earlier subject\n'

echo ""
if [[ ${FAILED} -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}✓ commit-msg: ${PASSED} passed${RESET}\n"
  exit 0
fi
echo -e "${RED}${BOLD}✗ commit-msg: ${FAILED} failed, ${PASSED} passed${RESET}\n"
exit 1
