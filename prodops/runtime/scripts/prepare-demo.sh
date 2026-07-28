#!/usr/bin/env bash
# prepare-demo.sh — Valida e prepara o ambiente antes da gravação do EXP-014 Iter 2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
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

GH_OWNER=$(yaml_get "github.owner")
GH_PROJECT=$(yaml_get "github.project-number")

ENV_FILE="$PRODOPS_DIR/../api/.env"
for KEY in DD_API_KEY DD_APP_KEY DD_SITE; do
  if [[ -z "${!KEY:-}" && -f "$ENV_FILE" ]]; then
    VAL=$(grep -E "^${KEY}=" "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'") || true
    [[ -n "$VAL" ]] && export "$KEY=$VAL"
  fi
done
DD_SITE="${DD_SITE:-datadoghq.com}"

PASS=0; FAIL=0; WARN=0

check() {
  local STATUS="$1"; local MSG="$2"
  case "$STATUS" in
    PASS) echo "  [PASS] $MSG"; PASS=$((PASS+1)) ;;
    FAIL) echo "  [FAIL] $MSG"; FAIL=$((FAIL+1)) ;;
    WARN) echo "  [WARN] $MSG"; WARN=$((WARN+1)) ;;
  esac
}

echo ""
echo "┌────────────────────────────────────────────────────────────────┐"
echo "│  EXP-014 — Demo Preparation Check                             │"
echo "└────────────────────────────────────────────────────────────────┘"
echo ""

# ── Runtime Doctor ─────────────────────────────────────────────────────────
echo "── Runtime Doctor"
if bash "$SCRIPT_DIR/runtime-doctor.sh" > /dev/null 2>&1; then
  check PASS "Runtime Doctor: PASS"
else
  check FAIL "Runtime Doctor: FAIL — run runtime-doctor.sh for details"
fi

# ── Credentials ────────────────────────────────────────────────────────────
echo ""
echo "── Credentials"
if [[ -n "${DD_API_KEY:-}" ]]; then
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.${DD_SITE}/api/v1/validate" -H "DD-API-KEY: ${DD_API_KEY}")
  [[ "$HTTP" == "200" ]] && check PASS "DD_API_KEY valid (HTTP 200)" || check FAIL "DD_API_KEY invalid (HTTP $HTTP)"
else
  check FAIL "DD_API_KEY not set"
fi

if [[ -n "${DD_APP_KEY:-}" ]]; then
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.${DD_SITE}/api/v1/validate" \
    -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}")
  [[ "$HTTP" == "200" ]] && check PASS "DD_APP_KEY valid (HTTP 200)" || check FAIL "DD_APP_KEY invalid (HTTP $HTTP)"
else
  check FAIL "DD_APP_KEY not set (needed for Dashboard)"
fi

# ── GitHub Project ─────────────────────────────────────────────────────────
echo ""
echo "── GitHub Project #${GH_PROJECT}"

PROJECT_DATA=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    organization(login: $owner) {
      projectV2(number: $number) {
        id title
        views(first: 10) { nodes { id name layout } }
        fields(first: 50) {
          nodes {
            ... on ProjectV2Field { id name }
            ... on ProjectV2SingleSelectField { id name }
          }
        }
        items(first: 5) { totalCount }
      }
    }
  }' -f owner="$GH_OWNER" -F number="$GH_PROJECT" 2>/dev/null || echo '{}')

PROJECT_TITLE=$(echo "$PROJECT_DATA" | jq -r '.data.organization.projectV2.title // empty')
if [[ -n "$PROJECT_TITLE" ]]; then
  check PASS "GitHub Project #${GH_PROJECT} accessible: \"${PROJECT_TITLE}\""
else
  check FAIL "GitHub Project #${GH_PROJECT} not accessible"
fi

# Check views
for VIEW_NAME in "01 — Delivery Timeline" "02 — Iteration Plan" "03 — Diligence Tracking" "04 — Runtime Reconciliation"; do
  VID=$(echo "$PROJECT_DATA" | jq -r --arg n "$VIEW_NAME" \
    '.data.organization.projectV2.views.nodes[] | select(.name == $n) | .id // empty')
  if [[ -n "$VID" ]]; then
    check PASS "View: \"${VIEW_NAME}\""
  else
    check WARN "View not found: \"${VIEW_NAME}\" — run create-github-views.sh"
  fi
done

# Check fields
for FIELD_NAME in "oem-state" "oem-last-event" "diligence-status" "diligence-evidence" "runtime-sync"; do
  FID=$(echo "$PROJECT_DATA" | jq -r --arg n "$FIELD_NAME" \
    '.data.organization.projectV2.fields.nodes[] | select(.name == $n) | .id // empty')
  if [[ -n "$FID" ]]; then
    check PASS "Field: \"${FIELD_NAME}\""
  else
    check WARN "Field not found: \"${FIELD_NAME}\""
  fi
done

