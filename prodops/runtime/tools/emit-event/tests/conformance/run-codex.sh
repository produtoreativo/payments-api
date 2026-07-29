#!/usr/bin/env bash
# Conformance run — Claude player
# Produces machine-readable result for compare-results.py

set -euo pipefail

CONF_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$CONF_DIR/../../scripts/emit-event"
REPO_ROOT="$(cd "$CONF_DIR/../../../../../.." && pwd)"
OUTPUT_DIR="$CONF_DIR/results"
mkdir -p "$OUTPUT_DIR"

PLAYER="codex"
CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
EXEC=$(uuidgen | tr '[:upper:]' '[:lower:]')
WORK_ITEM="76"
ITERATION="EXP-015-I5"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[conformance/$PLAYER] $*" >&2; }

run_check() {
  local check_name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $check_name"
    echo "PASS,$check_name,$actual" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
  else
    echo "  FAIL: $check_name — expected='$expected' got='$actual'"
    echo "FAIL,$check_name,$actual,$expected" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
    FAILED=$((FAILED + 1))
  fi
}

FAILED=0
echo "player,check,result,expected" > "$OUTPUT_DIR/${PLAYER}-results.csv"

echo ""
echo "=== Conformance Suite — player=$PLAYER ==="
echo "correlation-id: $CORR"
echo ""

# ── 1. Skill discovery ────────────────────────────────────────────────────────
echo "[ Skill discovery ]"
SKILL_PATH="$REPO_ROOT/.agents/skills/prodops-emit-event/SKILL.md"
if [[ -f "$SKILL_PATH" ]]; then
  echo "  PASS: skill discovered at $SKILL_PATH"
  echo "PASS,skill-discovery,$SKILL_PATH" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
else
  echo "  FAIL: skill not found at $SKILL_PATH"
  echo "FAIL,skill-discovery,NOT_FOUND" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
  FAILED=$((FAILED + 1))
fi

# ── 2. Tool availability ──────────────────────────────────────────────────────
echo "[ Tool availability ]"
if [[ -x "$TOOL" ]]; then
  echo "  PASS: tool executable"
  echo "PASS,tool-availability,executable" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
else
  echo "  FAIL: tool not executable at $TOOL"
  echo "FAIL,tool-availability,NOT_EXECUTABLE" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
  FAILED=$((FAILED + 1))
fi

# ── 3. Invalid input rejected ─────────────────────────────────────────────────
echo "[ Invalid input rejected ]"
set +e
INVALID_OUT=$(echo '{"actor":{"player":"codex","agent":"t"}}' | bash "$TOOL" 2>/dev/null)
INVALID_EXIT=$?
set -e
INVALID_STATUS=$(echo "$INVALID_OUT" | jq -r '.status' 2>/dev/null || echo "PARSE_ERROR")
run_check "invalid-input-exit-code" "1" "$INVALID_EXIT"
run_check "invalid-input-status" "error" "$INVALID_STATUS"

# ── 4. Forbidden catalog field rejected ──────────────────────────────────────
echo "[ Catalog field rejection ]"
FORBIDDEN_INPUT=$(jq -n --arg cid "$CORR" \
  '{"event":"Delivery.Bootstrap.Started","work-item-id":"76",
    "correlation-id":$cid,"new-state":"CUSTOM",
    "actor":{"player":"codex","agent":"t"},"payload":{}}')
set +e
FORBIDDEN_OUT=$(echo "$FORBIDDEN_INPUT" | bash "$TOOL" 2>/dev/null)
FORBIDDEN_EXIT=$?
set -e
FORBIDDEN_ERR=$(echo "$FORBIDDEN_OUT" | jq -r '.errors[0]' 2>/dev/null | grep -c "forbidden" || echo 0)
run_check "catalog-field-exit" "1" "$FORBIDDEN_EXIT"
[[ "$FORBIDDEN_ERR" -gt "0" ]] && \
  { echo "  PASS: catalog-field-error-message"; echo "PASS,catalog-field-error-message,ok" >> "$OUTPUT_DIR/${PLAYER}-results.csv"; } || \
  { echo "  FAIL: catalog-field-error-message"; echo "FAIL,catalog-field-error-message,not-found" >> "$OUTPUT_DIR/${PLAYER}-results.csv"; FAILED=$((FAILED + 1)); }

# ── 5. Explicit invocation — Bootstrap.Started ───────────────────────────────
echo "[ Explicit invocation: Bootstrap.Started ]"
INPUT_S=$(jq -n \
  --arg corr "$CORR" --arg exec "$EXEC" --arg wi "$WORK_ITEM" --arg it "$ITERATION" \
  '{"event":"Delivery.Bootstrap.Started","work-item-id":$wi,"iteration-id":$it,
    "correlation-id":$corr,"execution-id":$exec,
    "actor":{"player":"codex","agent":"bootstrap-agent"},"payload":{}}')
set +e
OUT_S=$(echo "$INPUT_S" | bash "$TOOL" --evidence-file "$OUTPUT_DIR/${PLAYER}-bootstrap-started.json" 2>/dev/null)
EXIT_S=$?
set -e

