#!/usr/bin/env bash
# test-framework-ci.sh — validates CI workflow YAML structure for DS-56
# Usage: ./prodops/scripts/test-framework-ci.sh
# Exit 0 if all tests pass, exit 1 if any fail.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NOTIFY_WF="$REPO_ROOT/prodops/scripts/ci/notify-consumers.yml"
SYNC_WF="$REPO_ROOT/prodops/scripts/ci/sync-prodops.yml"
CONSUMERS_YAML="$REPO_ROOT/prodops/exec/consumers.yaml"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "PASS  $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $name"
    FAIL=$((FAIL + 1))
  fi
}

# ── File existence ────────────────────────────────────────────────────────────

[ -f "$NOTIFY_WF" ] && r="ok" || r="fail"
run_test "notify-consumers.yml exists" "$r"

[ -f "$SYNC_WF" ] && r="ok" || r="fail"
run_test "sync-prodops.yml exists" "$r"

[ -f "$CONSUMERS_YAML" ] && r="ok" || r="fail"
run_test "consumers.yaml exists" "$r"

# ── notify-consumers.yml structure ───────────────────────────────────────────

grep -q "tags:" "$NOTIFY_WF" 2>/dev/null && \
  grep -q "v\*" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml triggers on push with tags v*" "$r"

grep -q "consumers.yaml" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml reads consumers.yaml" "$r"

grep -q "workflow_dispatch" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml dispatches workflow_dispatch" "$r"

# Error handling: look for error accumulation pattern (exit code tracking or failed_repos)
grep -qE "(failed_repos|FAILED|error.*continue|continue.*error|exit_code)" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml accumulates errors without blocking" "$r"

# Partial failure: exits non-zero after processing all consumers
grep -qE "(exit 1|exit_code.*1|\\\$\\{#failed|failed_repos.*gt|failed_count)" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml exits with failure on partial failure" "$r"

# ── sync-prodops.yml structure ────────────────────────────────────────────────

grep -q "workflow_dispatch:" "$SYNC_WF" 2>/dev/null && r="ok" || r="fail"
run_test "sync-prodops.yml has workflow_dispatch trigger" "$r"

grep -q "framework_version" "$SYNC_WF" 2>/dev/null && r="ok" || r="fail"
run_test "sync-prodops.yml has framework_version input" "$r"

grep -q "sync-from-framework.sh" "$SYNC_WF" 2>/dev/null && r="ok" || r="fail"
run_test "sync-prodops.yml calls sync-from-framework.sh" "$r"

grep -qE "(gh pr create|pull.request|pull_request)" "$SYNC_WF" 2>/dev/null && r="ok" || r="fail"
run_test "sync-prodops.yml opens a PR" "$r"

# ── consumers.yaml content ────────────────────────────────────────────────────

grep -q "consumers:" "$CONSUMERS_YAML" 2>/dev/null && r="ok" || r="fail"
run_test "consumers.yaml has consumers list" "$r"

grep -q "repo:" "$CONSUMERS_YAML" 2>/dev/null && r="ok" || r="fail"
run_test "consumers.yaml has at least one consumer entry" "$r"

# ── Error isolation: notify-consumers.yml continues after one failure ─────────

# Must NOT use steps that would abort on single failure without continue-on-error or equivalent
grep -qE "(continue-on-error|failed_repos|FAILED_REPOS|error_count|has_error)" "$NOTIFY_WF" 2>/dev/null && r="ok" || r="fail"
run_test "notify-consumers.yml uses error isolation pattern" "$r"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
