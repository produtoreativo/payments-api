#!/usr/bin/env bash
# validate-demo.sh — Valida o resultado do demo após execução
# Usage: validate-demo.sh --demo-run-id <id> [--mode exception-paths]

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

DEMO_RUN_ID=""
VALIDATE_MODE="delivery"   # delivery | exception-paths

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo-run-id) DEMO_RUN_ID="$2"; shift 2 ;;
    --mode)        VALIDATE_MODE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

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

ARTIFACTS_DIR="$PRODOPS_DIR/artifacts/runtime"
RECORDINGS_BASE="$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/recordings"

PASS=0; FAIL=0

check() {
  local STATUS="$1"; local MSG="$2"
  case "$STATUS" in
    PASS) echo "  [PASS] $MSG"; PASS=$((PASS+1)) ;;
    FAIL) echo "  [FAIL] $MSG"; FAIL=$((FAIL+1)) ;;
  esac
}

echo ""
echo "┌────────────────────────────────────────────────────────────────┐"
echo "│  EXP-014 — Demo Validation  (mode: ${VALIDATE_MODE})              │"
if [[ -n "$DEMO_RUN_ID" ]]; then
echo "│  demo-run-id: ${DEMO_RUN_ID:0:44}    │"
fi
echo "└────────────────────────────────────────────────────────────────┘"
echo ""

# ── Demo context ──────────────────────────────────────────────────────────
if [[ -n "$DEMO_RUN_ID" ]]; then
  RECORDING_DIR="${RECORDINGS_BASE}/${DEMO_RUN_ID}"
  if [[ -d "$RECORDING_DIR" ]]; then
    check PASS "Recording directory exists: ${DEMO_RUN_ID}"
    if [[ -f "${RECORDING_DIR}/demo-summary.json" ]]; then
      check PASS "demo-summary.json present"
      echo "         $(jq -c '{delivery: ."delivery-events-total", diligence: ."diligence-events-total"}' "${RECORDING_DIR}/demo-summary.json")"
    else
      check FAIL "demo-summary.json missing"
    fi
  else
    check FAIL "Recording directory not found: ${RECORDING_DIR}"
  fi
fi

# ── Delivery Timeline ─────────────────────────────────────────────────────
echo ""
echo "── Delivery Timeline Validation"
expected_events_for() { case "$1" in 76) echo 15;; 77) echo 11;; 78) echo 3;; esac; }
expected_state_for()  { case "$1" in 76) echo "DONE";; 77) echo "VALIDATING";; 78) echo "HACKING";; esac; }

for ISSUE in 76 77 78; do
  TL="$ARTIFACTS_DIR/timelines/${ISSUE}.json"
  EXPECTED_EV=$(expected_events_for "$ISSUE")
  if [[ -f "$TL" ]]; then
    COUNT=$(jq 'length' "$TL")
    if [[ "$COUNT" -eq "$EXPECTED_EV" ]]; then
      check PASS "Timeline #${ISSUE}: ${COUNT} events (expected: ${EXPECTED_EV})"
    else
      check FAIL "Timeline #${ISSUE}: ${COUNT} events (expected: ${EXPECTED_EV})"
    fi
  else
    check FAIL "Timeline #${ISSUE}: file not found"
  fi
done

# ── Derived State ──────────────────────────────────────────────────────────
echo ""
echo "── Derived State Validation"
for ISSUE in 76 77 78; do
  DS_FILE="$ARTIFACTS_DIR/derived-state-${ISSUE}.json"
  EXPECTED_ST=$(expected_state_for "$ISSUE")
  if [[ -f "$DS_FILE" ]]; then
    STATE=$(jq -r '.state' "$DS_FILE")
    if [[ "$STATE" == "$EXPECTED_ST" ]]; then
      check PASS "derived-state-${ISSUE}.json: ${STATE}"
    else
      check FAIL "derived-state-${ISSUE}.json: ${STATE} (expected: ${EXPECTED_ST})"
    fi
  else
    check FAIL "derived-state-${ISSUE}.json: not found"
  fi
done

# ── Diligence Timeline ────────────────────────────────────────────────────
echo ""
echo "── Diligence Timeline Validation (mode: ${VALIDATE_MODE})"

