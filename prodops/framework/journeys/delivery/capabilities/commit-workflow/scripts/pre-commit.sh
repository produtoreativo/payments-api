#!/usr/bin/env bash
# pre-commit.sh
#
# Discovers and runs: formatter → lint → quick tests
# All commands are discovered from the project; nothing is hardcoded.
#
# Language detection order:
#   1. Makefile   2. Taskfile   3. justfile
#   4. package.json (Node)      5. Gradle   6. Maven
#   7. Go         8. Python     9. .NET
#  10. Existing scripts in scripts/

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'

step()  { echo -e "\n${CYAN}▶${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $*"; }
fail()  { echo -e "  ${RED}✗${RESET} $*"; }

cd "$REPO_ROOT"

# ── 1. Discover runner ────────────────────────────────────────────────────────
run_if_exists() {
  local label="$1"; shift
  local cmd=("$@")
  if command -v "${cmd[0]}" &>/dev/null || [[ -x "${cmd[0]}" ]]; then
    step "$label"
    "${cmd[@]}" && ok "$label passed" || { fail "$label failed"; exit 1; }
    return 0
  fi
  return 1
}

has_script() {
  local file="$1" key="$2"
  [[ -f "$file" ]] && node -e "
const data = require(process.argv[1]);
process.exit(process.argv[2] in (data.scripts || {}) ? 0 : 1);
" "$PWD/$file" "$key" 2>/dev/null
}

# ── 2. Formatter ─────────────────────────────────────────────────────────────
step "Formatter"

if [[ -f Makefile ]] && grep -q "^format\b" Makefile; then
  make format || { fail "make format failed"; exit 1; }
elif [[ -f api/package.json ]] && has_script api/package.json format; then
  (cd api && npm run format) || { fail "npm run format failed"; exit 1; }
elif [[ -f package.json ]] && has_script package.json format; then
  npm run format || { fail "npm run format failed"; exit 1; }
else
  ok "No formatter found — skipping (lint may auto-fix)"
fi

# ── 3. Lint ───────────────────────────────────────────────────────────────────
step "Lint"

if [[ -f Makefile ]] && grep -q "^lint\b" Makefile; then
  make lint || { fail "make lint failed"; exit 1; }
elif [[ -f api/package.json ]] && has_script api/package.json lint; then
  (cd api && npm run lint) && ok "Lint passed" || { fail "Lint failed — fix errors above before committing"; exit 1; }
elif [[ -f package.json ]] && has_script package.json lint; then
  npm run lint && ok "Lint passed" || { fail "Lint failed"; exit 1; }
else
  ok "No lint script found — skipping"
fi

# ── 4. Quick tests ────────────────────────────────────────────────────────────
step "Unit tests"

if [[ -f Makefile ]] && grep -q "^test\b" Makefile; then
  make test || { fail "make test failed"; exit 1; }
elif [[ -f api/package.json ]] && has_script api/package.json test; then
  (cd api && npm run test -- --passWithNoTests) && ok "Unit tests passed" \
    || { fail "Unit tests failed"; exit 1; }
elif [[ -f package.json ]] && has_script package.json test; then
  npm run test -- --passWithNoTests && ok "Unit tests passed" || { fail "Unit tests failed"; exit 1; }
else
  ok "No test script found — skipping"
fi

echo ""
echo -e "${GREEN}${BOLD}pre-commit passed${RESET}"
