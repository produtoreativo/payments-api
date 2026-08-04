#!/usr/bin/env bash
# Test 10: send.sh includes iteration:<id> tag when --iteration-id is provided
#
# BDD: Scenario "Todos os eventos de Bootstrap chegam ao Datadog"
#   Then cada evento aparece com tag "iteration:<iteration-id>"
#
# Uses a PATH-injected curl stub that captures the POST body to a temp file.
# Verifies the iteration tag is present in the series[0].tags array.

SEND_SH="$(cd "$(dirname "$0")/../../../.." && pwd)/runtime/datadog/send.sh"

CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')
ITERATION="v0.12.0"

# Temp workspace
MOCK_BIN=$(mktemp -d)
CAPTURED_PAYLOAD=$(mktemp)

# Write curl stub using printf to avoid heredoc quoting issues
printf '#!/usr/bin/env bash\n' > "$MOCK_BIN/curl"
printf '# Minimal curl stub: capture -d arg and return 202\n' >> "$MOCK_BIN/curl"
printf 'PAYLOAD_FILE="%s"\n' "$CAPTURED_PAYLOAD" >> "$MOCK_BIN/curl"
printf 'while [[ $# -gt 0 ]]; do\n' >> "$MOCK_BIN/curl"
printf '  case "$1" in\n' >> "$MOCK_BIN/curl"
printf '    -d) printf "%%s" "$2" > "$PAYLOAD_FILE"; shift 2 ;;\n' >> "$MOCK_BIN/curl"
printf '    *) shift ;;\n' >> "$MOCK_BIN/curl"
printf '  esac\n' >> "$MOCK_BIN/curl"
printf 'done\n' >> "$MOCK_BIN/curl"
printf 'echo "202"\n' >> "$MOCK_BIN/curl"
chmod +x "$MOCK_BIN/curl"

set +e
PATH="$MOCK_BIN:$PATH" DD_API_KEY="test-key-10" \
  bash "$SEND_SH" \
    --issue          "146" \
    --event          "prodops.delivery.bootstrap.dependencies.installed" \
    --state          "BOOTSTRAPPING" \
    --correlation-id "$CORR" \
    --iteration-id   "$ITERATION" \
  >/dev/null 2>&1
EXIT_CODE=$?
set -e

rm -rf "$MOCK_BIN"

[[ "$EXIT_CODE" == "0" ]] || { echo "FAIL: send.sh exited $EXIT_CODE (expected 0)"; rm -f "$CAPTURED_PAYLOAD"; exit 1; }

[[ -s "$CAPTURED_PAYLOAD" ]] || { echo "FAIL: curl was not invoked — payload file empty or missing"; rm -f "$CAPTURED_PAYLOAD"; exit 1; }

ITERATION_TAG=$(jq -r '.series[0].tags[] | select(startswith("iteration:"))' "$CAPTURED_PAYLOAD" 2>/dev/null)
ISSUE_TAG=$(jq -r '.series[0].tags[] | select(startswith("issue:"))' "$CAPTURED_PAYLOAD" 2>/dev/null)

rm -f "$CAPTURED_PAYLOAD"

[[ "$ITERATION_TAG" == "iteration:${ITERATION}" ]] \
  || { echo "FAIL: iteration tag not found or wrong; got='$ITERATION_TAG' expected='iteration:${ITERATION}'"; exit 1; }

[[ "$ISSUE_TAG" == "issue:146" ]] \
  || { echo "FAIL: issue tag wrong; got='$ISSUE_TAG' expected='issue:146'"; exit 1; }
