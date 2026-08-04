#!/usr/bin/env bash
# Test runner for prodops_emit_event
# Usage: run-all.sh [--player <claude|codex|copilot>]

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$TESTS_DIR/../scripts/emit-event"

PLAYER="${PLAYER:-claude}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --player) PLAYER="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Shared correlation-id for tests 01 and 06
export TEST_CORR_ID
TEST_CORR_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
export PLAYER
export TOOL

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

PASSED=0
FAILED=0
RESULTS=()

run_test() {
  local name="$1"
  local file="$2"
  if bash "$file" 2>/dev/null; then
    printf "${GREEN}✓ PASS${RESET}: %s\n" "$name"
    ((PASSED++))
    RESULTS+=("PASS: $name")
  else
    printf "${RED}✗ FAIL${RESET}: %s\n" "$name"
    ((FAILED++))
    RESULTS+=("FAIL: $name")
  fi
}

echo ""
echo "prodops_emit_event — Test Suite"
echo "player=$PLAYER  shared-corr-id=$TEST_CORR_ID"
echo "────────────────────────────────────────────────"

run_test "01 valid-input (full pipeline)"       "$TESTS_DIR/01-valid-input.sh"
run_test "02 missing-required-fields"           "$TESTS_DIR/02-missing-required.sh"
run_test "03 unknown-event"                     "$TESTS_DIR/03-unknown-event.sh"
run_test "04 catalog-field-rejection"           "$TESTS_DIR/04-catalog-field-rejection.sh"
run_test "05 partial-runtime-failure (datadog)" "$TESTS_DIR/05-partial-runtime-failure.sh"
run_test "06 idempotency (same correlation-id)"         "$TESTS_DIR/06-idempotency.sh"
run_test "07 plan-level null work-item-id → iteration-id" "$TESTS_DIR/07-plan-level-null-work-item-id.sh"
run_test "08 bootstrap-intermediate-events (pipeline completeness)" "$TESTS_DIR/08-bootstrap-intermediate-events.sh"
run_test "09 finish-started → FINISHING derived-state"              "$TESTS_DIR/09-finish-started-finishing-state.sh"
run_test "10 send-sh iteration tag in Datadog payload"              "$TESTS_DIR/10-send-sh-iteration-tag.sh"

echo "────────────────────────────────────────────────"
echo "Results: $PASSED passed, $FAILED failed"

if [[ $FAILED -gt 0 ]]; then
  echo "FAILED TESTS:"
  for r in "${RESULTS[@]}"; do
    [[ "$r" == FAIL:* ]] && echo "  $r"
  done
  exit 1
fi

echo "All tests passed."
