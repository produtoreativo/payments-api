#!/usr/bin/env bash
# Test 13: emit-event says WHY a consumer failed (field "consumer-errors")
#
# BDD (DS-57): "emit-event retorna github-sync success ... " — a failure must be diagnosable.
#   Before, GitHub sync output was discarded (>/dev/null 2>&1) and the caller only saw
#   "github-sync":"error" with no reason (e.g. token without the 'project' scope).
#
# The "errors" field keeps its contract (test 05: empty when only a consumer fails); the reason
# goes to "consumer-errors". Uses PATH-injected curl and gh stubs (no network).
#   A. GitHub mutation rejected → github-sync=error, consumer-errors mentions the reason and the scope hint
#   B. Datadog rejects the key  → datadog-sync=error, consumer-errors mentions datadog-sync
#   C. everything succeeds      → both success, consumer-errors empty

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PRODOPS_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
RAND=$(uuidgen | tr -d '-' | cut -c1-8 | tr 'A-Z' 'a-z')
ISSUE="t13$RAND"; ITERATION="v0.0.0-test13-$RAND"
MOCK_BIN=$(mktemp -d); SYNC_LOG=$(mktemp)
cleanup() {
  rm -rf "$MOCK_BIN"; rm -f "$SYNC_LOG"
  rm -f "$PRODOPS_DIR/artifacts/runtime/timelines/$ISSUE.json" "$PRODOPS_DIR/artifacts/runtime/derived-state-$ISSUE.json" 2>/dev/null
  rm -rf "$PRODOPS_DIR/artifacts/iterations/$ITERATION" 2>/dev/null
}
trap cleanup EXIT

# curl: 403 when the key is "bad-key", else 202
cat > "$MOCK_BIN/curl" <<'STUB'
#!/usr/bin/env bash
key=""; prev=""
for a in "$@"; do [[ "$prev" == "-H" && "$a" == DD-API-KEY:* ]] && key="${a#DD-API-KEY: }"; prev="$a"; done
[[ "$key" == "bad-key" ]] && echo "403" || echo "202"
STUB
# gh: project lookup / add item / fields succeed; field mutation fails when MOCK_FAIL_UPDATE=1
cat > "$MOCK_BIN/gh" <<'STUB'
#!/usr/bin/env bash
all="$*"
if [[ "$1" == "api" && "$2" == "graphql" ]]; then
  if grep -q "organization(login" <<<"$all"; then echo '{"data":{"organization":{"projectV2":{"id":"PVT_1"}}}}'
  elif grep -q "addProjectV2ItemById" <<<"$all"; then echo '{"data":{"addProjectV2ItemById":{"item":{"id":"ITEM_1"}}}}'
  elif grep -q "fields(first" <<<"$all"; then
    echo '{"data":{"node":{"fields":{"nodes":[{"id":"F_STATE","name":"oem-state","options":[{"id":"O1","name":"HACKING"},{"id":"O2","name":"BOOTSTRAPPING"},{"id":"O3","name":"SYNCING"}]},{"id":"F_LAST","name":"oem-last-event"},{"id":"F_CYCLE","name":"Cycle","options":[{"id":"C1","name":"CI Sync"}]}]}}}}'
  elif grep -q "updateProjectV2ItemFieldValue" <<<"$all"; then
    if [[ "${MOCK_FAIL_UPDATE:-0}" == "1" ]]; then
      echo '{"errors":[{"type":"INSUFFICIENT_SCOPES","message":"Your token has not been granted the required scopes"}]}'; exit 1; fi
    echo '{"data":{"updateProjectV2ItemFieldValue":{"projectV2Item":{"id":"ITEM_1"}}}}'
  else echo '{}'; fi
  exit 0
fi
if [[ "$1" == "api" ]]; then
  grep -q "node_id" <<<"$all" && { echo "ISSUE_NODE_1"; exit 0; }
  grep -q "\.state" <<<"$all" && { echo "open"; exit 0; }
fi
exit 0
STUB
chmod +x "$MOCK_BIN/curl" "$MOCK_BIN/gh"

run() { # <ddkey> <fail-update> <event>
  jq -n --arg w "$ISSUE" --arg it "$ITERATION" --arg ev "$3" --arg c "$(uuidgen | tr 'A-Z' 'a-z')" --arg e "$(uuidgen | tr 'A-Z' 'a-z')" \
    '{"event":$ev,"work-item-id":$w,"iteration-id":$it,"correlation-id":$c,"execution-id":$e,"actor":{"player":"claude","agent":"test-agent-13"},"payload":{}}' \
  | PATH="$MOCK_BIN:$PATH" DD_API_KEY="$1" MOCK_FAIL_UPDATE="$2" GITHUB_SYNC_DRY_RUN=0 GITHUB_SYNC_LOG_FILE="$SYNC_LOG" bash "$TOOL" 2>/dev/null
}

# A: GitHub rejected
OUT=$(run "good-key" 1 "Delivery.Hack.Started")
[[ "$(echo "$OUT" | jq -r '."github-sync"')" == "error" ]] || { echo "FAIL A: github-sync should be error"; echo "$OUT"; exit 1; }
echo "$OUT" | jq -e '."consumer-errors" | map(select(startswith("github-sync:"))) | length == 1' >/dev/null \
  || { echo "FAIL A: consumer-errors has no github-sync reason"; echo "$OUT" | jq -c '."consumer-errors"'; exit 1; }
echo "$OUT" | jq -r '."consumer-errors"[]' | grep -qi "scope" \
  || { echo "FAIL A: reason/hint about the missing scope not surfaced"; echo "$OUT" | jq -c '."consumer-errors"'; exit 1; }
[[ "$(echo "$OUT" | jq -r '.errors | length')" == "0" ]] || { echo "FAIL A: 'errors' must stay empty (contract of test 05)"; exit 1; }

# B: Datadog rejected
OUT=$(run "bad-key" 0 "Delivery.Hack.Completed")
[[ "$(echo "$OUT" | jq -r '."datadog-sync"')" == "error" ]] || { echo "FAIL B: datadog-sync should be error"; echo "$OUT"; exit 1; }
echo "$OUT" | jq -e '."consumer-errors" | map(select(startswith("datadog-sync:"))) | length == 1' >/dev/null \
  || { echo "FAIL B: consumer-errors has no datadog-sync reason"; echo "$OUT" | jq -c '."consumer-errors"'; exit 1; }

# C: all good
OUT=$(run "good-key" 0 "Delivery.Sync.Started")
[[ "$(echo "$OUT" | jq -r '."github-sync"')/$(echo "$OUT" | jq -r '."datadog-sync"')" == "success/success" ]] \
  || { echo "FAIL C: expected success/success"; echo "$OUT"; exit 1; }
[[ "$(echo "$OUT" | jq -r '."consumer-errors" | length')" == "0" ]] || { echo "FAIL C: consumer-errors should be empty"; echo "$OUT" | jq -c '."consumer-errors"'; exit 1; }
exit 0