STATUS_S=$(echo "$OUT_S"      | jq -r '.status')
EVENT_TYPE_S=$(echo "$OUT_S"  | jq -r '."event-type"')
DERIVED_S=$(echo "$OUT_S"     | jq -r '."derived-state"')
GH_S=$(echo "$OUT_S"          | jq -r '."github-sync"')
DD_S=$(echo "$OUT_S"          | jq -r '."datadog-sync"')

run_check "started-exit"         "0"                                     "$EXIT_S"
run_check "started-status"       "accepted"                              "$STATUS_S"
run_check "started-event-type"   "prodops.delivery.bootstrap.started"   "$EVENT_TYPE_S"
run_check "started-derived"      "BOOTSTRAPPING"                         "$DERIVED_S"
run_check "started-github"       "success"                               "$GH_S"
run_check "started-datadog"      "success"                               "$DD_S"

# ── 6. Started emitted exactly once ──────────────────────────────────────────
echo "[ Started emitted once ]"
STARTED_COUNT=$(jq --arg cid "$CORR" --arg type "prodops.delivery.bootstrap.started" \
  '[.[] | select(.data["runtime-correlation-id"] == $cid and .type == $type)] | length' \
  "$REPO_ROOT/prodops/artifacts/runtime/timelines/${WORK_ITEM}.json" 2>/dev/null || echo 0)
run_check "started-count-in-timeline" "1" "$STARTED_COUNT"

# ── 7. Idempotency (same correlation-id) ─────────────────────────────────────
echo "[ Idempotency ]"
set +e
IDEMP_OUT=$(echo "$INPUT_S" | bash "$TOOL" 2>/dev/null)
IDEMP_EXIT=$?
set -e
IDEMP_STATUS=$(echo "$IDEMP_OUT" | jq -r '.status')
run_check "idempotency-exit"   "4"       "$IDEMP_EXIT"
run_check "idempotency-status" "skipped" "$IDEMP_STATUS"

# ── 8. Bootstrap.Completed ───────────────────────────────────────────────────
echo "[ Bootstrap.Completed ]"
EXEC_C=$(uuidgen | tr '[:upper:]' '[:lower:]')
INPUT_C=$(jq -n \
  --arg corr "$CORR" --arg exec "$EXEC_C" --arg wi "$WORK_ITEM" --arg it "$ITERATION" \
  '{"event":"Delivery.Bootstrap.Completed","work-item-id":$wi,"iteration-id":$it,
    "correlation-id":$corr,"execution-id":$exec,
    "actor":{"player":"codex","agent":"bootstrap-agent"},"payload":{}}')
set +e
OUT_C=$(echo "$INPUT_C" | bash "$TOOL" --evidence-file "$OUTPUT_DIR/${PLAYER}-bootstrap-completed.json" 2>/dev/null)
EXIT_C=$?
set -e

STATUS_C=$(echo "$OUT_C"     | jq -r '.status')
EVENT_TYPE_C=$(echo "$OUT_C" | jq -r '."event-type"')
DERIVED_C=$(echo "$OUT_C"    | jq -r '."derived-state"')
GH_C=$(echo "$OUT_C"         | jq -r '."github-sync"')
DD_C=$(echo "$OUT_C"         | jq -r '."datadog-sync"')

run_check "completed-exit"        "0"                                       "$EXIT_C"
run_check "completed-status"      "accepted"                                "$STATUS_C"
run_check "completed-event-type"  "prodops.delivery.bootstrap.completed"   "$EVENT_TYPE_C"
run_check "completed-github"      "success"                                 "$GH_C"
run_check "completed-datadog"     "success"                                 "$DD_C"

# ── 9. Same correlation-id in both timeline entries ──────────────────────────
echo "[ Correlation ID consistency ]"
BOTH_COUNT=$(jq --arg cid "$CORR" \
  '[.[] | select(.data["runtime-correlation-id"] == $cid)] | length' \
  "$REPO_ROOT/prodops/artifacts/runtime/timelines/${WORK_ITEM}.json" 2>/dev/null || echo 0)
run_check "both-events-same-corr" "2" "$BOTH_COUNT"

# ── 10. Secrets sanitized ────────────────────────────────────────────────────
echo "[ Secrets sanitized ]"
if echo "$OUT_S$OUT_C" | grep -qE "DD_API_KEY|gh auth|GH_TOKEN" 2>/dev/null; then
  echo "  FAIL: secrets-sanitized"
  echo "FAIL,secrets-sanitized,found" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
  FAILED=$((FAILED + 1))
else
  echo "  PASS: secrets-sanitized"
  echo "PASS,secrets-sanitized,ok" >> "$OUTPUT_DIR/${PLAYER}-results.csv"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL=$(grep -c "^" "$OUTPUT_DIR/${PLAYER}-results.csv" 2>/dev/null || echo 1)
TOTAL=$((TOTAL - 1))
PASSED=$((TOTAL - FAILED))
echo ""
echo "────────────────────────────────────────────────"
echo "Results: $PASSED/$TOTAL passed  ($FAILED failed)"
echo "CSV: $OUTPUT_DIR/${PLAYER}-results.csv"

[[ "$FAILED" -eq 0 ]] && exit 0 || exit 1