if [[ "$VALIDATE_MODE" == "exception-paths" ]]; then
  # Expected events per scenario
  # A(#76): Capture.Started/Completed, Attach.Started/Completed, Promote.Started/Completed, Close.Started/Completed = 8
  # B(#77): above minus Attach x2 (pre-block), + Block.Declared, Block.Resolved = 10
  # C(#78): 4 baseline + Scan.Started, Divergence.Detected, Scan.Completed, Flag.Started/Completed, Repair.Started/Completed, Promote.Started/Completed, Close.Started/Completed = 15
  dil_expected_events_for() { case "$1" in 76) echo 8;; 77) echo 10;; 78) echo 15;; esac; }
  for ISSUE in 76 77 78; do
    DTL="$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json"
    EXPECTED_DIL=$(dil_expected_events_for "$ISSUE")
    if [[ -f "$DTL" ]]; then
      COUNT=$(jq 'length' "$DTL")
      if [[ "$COUNT" -eq "$EXPECTED_DIL" ]]; then
        check PASS "Diligence timeline #${ISSUE}: ${COUNT} events (expected: ${EXPECTED_DIL})"
      else
        check FAIL "Diligence timeline #${ISSUE}: ${COUNT} events (expected: ${EXPECTED_DIL})"
      fi
      # Cross-reference
      DEL_STATE=$(jq -r '.[0].data["delivery-derived-state"] // empty' "$DTL")
      DEL_CORR=$(jq -r '.[0].data["delivery-correlation-id"] // empty' "$DTL")
      if [[ -n "$DEL_STATE" && -n "$DEL_CORR" ]]; then
        check PASS "  #${ISSUE} cross-reference: delivery-state=${DEL_STATE} | corr=${DEL_CORR:0:8}..."
      else
        check FAIL "  #${ISSUE} cross-reference: delivery context missing"
      fi
      # Verify final event is Close.Completed
      LAST_TYPE=$(jq -r '.[-1].type // empty' "$DTL")
      if [[ "$LAST_TYPE" == "prodops.diligence.close.completed" ]]; then
        check PASS "  #${ISSUE} last event: Close.Completed ✓"
      else
        check FAIL "  #${ISSUE} last event: ${LAST_TYPE} (expected: prodops.diligence.close.completed)"
      fi
      # Scenario-specific checks
      if [[ "$ISSUE" == "77" ]]; then
        HAS_BLOCK=$(jq '[.[].type | select(. == "prodops.diligence.block.declared")] | length' "$DTL")
        HAS_RESOLVED=$(jq '[.[].type | select(. == "prodops.diligence.block.resolved")] | length' "$DTL")
        if [[ "$HAS_BLOCK" -ge 1 ]]; then
          check PASS "  #77 Block.Declared present (${HAS_BLOCK})"
        else
          check FAIL "  #77 Block.Declared missing — block not validated"
        fi
        if [[ "$HAS_RESOLVED" -ge 1 ]]; then
          check PASS "  #77 Block.Resolved present (${HAS_RESOLVED})"
        else
          check FAIL "  #77 Block.Resolved missing"
        fi
      fi
      if [[ "$ISSUE" == "78" ]]; then
        HAS_DIV=$(jq '[.[].type | select(. == "prodops.diligence.divergence.detected")] | length' "$DTL")
        HAS_REPAIR=$(jq '[.[].type | select(. == "prodops.diligence.repair.completed")] | length' "$DTL")
        if [[ "$HAS_DIV" -ge 1 ]]; then
          check PASS "  #78 Divergence.Detected present ✓"
        else
          check FAIL "  #78 Divergence.Detected missing — drift not validated"
        fi
        if [[ "$HAS_REPAIR" -ge 1 ]]; then
          check PASS "  #78 Repair.Completed present ✓"
        else
          check FAIL "  #78 Repair.Completed missing"
        fi
        # Repair must reference derived state, not GitHub
        REPAIR_SOURCE=$(jq -r '[.[] | select(.type == "prodops.diligence.repair.started") | .data["repair-source"] // ""] | .[0]' "$DTL")
        if [[ "$REPAIR_SOURCE" == *"derived-state"* ]]; then
          check PASS "  #78 Repair source: ${REPAIR_SOURCE}"
        else
          check FAIL "  #78 Repair did not consult Derived State (source: ${REPAIR_SOURCE:-empty})"
        fi
      fi
    else
      check FAIL "Diligence timeline diligence-${ISSUE}: not found"
    fi
  done