# Check pilot issues in project
for ISSUE in 76 77 78; do
  ISSUE_EXISTS=$(gh api "repos/${GH_OWNER}/$(yaml_get 'github.repository')/issues/${ISSUE}" \
    -q '.number // empty' 2>/dev/null || echo "")
  if [[ -n "$ISSUE_EXISTS" ]]; then
    check PASS "Pilot issue #${ISSUE} exists"
  else
    check FAIL "Pilot issue #${ISSUE} not found"
  fi
done

# ── Datadog Dashboard ─────────────────────────────────────────────────────
echo ""
echo "── Datadog Dashboard (EXP-014)"
DEMO_DASH_META="$PRODOPS_DIR/artifacts/runtime/datadog-demo-dashboard-metadata.json"
if [[ -f "$DEMO_DASH_META" ]]; then
  DASH_ID=$(jq -r '.id' "$DEMO_DASH_META")
  DASH_TITLE=$(jq -r '.title' "$DEMO_DASH_META")
  check PASS "Demo Dashboard: \"${DASH_TITLE}\" (${DASH_ID})"
  echo "         URL: https://app.${DD_SITE}/dashboard/${DASH_ID}"
else
  check WARN "Demo Dashboard not created yet — run create-demo-dashboard.sh"
fi

# ── Delivery derived states ────────────────────────────────────────────────
echo ""
echo "── Delivery Derived States (from EXP-013)"
for ISSUE in 76 77 78; do
  DS_FILE="$PRODOPS_DIR/artifacts/runtime/derived-state-${ISSUE}.json"
  if [[ -f "$DS_FILE" ]]; then
    STATE=$(jq -r '.state' "$DS_FILE")
    check PASS "derived-state-${ISSUE}.json exists: state=${STATE}"
  else
    check WARN "derived-state-${ISSUE}.json not found — run EXP-013 first"
  fi
done

# ── Catalog ────────────────────────────────────────────────────────────────
echo ""
echo "── Event Catalog"
CATALOG="$RUNTIME_DIR/catalog/events.yaml"
if [[ -f "$CATALOG" ]]; then
  EVENT_COUNT=$(python3 - "$CATALOG" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
print(len(data['events']))
PYEOF
)
  check PASS "events.yaml: ${EVENT_COUNT} events"
  for EVENT in "Diligence.Capture.Started" "Diligence.Capture.Completed" \
               "Diligence.Attach.Started" "Diligence.Attach.Completed"; do
    EXISTS=$(python3 - "$CATALOG" "$EVENT" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
print("yes" if sys.argv[2] in data['events'] else "no")
PYEOF
)
    [[ "$EXISTS" == "yes" ]] && check PASS "Catalog: ${EVENT}" || check FAIL "Catalog: ${EVENT} missing"
  done
else
  check FAIL "events.yaml not found"
fi

# ── Generate demo-context.json ─────────────────────────────────────────────
echo ""
echo "── Generating demo-context.json..."
DEMO_RUN_ID="exp-014-demo-$(date -u +%Y-%m-%d-%H%M)"

jq -n \
  --arg demo_run_id    "$DEMO_RUN_ID" \
  --arg project_url    "https://github.com/orgs/${GH_OWNER}/projects/${GH_PROJECT}" \
  --arg demo_cmd       "bash prodops/runtime/scripts/demo-delivery-with-diligence.sh --demo --with-diligence --demo-run-id ${DEMO_RUN_ID}" \
  --arg prepared_at    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  '{
    "demo-run-id": $demo_run_id,
    "prepared-at": $prepared_at,
    "project-url": $project_url,
    "demo-command": $demo_cmd,
    "features": ["#76 FTR-001 Invoice PIX", "#77 FTR-002 Invoice Cartao", "#78 FTR-003 Confirmacao Pagamento"],
    "target-delivery-states": {"76":"DONE","77":"VALIDATING","78":"HACKING"},
    "target-diligence-states": {"diligence-status":"Attached","diligence-evidence":"Complete","runtime-sync":"In Sync"}
  }' > "$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/demo-context.json"

echo "  Saved: prodops/artifacts/experiments/014-diligence-tracks-delivery/evidence/demo-context.json"
echo ""

# ── Summary ────────────────────────────────────────────────────────────────
echo "──────────────────────────────────────────"
echo ""
echo "  Total checks — PASS: ${PASS} | WARN: ${WARN} | FAIL: ${FAIL}"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "  Result: NOT READY — resolve FAIL items before recording"
  echo ""
  exit 1
elif [[ $WARN -gt 0 ]]; then
  echo "  Result: READY WITH WARNINGS — review WARN items"
  echo ""
  echo "  Suggested command:"
  echo "    ${DEMO_RUN_ID}"
  echo "    bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \\"
  echo "         --demo --with-diligence --demo-run-id ${DEMO_RUN_ID}"
else
  echo "  Result: DEMO READY ✅"
  echo ""
  echo "  Suggested command:"
  echo "    bash prodops/runtime/scripts/demo-delivery-with-diligence.sh \\"
  echo "         --demo --with-diligence --demo-run-id ${DEMO_RUN_ID}"
fi
echo ""
