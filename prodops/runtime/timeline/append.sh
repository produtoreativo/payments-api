#!/usr/bin/env bash
# Timeline — validates and appends a CloudEvent to the issue's timeline (append-only)
# Usage: append.sh --issue <id> --event-json <json> --iteration-id <id>
#
# Routing (iteration-scoped):
#   Issue events  → artifacts/iterations/<iteration-id>/runtime/timelines/<issue>.json
#   Plan events   → artifacts/iterations/<iteration-id>/runtime/timelines/plan-<iteration-id>.json
#
# Falls back to artifacts/runtime/timelines/<issue>.json when --iteration-id is not provided
# (backward compat for standalone tool invocations outside an iteration context).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# Resolve iteration-id from arg or event JSON
if [[ -z "$ITERATION_ID" ]]; then
  ITERATION_ID=$(echo "$EVENT_JSON" | jq -r '.data["iteration-id"] // empty' 2>/dev/null || true)
fi

# Resolve TIMELINES_DIR: iteration-scoped or legacy fallback
if [[ -n "$ITERATION_ID" ]]; then
  SAFE_ITER=$(echo "$ITERATION_ID" | tr '/ ' '--')
  TIMELINES_DIR="$PRODOPS_DIR/artifacts/iterations/${SAFE_ITER}/runtime/timelines"
else
  TIMELINES_DIR="$PRODOPS_DIR/artifacts/runtime/timelines"
fi

mkdir -p "$TIMELINES_DIR"

# Route plan-level events (work-item-id null/empty) to plan timeline.
# Issue-level events route to timelines/<issue>.json.
if [[ -z "$ISSUE" || "$ISSUE" == "null" ]]; then
  [[ -z "$ITERATION_ID" ]] && { echo "Error: plan-level event requires --iteration-id or data.iteration-id" >&2; exit 1; }
  TIMELINE_FILE="$TIMELINES_DIR/plan-${SAFE_ITER}.json"
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
