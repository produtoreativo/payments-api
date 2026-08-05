#!/usr/bin/env bash
# Runtime Doctor — verifies all prerequisites for bootstrap-runtime.sh
# Exit code: 0 = PASS or WARNING only; 1 = FAIL detected

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"

PASS=0; WARN=0; FAIL=0

pass()    { echo "  [PASS] $*"; ((PASS++)) || true; }
warn()    { echo "  [WARN] $*"; ((WARN++)) || true; }
fail()    { echo "  [FAIL] $*"; ((FAIL++)) || true; }

yaml_get() {
  python3 - "$1" "$2" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
keys = sys.argv[2].split('.')
val = data
for k in keys:
    val = val[k]
print(val)
PYEOF
}

echo ""
echo "┌──────────────────────────────────────┐"
echo "│   ProdOps Runtime Doctor             │"
echo "│   runtime v0.3.0                     │"
echo "└──────────────────────────────────────┘"
echo ""

# ── Tools ─────────────────────────────────────────────────────────────────────
echo "Tools:"

if command -v jq &>/dev/null; then
  pass "jq installed ($(jq --version))"
else
  fail "jq is not installed — required for JSON processing"
fi

if command -v curl &>/dev/null; then
  pass "curl installed"
else
  fail "curl is not installed — required for Datadog HTTP API"
fi

if command -v python3 &>/dev/null && python3 -c "import yaml" &>/dev/null; then
  pass "python3 + PyYAML installed — used for YAML parsing"
else
  fail "python3 with PyYAML is not available — required for runtime.yaml and catalog/events.yaml parsing (pip install pyyaml)"
fi

if command -v gh &>/dev/null; then
  pass "gh CLI installed ($(gh --version | head -1))"
else
  fail "gh CLI is not installed — required for GitHub Project sync"
fi

if command -v yq &>/dev/null; then
  pass "yq installed (not used — python3+PyYAML is the YAML parser)"
else
  pass "yq not installed — not required (python3+PyYAML is used instead)"
fi

echo ""

# ── Configuration ─────────────────────────────────────────────────────────────
echo "Configuration:"

if [[ -f "$CONFIG" ]]; then
  pass "runtime.yaml found at $CONFIG"
  RUNTIME_VERSION=$(yaml_get "$CONFIG" "runtime-version" 2>/dev/null)
  CATALOG_VERSION=$(yaml_get "$CONFIG" "catalog-version" 2>/dev/null)
  GH_OWNER=$(yaml_get "$CONFIG" "github.owner" 2>/dev/null)
  GH_PROJECT=$(yaml_get "$CONFIG" "github.project-number" 2>/dev/null)
  GH_REPO=$(yaml_get "$CONFIG" "github.repository" 2>/dev/null)
  PILOT_ISSUE=$(yaml_get "$CONFIG" "github.pilot-issue" 2>/dev/null)
  pass "runtime-version: $RUNTIME_VERSION | catalog-version: $CATALOG_VERSION"
else
  fail "runtime.yaml not found at $CONFIG"
  GH_OWNER=""; GH_PROJECT=""; GH_REPO=""; PILOT_ISSUE=""
fi

CATALOG="$RUNTIME_DIR/catalog/events.yaml"
if [[ -f "$CATALOG" ]]; then
  pass "catalog/events.yaml found"
else
  fail "catalog/events.yaml not found at $CATALOG"
fi

echo ""

# ── GitHub ─────────────────────────────────────────────────────────────────────
echo "GitHub:"

if gh auth status &>/dev/null; then
  GH_USER=$(gh api user -q '.login' 2>/dev/null)
  pass "gh CLI authenticated as: $GH_USER"
else
  fail "gh CLI is not authenticated — run: gh auth login"
fi

if [[ -n "$GH_OWNER" && -n "$GH_PROJECT" ]]; then
  PROJECT_ID=$(gh api graphql -f query='
    query($owner: String!, $number: Int!) {
      organization(login: $owner) { projectV2(number: $number) { id title } }
    }' -f owner="$GH_OWNER" -F number="$GH_PROJECT" \
    2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); p=d['data']['organization']['projectV2']; print(p['title'])" 2>/dev/null) || PROJECT_ID=""

  if [[ -n "$PROJECT_ID" ]]; then
    pass "GitHub Project #${GH_PROJECT} accessible: \"${PROJECT_ID}\""
  else
    fail "GitHub Project #${GH_PROJECT} not accessible for owner: ${GH_OWNER}"
  fi
fi

if [[ -n "$GH_OWNER" && -n "$GH_REPO" && -n "$PILOT_ISSUE" ]]; then
  ISSUE_STATE=$(gh api "repos/${GH_OWNER}/${GH_REPO}/issues/${PILOT_ISSUE}" -q '.state' 2>/dev/null) || ISSUE_STATE=""
  if [[ "$ISSUE_STATE" == "open" || "$ISSUE_STATE" == "closed" ]]; then
    ISSUE_TITLE=$(gh api "repos/${GH_OWNER}/${GH_REPO}/issues/${PILOT_ISSUE}" -q '.title' 2>/dev/null)
    pass "Pilot issue #${PILOT_ISSUE} exists: \"${ISSUE_TITLE}\" (${ISSUE_STATE})"
  else
    fail "Pilot issue #${PILOT_ISSUE} not found in ${GH_OWNER}/${GH_REPO}"
  fi
fi

echo ""

# ── Datadog ────────────────────────────────────────────────────────────────────
echo "Datadog:"

# DD_API_KEY and DD_APP_KEY must be set as environment variables before running.

if [[ -n "${DD_API_KEY:-}" ]]; then
  KEY_PREVIEW="${DD_API_KEY:0:8}..."
  pass "DD_API_KEY is set (${KEY_PREVIEW})"
else
  fail "DD_API_KEY is not set — required for publishing metrics"
fi

if [[ -n "${DD_APP_KEY:-}" ]]; then
  pass "DD_APP_KEY is set"
else
  warn "DD_APP_KEY is not set — not required for publishing metrics, but needed for Datadog API reads"
fi

echo ""

# ── Result ─────────────────────────────────────────────────────────────────────
echo "──────────────────────────────────────────"
if (( FAIL > 0 )); then
  echo "  Result: FAIL  ($PASS passed, $WARN warnings, $FAIL failures)"
  echo "  Fix the FAIL items before running bootstrap-runtime.sh."
  echo ""
  exit 1
elif (( WARN > 0 )); then
  echo "  Result: PASS with WARNINGS  ($PASS passed, $WARN warnings)"
  echo "  Runtime is operational. Review warnings when convenient."
else
  echo "  Result: PASS  ($PASS passed)"
fi
echo ""
