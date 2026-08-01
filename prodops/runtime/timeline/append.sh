#!/usr/bin/env bash
# Timeline — validates and appends a CloudEvent to the issue's timeline (append-only)
# Usage: append.sh --issue <id> --event-json <json>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMELINES_DIR="$PRODOPS_DIR/artifacts/runtime/timelines"

ISSUE=""
EVENT_JSON=""
ITERATION_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)        ISSUE="$2"; shift 2 ;;
    --event-json)   EVENT_JSON="$2"; shift 2 ;;
    --iteration-id) ITERATION_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$EVENT_JSON" ]] && { echo "Error: --event-json required" >&2; exit 1; }

# Reject invalid CloudEvents — nothing invalid enters the timeline
if ! bash "$RUNTIME_DIR/scripts/validate-event.sh" --event-json "$EVENT_JSON" >&2; then
  echo "Error: invalid CloudEvent — not appended to timeline" >&2
  exit 1
fi

mkdir -p "$TIMELINES_DIR"

# Route plan-level events (work-item-id null/empty) to plan timeline.
# Issue-level events route to timelines/<issue>.json as before.
if [[ -z "$ISSUE" || "$ISSUE" == "null" ]]; then
  # Derive iteration-id from --iteration-id arg or from event JSON data field
  if [[ -z "$ITERATION_ID" ]]; then
    ITERATION_ID=$(echo "$EVENT_JSON" | jq -r '.data["iteration-id"] // empty' 2>/dev/null || true)
  fi
  [[ -z "$ITERATION_ID" ]] && { echo "Error: plan-level event requires --iteration-id or data.iteration-id" >&2; exit 1; }
  # Sanitize iteration-id for use as filename (replace / and spaces with -)
  SAFE_ID=$(echo "$ITERATION_ID" | tr '/ ' '--')
  TIMELINE_FILE="$TIMELINES_DIR/plan-${SAFE_ID}.json"
else
  TIMELINE_FILE="$TIMELINES_DIR/${ISSUE}.json"
fi

if [[ -f "$TIMELINE_FILE" ]]; then
  jq --argjson new "$EVENT_JSON" '. + [$new]' "$TIMELINE_FILE" > "${TIMELINE_FILE}.tmp" \
    && mv "${TIMELINE_FILE}.tmp" "$TIMELINE_FILE"
else
  echo "[$EVENT_JSON]" | jq '.' > "$TIMELINE_FILE"
fi

echo "$TIMELINE_FILE"
