#!/usr/bin/env bash
# Test 11: github/sync.sh never reports success when an update did not apply
#
# BDD (DS-57): "emit-event retorna github-sync success para eventos de phase" —
#   success must mean the Project really changed. Before this fix the mutations had
#   their output discarded and the script logged "updated" and exited 0 even when the
#   GitHub API rejected them (e.g. token without the 'project' scope).
#
# Uses a PATH-injected `gh` stub (no network). Scenarios:
#   A. every call succeeds                                  → exit 0, "oem-state updated"
#   B. the field mutation is rejected (INSUFFICIENT_SCOPES) → exit non-zero, no "updated"
#   C. the target state is not an option of oem-state       → exit non-zero, option reported
#   D. the missing-scope hint is shown to the user

SYNC_SH="$(cd "$(dirname "$0")/../../../.." && pwd)/runtime/github/sync.sh"

MOCK_BIN=$(mktemp -d)
LOG=$(mktemp)
trap 'rm -rf "$MOCK_BIN" "$LOG"' EXIT

cat > "$MOCK_BIN/gh" <<'STUB'
#!/usr/bin/env bash
# Minimal gh stub driven by env vars: MOCK_FAIL_UPDATE=1, MOCK_NO_PENDING=1, MOCK_ISSUE_STATE
all="$*"
if [[ "$1" == "api" && "$2" == "graphql" ]]; then
  if grep -q "organization(login" <<<"$all"; then
    echo '{"data":{"organization":{"projectV2":{"id":"PVT_1"}}}}'
  elif grep -q "addProjectV2ItemById" <<<"$all"; then
    echo '{"data":{"addProjectV2ItemById":{"item":{"id":"ITEM_1"}}}}'
  elif grep -q "fields(first" <<<"$all"; then
    pending='{"id":"O0","name":"PENDING"},'
    [[ "${MOCK_NO_PENDING:-0}" == "1" ]] && pending=""
    echo '{"data":{"node":{"fields":{"nodes":[
      {"id":"F_STATE","name":"oem-state","options":['"$pending"'{"id":"O1","name":"BOOTSTRAPPING"},{"id":"O2","name":"HACKING"},{"id":"O3","name":"DONE"}]},
      {"id":"F_LAST","name":"oem-last-event"},
      {"id":"F_CYCLE","name":"Cycle","options":[{"id":"C1","name":"CI Sync"},{"id":"C2","name":"CI Async"}]}]}}}}'
  elif grep -q "updateProjectV2ItemFieldValue" <<<"$all"; then
    if [[ "${MOCK_FAIL_UPDATE:-0}" == "1" ]]; then
      echo '{"errors":[{"type":"INSUFFICIENT_SCOPES","message":"Your token has not been granted the required scopes"}]}'
      exit 1
    fi
    echo '{"data":{"updateProjectV2ItemFieldValue":{"projectV2Item":{"id":"ITEM_1"}}}}'
  else
    echo '{}'
  fi
  exit 0
fi
if [[ "$1" == "api" ]]; then
  if grep -q "node_id" <<<"$all"; then echo "ISSUE_NODE_1"; exit 0; fi
  if grep -q "\.state" <<<"$all"; then echo "${MOCK_ISSUE_STATE:-open}"; exit 0; fi
fi
exit 0   # gh issue close/reopen, gh project field-create
STUB
chmod +x "$MOCK_BIN/gh"

run_sync() { # <state> [env assignments...]
  local state="$1"; shift
  env GITHUB_SYNC_DRY_RUN=0 "$@" PATH="$MOCK_BIN:$PATH" GITHUB_SYNC_LOG_FILE="$LOG" \
    bash "$SYNC_SH" --issue 173 --state "$state" --last-event "prodops.delivery.hack.started" \
    --correlation-id "t11" >"$LOG.out" 2>&1
}

# ── A: success ───────────────────────────────────────────────────────────────
: > "$LOG"
run_sync HACKING; RC=$?
[[ $RC -eq 0 ]] || { echo "FAIL A: sync.sh exited $RC on a fully successful run"; cat "$LOG.out"; exit 1; }
grep -q "oem-state updated to: HACKING" "$LOG.out" || { echo "FAIL A: success not logged"; cat "$LOG.out"; exit 1; }

# ── B: mutation rejected ─────────────────────────────────────────────────────
: > "$LOG"
run_sync HACKING MOCK_FAIL_UPDATE=1; RC=$?
[[ $RC -ne 0 ]] || { echo "FAIL B: sync.sh exited 0 although the Project update was rejected"; cat "$LOG.out"; exit 1; }
if grep -q "oem-state updated to" "$LOG.out"; then
  echo "FAIL B: sync.sh logged 'oem-state updated' for a rejected mutation"; cat "$LOG.out"; exit 1
fi
grep -q "INSUFFICIENT_SCOPES\|required scopes" "$LOG.out" \
  || { echo "FAIL B: real error reason not surfaced"; cat "$LOG.out"; exit 1; }

# ── D: missing-scope hint ────────────────────────────────────────────────────
grep -q "gh auth refresh" "$LOG.out" || { echo "FAIL D: no hint on how to get the 'project' scope"; cat "$LOG.out"; exit 1; }

# ── C: state is not an option of oem-state ───────────────────────────────────
: > "$LOG"
run_sync PENDING MOCK_NO_PENDING=1; RC=$?
[[ $RC -ne 0 ]] || { echo "FAIL C: sync.sh exited 0 although option PENDING does not exist in oem-state"; cat "$LOG.out"; exit 1; }
grep -q "option 'PENDING' not found" "$LOG.out" || { echo "FAIL C: missing option not reported"; cat "$LOG.out"; exit 1; }

rm -f "$LOG.out"
exit 0
