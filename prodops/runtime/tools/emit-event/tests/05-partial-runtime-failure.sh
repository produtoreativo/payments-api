#!/usr/bin/env bash
# Test 05: Datadog failure — must exit 0 with datadog-sync:error, github-sync:success
#
# Uses DD_API_KEY=invalid (non-empty, so no .env fallback) to force a 403 from Datadog.
# send.sh exits 1 on non-202 → tool catches it as non-fatal → datadog-sync: error.

TOOL="${TOOL:-$(cd "$(dirname "$0")/.." && pwd)/scripts/emit-event}"
PLAYER="${PLAYER:-claude}"

CORR=$(uuidgen | tr '[:upper:]' '[:lower:]')

INPUT=$(jq -n \
  --arg player "$PLAYER" \
  --arg corr   "$CORR" \
  '{"event":"Delivery.Bootstrap.Started","work-item-id":"76",
    "correlation-id":$corr,
    "actor":{"player":$player,"agent":"test-agent"},"payload":{}}')

set +e
OUTPUT=$(echo "$INPUT" | DD_API_KEY="invalid-key-for-test-05" bash "$TOOL" 2>/dev/null)
EXIT_CODE=$?
set -e

STATUS=$(echo "$OUTPUT" | jq -r '.status')
DD=$(echo "$OUTPUT"     | jq -r '."datadog-sync"')
GH=$(echo "$OUTPUT"     | jq -r '."github-sync"')
ERRORS=$(echo "$OUTPUT" | jq -r '.errors | length')

[[ "$EXIT_CODE" == "0"       ]] || { echo "FAIL exit=$EXIT_CODE (expected 0 — datadog failure is non-fatal)"; exit 1; }
[[ "$STATUS"    == "accepted" ]] || { echo "FAIL status=$STATUS (expected accepted)"; exit 1; }
[[ "$DD"        == "error"    ]] || { echo "FAIL datadog-sync=$DD (expected error — key is invalid)"; exit 1; }
[[ "$GH"        == "success"  ]] || { echo "FAIL github-sync=$GH (expected success)"; exit 1; }
[[ "$ERRORS"    == "0"        ]] || { echo "FAIL errors array not empty"; exit 1; }
