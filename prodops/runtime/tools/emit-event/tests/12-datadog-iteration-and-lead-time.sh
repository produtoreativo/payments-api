#!/usr/bin/env bash
# Test 12: emit-event forwards the iteration to Datadog and reports lead time on Promote.Completed
#
# BDD (DS-57): "cada evento aparece com tag iteration:<iteration-id>"
#   Without the iteration tag, metrics land in "iteration:N/A" and dashboards filtered by iteration
#   show nothing. Lead time (runtime.delivery.lead_time_days) must be sent once per Work Item, on
#   Promote.Completed — also when the timeline has no Bootstrap.Started (events emitted through a
#   fast path), which used to skip the metric silently (tracking issue #127).
#
# Uses a PATH-injected curl stub that records every POST body (no network) and GITHUB_SYNC_DRY_RUN=1.
#   A. every runtime.event.received metric carries iteration:<id> and issue:<id>
#   B. Promote.Completed also sends runtime.delivery.lead_time_days with a numeric value >= 0
#   C. events other than Promote.Completed do NOT send lead time
#   D. lead time is still sent when the timeline has no Bootstrap.Started
# Cleans up every artifact it creates.

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PRODOPS_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
PLAYER="${PLAYER:-claude}"
RAND=$(uuidgen | tr -d '-' | cut -c1-8 | tr 'A-Z' 'a-z')
ISSUE="t12$RAND"
ITERATION="v0.0.0-test12-$RAND"

MOCK_BIN=$(mktemp -d); CAPTURE=$(mktemp)
cleanup() {
  rm -rf "$MOCK_BIN" "$CAPTURE"
  rm -f "$PRODOPS_DIR/artifacts/runtime/timelines/$ISSUE.json" "$PRODOPS_DIR/artifacts/runtime/derived-state-$ISSUE.json" 2>/dev/null
  rm -rf "$PRODOPS_DIR/artifacts/iterations/$ITERATION" 2>/dev/null
  find "$PRODOPS_DIR/artifacts" -name "*$ISSUE*" -newer "$MOCK_BIN" 2>/dev/null | xargs rm -rf 2>/dev/null
}
trap cleanup EXIT

# curl stub: append each -d payload as one line and answer 202
cat > "$MOCK_BIN/curl" <<STUB
#!/usr/bin/env bash
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -d) printf '%s\n' "\$(printf '%s' "\$2" | tr -d '\n')" >> "$CAPTURE"; shift 2 ;;
    *) shift ;;
  esac
done
echo "202"
STUB
chmod +x "$MOCK_BIN/curl"

emit_event() { # <event> [correlation-id]
  jq -n --arg event "$1" --arg w "$ISSUE" --arg it "$ITERATION" --arg c "${2:-$(uuidgen | tr 'A-Z' 'a-z')}" \
        --arg e "$(uuidgen | tr 'A-Z' 'a-z')" --arg p "$PLAYER" \
    '{"event":$event,"work-item-id":$w,"iteration-id":$it,"correlation-id":$c,"execution-id":$e,
      "actor":{"player":$p,"agent":"test-agent-12"},"payload":{}}' \
  | PATH="$MOCK_BIN:$PATH" DD_API_KEY="dummy-key-12" GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" 2>/dev/null
}

CORR=$(uuidgen | tr 'A-Z' 'a-z')
set +e
emit_event "Delivery.Bootstrap.Started" "$CORR" >/dev/null; RC1=$?
sleep 1
: > "$CAPTURE"                                   # C: this event must not send lead time
emit_event "Delivery.Hack.Started" "$CORR" >/dev/null; RC2=$?
HACK_LINES=$(grep -c "lead_time_days" "$CAPTURE")
sleep 1
: > "$CAPTURE"
OUT=$(emit_event "Delivery.Promote.Completed" "$CORR"); RC3=$?
set -e

[[ $RC1 -eq 0 && $RC2 -eq 0 && $RC3 -eq 0 ]] || { echo "FAIL: emit-event exited $RC1/$RC2/$RC3"; echo "$OUT"; exit 1; }
[[ "$(echo "$OUT" | jq -r '."datadog-sync"')" == "success" ]] || { echo "FAIL: datadog-sync != success"; echo "$OUT"; exit 1; }

# C
[[ "$HACK_LINES" == "0" ]] || { echo "FAIL C: lead time sent for an event that is not Promote.Completed"; exit 1; }

# A
EVENT_PAYLOAD=$(grep '"runtime.event.received"' "$CAPTURE" | head -1)
[[ -n "$EVENT_PAYLOAD" ]] || { echo "FAIL A: runtime.event.received was not sent"; cat "$CAPTURE"; exit 1; }
echo "$EVENT_PAYLOAD" | jq -e --arg t "iteration:$ITERATION" '.series[0].tags | index($t)' >/dev/null \
  || { echo "FAIL A: tag iteration:$ITERATION missing; tags=$(echo "$EVENT_PAYLOAD" | jq -c '.series[0].tags')"; exit 1; }
echo "$EVENT_PAYLOAD" | jq -e --arg t "issue:$ISSUE" '.series[0].tags | index($t)' >/dev/null \
  || { echo "FAIL A: tag issue:$ISSUE missing"; exit 1; }

# D — a Work Item whose timeline has no Bootstrap.Started
ISSUE_D="${ISSUE}d"
: > "$CAPTURE"
set +e
jq -n --arg w "$ISSUE_D" --arg it "$ITERATION" --arg c "$(uuidgen | tr 'A-Z' 'a-z')" --arg e "$(uuidgen | tr 'A-Z' 'a-z')" \
  '{"event":"Delivery.Hack.Started","work-item-id":$w,"iteration-id":$it,"correlation-id":$c,"execution-id":$e,"actor":{"player":"claude","agent":"test-agent-12"},"payload":{}}' \
  | PATH="$MOCK_BIN:$PATH" DD_API_KEY="dummy-key-12" GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" >/dev/null 2>&1
sleep 1
: > "$CAPTURE"
jq -n --arg w "$ISSUE_D" --arg it "$ITERATION" --arg c "$(uuidgen | tr 'A-Z' 'a-z')" --arg e "$(uuidgen | tr 'A-Z' 'a-z')" \
  '{"event":"Delivery.Promote.Completed","work-item-id":$w,"iteration-id":$it,"correlation-id":$c,"execution-id":$e,"actor":{"player":"claude","agent":"test-agent-12"},"payload":{}}' \
  | PATH="$MOCK_BIN:$PATH" DD_API_KEY="dummy-key-12" GITHUB_SYNC_DRY_RUN=1 bash "$TOOL" >/dev/null 2>&1
set -e
grep -q '"runtime.delivery.lead_time_days"' "$CAPTURE" \
  || { echo "FAIL D: lead time not sent when the timeline has no Bootstrap.Started"; cat "$CAPTURE"; exit 1; }

# B
LEAD_PAYLOAD=$(grep '"runtime.delivery.lead_time_days"' "$CAPTURE" | head -1)
[[ -n "$LEAD_PAYLOAD" ]] || { echo "FAIL B: lead time metric not sent on Promote.Completed"; cat "$CAPTURE"; exit 1; }
echo "$LEAD_PAYLOAD" | jq -e '.series[0].points[0].value | (type == "number") and (. >= 0)' >/dev/null \
  || { echo "FAIL B: lead time value is not a number >= 0: $(echo "$LEAD_PAYLOAD" | jq -c '.series[0].points')"; exit 1; }
exit 0
