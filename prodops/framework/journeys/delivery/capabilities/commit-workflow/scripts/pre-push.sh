#!/usr/bin/env bash
# pre-push.sh
#
# Runs before push: build → integration tests → contract validation → quality gates
# All commands are discovered from the project; nothing is hardcoded.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'

step() { echo -e "\n${CYAN}▶${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
fail() { echo -e "  ${RED}✗${RESET} $*"; }

cd "$REPO_ROOT"

has_script() {
  local file="$1" key="$2"
  [[ -f "$file" ]] && node -e "
const data = require(process.argv[1]);
process.exit(process.argv[2] in (data.scripts || {}) ? 0 : 1);
" "$PWD/$file" "$key" 2>/dev/null
}

# ── 1. Build ──────────────────────────────────────────────────────────────────
step "Build"

if [[ -f Makefile ]] && grep -q "^build\b" Makefile; then
  make build && ok "Build passed" || { fail "Build failed"; exit 1; }
elif [[ -f api/package.json ]] && has_script api/package.json build; then
  (cd api && npm run build) && ok "Build passed" || { fail "Build failed"; exit 1; }
elif [[ -f package.json ]] && has_script package.json build; then
  npm run build && ok "Build passed" || { fail "Build failed"; exit 1; }
else
  ok "No build script found — skipping"
fi

# ── 2. Integration / acceptance tests ─────────────────────────────────────────
step "Integration tests"

if [[ -f Makefile ]] && grep -q "^test:acceptance\b\|^test-acceptance\b" Makefile; then
  make test:acceptance && ok "Integration tests passed" || { fail "Integration tests failed"; exit 1; }
elif [[ -f scripts/test-acceptance.sh ]]; then
  ./scripts/test-acceptance.sh && ok "Acceptance tests passed" || { fail "Acceptance tests failed"; exit 1; }
elif [[ -f api/package.json ]] && has_script api/package.json "test:acceptance"; then
  (cd api && npm run test:acceptance) && ok "Acceptance tests passed" \
    || { fail "Acceptance tests failed"; exit 1; }
else
  ok "No integration test script found — skipping"
fi

# ── 3. Contract validation ────────────────────────────────────────────────────
step "Contract validation"

if [[ -f Makefile ]] && grep -q "^validate\b\|^contract\b" Makefile; then
  make validate && ok "Contracts validated" || { fail "Contract validation failed"; exit 1; }
else
  ok "No contract validation script found — skipping"
fi

# ── 4. Quality gates ──────────────────────────────────────────────────────────
step "Quality gates"

if [[ -f Makefile ]] && grep -q "^quality\b\|^quality-gate\b" Makefile; then
  make quality && ok "Quality gates passed" || { fail "Quality gates failed"; exit 1; }
else
  ok "No additional quality gate script found — skipping"
fi

echo ""
echo -e "${GREEN}${BOLD}pre-push passed — safe to push${RESET}"