else
  for ISSUE in 76 77 78; do
    DTL="$ARTIFACTS_DIR/timelines/diligence-${ISSUE}.json"
    if [[ -f "$DTL" ]]; then
      COUNT=$(jq 'length' "$DTL")
      TYPES=$(jq -r '[.[].type] | join(", ")' "$DTL")
      if [[ "$COUNT" -eq 4 ]]; then
        check PASS "Diligence timeline diligence-${ISSUE}: ${COUNT} events"
      else
        check FAIL "Diligence timeline diligence-${ISSUE}: ${COUNT} events (expected: 4)"
      fi
      DEL_STATE=$(jq -r '.[0].data["delivery-derived-state"] // empty' "$DTL")
      DEL_CORR=$(jq -r '.[0].data["delivery-correlation-id"] // empty' "$DTL")
      if [[ -n "$DEL_STATE" && -n "$DEL_CORR" ]]; then
        check PASS "  Cross-reference: delivery-state=${DEL_STATE} | delivery-corr=${DEL_CORR:0:8}..."
      else
        check FAIL "  Cross-reference: delivery context missing in diligence events"
      fi
    else
      check FAIL "Diligence timeline diligence-${ISSUE}: not found"
    fi
  done
fi

# ── GitHub Project ────────────────────────────────────────────────────────
echo ""
echo "── GitHub Project #${GH_PROJECT} Validation"

PROJECT_ID=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    organization(login: $owner) {
      projectV2(number: $number) { id }
    }
  }' -f owner="$GH_OWNER" -F number="$GH_PROJECT" \
  -q '.data.organization.projectV2.id' 2>/dev/null)

GH_DATA=$(gh api graphql -f query='
  query($project: ID!) {
    node(id: $project) {
      ... on ProjectV2 {
        items(first: 20) {
          nodes {
            content { ... on Issue { number } }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
        }
      }
    }
  }' -f project="$PROJECT_ID" 2>/dev/null)

for ISSUE in 76 77 78; do
  ITEM=$(echo "$GH_DATA" | jq --argjson i "$ISSUE" \
    '.data.node.items.nodes[] | select(.content.number == $i)')
  OEM=$(echo "$ITEM" | jq -r '.fieldValues.nodes[] | select(.field.name=="oem-state") | .name // empty')
  DS=$(echo "$ITEM"  | jq -r '.fieldValues.nodes[] | select(.field.name=="diligence-status") | .name // empty')
  DE=$(echo "$ITEM"  | jq -r '.fieldValues.nodes[] | select(.field.name=="diligence-evidence") | .name // empty')
  RS=$(echo "$ITEM"  | jq -r '.fieldValues.nodes[] | select(.field.name=="runtime-sync") | .name // empty')

  EXPECTED_OEM=$(expected_state_for "$ISSUE")
  if [[ "$OEM" == "$EXPECTED_OEM" ]]; then
    check PASS "#${ISSUE} oem-state=${OEM}"
  else
    check FAIL "#${ISSUE} oem-state=${OEM} (expected: ${EXPECTED_OEM})"
  fi

  if [[ "$VALIDATE_MODE" == "exception-paths" ]]; then
    # All features must end at Closed/Complete/In Sync
    if [[ "$DS" == "Closed" ]]; then
      check PASS "#${ISSUE} diligence-status=${DS}"
    else
      check FAIL "#${ISSUE} diligence-status=${DS} (expected: Closed)"
    fi
    if [[ "$DE" == "Complete" ]]; then
      check PASS "#${ISSUE} diligence-evidence=${DE}"
    else
      check FAIL "#${ISSUE} diligence-evidence=${DE} (expected: Complete)"
    fi
    if [[ "$RS" == "In Sync" ]]; then
      check PASS "#${ISSUE} runtime-sync=${RS}"
    else
      check FAIL "#${ISSUE} runtime-sync=${RS} (expected: In Sync)"
    fi
  else
    if [[ "$DS" == "Attached" ]]; then
      check PASS "#${ISSUE} diligence-status=${DS}"
    else
      check FAIL "#${ISSUE} diligence-status=${DS} (expected: Attached)"
    fi
    if [[ "$DE" == "Complete" ]]; then
      check PASS "#${ISSUE} diligence-evidence=${DE}"
    else
      check FAIL "#${ISSUE} diligence-evidence=${DE} (expected: Complete)"
    fi
    if [[ "$RS" == "In Sync" ]]; then
      check PASS "#${ISSUE} runtime-sync=${RS}"
    else
      check FAIL "#${ISSUE} runtime-sync=${RS} (expected: In Sync)"
    fi
  fi
done

# ── Exception-Paths specific checks ──────────────────────────────────────
if [[ "$VALIDATE_MODE" == "exception-paths" ]]; then
  echo ""
  echo "── Exception-Paths Checks"
  EVIDENCE_DIR="$PRODOPS_DIR/artifacts/experiments/014-diligence-tracks-delivery/evidence/diligence-exception-paths"

  # Finding JSON for #78
  FINDING_FILE=$(ls "${EVIDENCE_DIR}"/finding-FND-*.json 2>/dev/null | head -1 || true)
  if [[ -n "$FINDING_FILE" ]]; then
    FINDING_ID=$(jq -r '."finding-id"' "$FINDING_FILE")
    FINDING_STATUS=$(jq -r '.status' "$FINDING_FILE")
    FINDING_SEV=$(jq -r '.severity' "$FINDING_FILE")
    REPAIR_SOURCE=$(jq -r '."source-of-truth"' "$FINDING_FILE")
    check PASS "Finding JSON: ${FINDING_ID} (status: ${FINDING_STATUS})"
    if [[ "$FINDING_STATUS" == "Closed" ]]; then
      check PASS "  Finding closed ✓"
    else
      check FAIL "  Finding not closed (status: ${FINDING_STATUS})"
    fi
    if [[ "$FINDING_SEV" == "HIGH" ]]; then
      check PASS "  Finding severity: HIGH ✓"
    else
      check FAIL "  Finding severity: ${FINDING_SEV} (expected: HIGH)"
    fi
    if [[ "$REPAIR_SOURCE" == *"Derived State"* || "$REPAIR_SOURCE" == *"derived-state"* ]]; then
      check PASS "  Repair source of truth: Derived State ✓"
    else
      check FAIL "  Repair source not Derived State (got: ${REPAIR_SOURCE})"
    fi
  else
    check FAIL "Finding JSON not found in evidence/diligence-exception-paths/"
  fi

  # github-before-after
  GH_BEFORE_AFTER="${EVIDENCE_DIR}/github-before-after.json"
  if [[ -f "$GH_BEFORE_AFTER" ]]; then
    DRIFT_FIELD=$(jq -r '."drift-field"' "$GH_BEFORE_AFTER")
    REPAIRED_TO=$(jq -r '."repaired-to"' "$GH_BEFORE_AFTER")
    check PASS "github-before-after.json: drift-field=${DRIFT_FIELD} repaired-to=${REPAIRED_TO}"
  else
    check FAIL "github-before-after.json not found"
  fi

  # Delivery Timeline preservation
  echo ""
  echo "  ── Delivery Timeline Preservation"
  RECORDING_DIR="${RECORDINGS_BASE}/${DEMO_RUN_ID}"
  if [[ -n "$DEMO_RUN_ID" && -d "${RECORDING_DIR}/diligence-timelines" ]]; then
    check PASS "Diligence timelines archived at: ${DEMO_RUN_ID}/diligence-timelines/"
    for ISSUE in 76 77 78; do
      DIL_ARCHIVED="${RECORDING_DIR}/diligence-timelines/diligence-${ISSUE}.json"
      DEL_TL="$ARTIFACTS_DIR/timelines/${ISSUE}.json"
      if [[ -f "$DIL_ARCHIVED" ]]; then
        ARCH_COUNT=$(jq 'length' "$DIL_ARCHIVED")
        check PASS "  Archived diligence-${ISSUE}.json: ${ARCH_COUNT} events"
      else
        check FAIL "  Archived diligence-${ISSUE}.json not found"
      fi
      # Delivery timeline must NOT contain diligence event types
      if [[ -f "$DEL_TL" ]]; then
        DIL_IN_DEL=$(jq '[.[].type | select(startswith("prodops.diligence."))] | length' "$DEL_TL")
        if [[ "$DIL_IN_DEL" -eq 0 ]]; then
          check PASS "  #${ISSUE} Delivery Timeline unmodified (no diligence events)"
        else
          check FAIL "  #${ISSUE} Delivery Timeline contains ${DIL_IN_DEL} diligence events — INTEGRITY VIOLATION"
        fi
      fi
    done
  else
    check FAIL "Diligence timeline archives not found (demo-run-id: ${DEMO_RUN_ID:-missing})"
  fi

  # Block did not allow Promote to pass (#77)
  echo ""
  echo "  ── Block Gate Validation (#77)"
  DTL77="$ARTIFACTS_DIR/timelines/diligence-77.json"
  if [[ -f "$DTL77" ]]; then
    # Block.Declared must appear before Promote.Started
    BLOCK_IDX=$(jq '[to_entries[] | select(.value.type == "prodops.diligence.block.declared") | .key] | .[0] // -1' "$DTL77")
    PROMOTE_IDX=$(jq '[to_entries[] | select(.value.type == "prodops.diligence.promote.started") | .key] | .[0] // -1' "$DTL77")
    if [[ "$BLOCK_IDX" -ge 0 && "$PROMOTE_IDX" -ge 0 && "$BLOCK_IDX" -lt "$PROMOTE_IDX" ]]; then
      check PASS "  #77 Block (idx=${BLOCK_IDX}) precedes Promote.Started (idx=${PROMOTE_IDX}) ✓"
    elif [[ "$BLOCK_IDX" -lt 0 ]]; then
      check FAIL "  #77 Block.Declared not found"
    else
      check FAIL "  #77 Promote.Started (idx=${PROMOTE_IDX}) preceded Block.Declared (idx=${BLOCK_IDX})"
    fi
  fi
fi

# ── Datadog ───────────────────────────────────────────────────────────────
echo ""
echo "── Datadog API Validation"
if [[ -n "${DD_API_KEY:-}" && -n "${DD_APP_KEY:-}" ]]; then
  # Query delivery events
  NOW=$(date +%s)
  FROM=$((NOW - 1800))  # last 30 min

  QUERY_RESULT=$(curl -s \
    --get --data-urlencode "query=sum:runtime.event.received{service:$(yaml_get 'datadog.service')}.as_count()" \
    --data-urlencode "from=${FROM}" --data-urlencode "to=${NOW}" \
    "https://api.${DD_SITE}/api/v1/query" \
    -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" 2>/dev/null)

  QR_STATUS=$(echo "$QUERY_RESULT" | jq -r '.status // empty')
  if [[ "$QR_STATUS" == "ok" ]]; then
    check PASS "Datadog API query: runtime.event.received (status: ok)"
  else
    check FAIL "Datadog API query failed (status: ${QR_STATUS})"
  fi

  DQUERY_RESULT=$(curl -s \
    --get --data-urlencode "query=sum:runtime.diligence.event.received{service:$(yaml_get 'datadog.service')}.as_count()" \
    --data-urlencode "from=${FROM}" --data-urlencode "to=${NOW}" \
    "https://api.${DD_SITE}/api/v1/query" \
    -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" 2>/dev/null)

  DQ_STATUS=$(echo "$DQUERY_RESULT" | jq -r '.status // empty')
  if [[ "$DQ_STATUS" == "ok" ]]; then
    check PASS "Datadog API query: runtime.diligence.event.received (status: ok)"
  else
    check FAIL "Datadog API query failed: runtime.diligence.event.received"
  fi

  if [[ "$VALIDATE_MODE" == "exception-paths" ]]; then
    for METRIC in runtime.diligence.blocked runtime.diligence.drift.detected \
                  runtime.diligence.repairs.completed runtime.diligence.features.closed; do
      EX_RESULT=$(curl -s \
        --get --data-urlencode "query=sum:${METRIC}{service:$(yaml_get 'datadog.service')}.as_count()" \
        --data-urlencode "from=${FROM}" --data-urlencode "to=${NOW}" \
        "https://api.${DD_SITE}/api/v1/query" \
        -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" 2>/dev/null)
      EX_STATUS=$(echo "$EX_RESULT" | jq -r '.status // empty')
      if [[ "$EX_STATUS" == "ok" ]]; then
        check PASS "Datadog: ${METRIC} (status: ok)"
      else
        check FAIL "Datadog: ${METRIC} query failed (status: ${EX_STATUS})"
      fi
    done
  fi
else
  check FAIL "Datadog API validation skipped — DD_API_KEY or DD_APP_KEY missing"
fi

# ── Final result ────────────────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────"
echo ""
echo "  Total — PASS: ${PASS} | FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "  ✅ DEMO READY"
  echo "  ✅ DELIVERY CONSISTENT"
  echo "  ✅ DILIGENCE TRACKING"
  echo "  ✅ GITHUB IN SYNC"
  echo "  ✅ DATADOG IN SYNC"
else
  echo "  ❌ VALIDATION FAILED — ${FAIL} check(s) failed"
  exit 1
fi
echo ""
