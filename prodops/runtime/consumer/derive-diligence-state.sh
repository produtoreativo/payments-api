#!/usr/bin/env bash
# Derived Diligence State Consumer — reads CloudEvents from Diligence timeline;
# computes the current Diligence checkpoint for a given issue.
#
# Usage: derive-diligence-state.sh --issue <id> [--iteration-id <id>]
#
# With --iteration-id: reads from artifacts/iterations/<id>/runtime/timelines/
#                      writes to   artifacts/iterations/<id>/runtime/derived-state-diligence-<issue>.json
# Without:             reads/writes artifacts/runtime/ (legacy fallback)
#
# The Diligence timeline is at timelines/diligence-<issue>.json (canonical)
# or timelines/<issue>.json (fallback — dispatcher signals only).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"

yaml_get() {
  python3 - "$CONFIG" "$1" <<'PYEOF'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
keys = sys.argv[2].split('.')
val = data
for k in keys:
    val = val[k]
print(val)
PYEOF
}

ISSUE=""
ITERATION_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)        ISSUE="$2"; shift 2 ;;
    --iteration-id) ITERATION_ID="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ISSUE" ]] && { echo "Error: --issue required" >&2; exit 1; }

if [[ -n "$ITERATION_ID" ]]; then
  SAFE_ITER=$(echo "$ITERATION_ID" | tr '/ ' '--')
  TIMELINES_DIR="$PRODOPS_DIR/artifacts/iterations/${SAFE_ITER}/runtime/timelines"
  OUTPUT_DIR="$PRODOPS_DIR/artifacts/iterations/${SAFE_ITER}/runtime"
else
  TIMELINES_DIR="$PRODOPS_DIR/artifacts/runtime/timelines"
  OUTPUT_DIR="$PRODOPS_DIR/artifacts/runtime"
fi

# Prefer the dedicated Diligence timeline; fall back to delivery timeline
DILIGENCE_TIMELINE="$TIMELINES_DIR/diligence-${ISSUE}.json"
DELIVERY_TIMELINE="$TIMELINES_DIR/${ISSUE}.json"

if [[ -f "$DILIGENCE_TIMELINE" ]]; then
  TIMELINE_FILE="$DILIGENCE_TIMELINE"
  TIMELINE_SOURCE="diligence"
elif [[ -f "$DELIVERY_TIMELINE" ]]; then
  TIMELINE_FILE="$DELIVERY_TIMELINE"
  TIMELINE_SOURCE="delivery-fallback"
else
  echo "Error: no timeline found for issue $ISSUE" >&2
  exit 1
fi

RUNTIME_VERSION=$(yaml_get "runtime-version")
FRAMEWORK_VERSION=$(yaml_get "framework-version")
SCHEMA_VERSION=$(yaml_get "schema-version")

DERIVED=$(jq \
  --arg issue             "$ISSUE" \
  --arg computed_at       "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg runtime_version   "$RUNTIME_VERSION" \
  --arg framework_version "$FRAMEWORK_VERSION" \
  --arg schema_version    "$SCHEMA_VERSION" \
  --arg timeline_source   "$TIMELINE_SOURCE" \
  '
  def ts_of(ev): ev.time // ev.data["computed-at"] // null;

  def last_of(t):
    [.[] | select(.type == t)] | if length > 0 then last | ts_of(.) else null end;

  {
    "issue":           $issue,
    "timeline-source": $timeline_source,

    "diligence-status": (
      if ([.[] | select(.type == "prodops.diligence.close.completed")] | length) > 0 then "CLOSED"
      elif ([.[] | select(.type == "prodops.diligence.promote.completed")] | length) > 0 then "PROMOTED"
      elif ([.[] | select(.type == "prodops.diligence.attach.completed")] | length) > 0 then "ATTACHED"
      elif ([.[] | select(.type == "prodops.diligence.capture.completed")] | length) > 0 then "CAPTURED"
      else "PENDING"
      end
    ),

    "last-diligence-event-type": (
      [.[] | select(.type | startswith("prodops.diligence."))] |
      if length > 0 then last.type else null end
    ),

    "capture-at":  last_of("prodops.diligence.capture.completed"),
    "attach-at":   last_of("prodops.diligence.attach.completed"),
    "promote-at":  last_of("prodops.diligence.promote.completed"),
    "close-at":    last_of("prodops.diligence.close.completed"),

    "divergences-detected": (
      [.[] | select(.type == "prodops.diligence.divergence.detected")] | length
    ),

    "repairs-completed": (
      [.[] | select(.type == "prodops.diligence.repair.completed")] | length
    ),

    "has-active-block": (
      ([.[] | select(.type == "prodops.diligence.block.declared")] | length) >
      ([.[] | select(.type == "prodops.diligence.block.resolved")] | length)
    ),

    "runtime-version":   $runtime_version,
    "framework-version": $framework_version,
    "schema-version":    $schema_version,
    "computed-at":       $computed_at
  }
  ' "$TIMELINE_FILE")

mkdir -p "$OUTPUT_DIR"
echo "$DERIVED" > "$OUTPUT_DIR/derived-state-diligence-${ISSUE}.json"
echo "$DERIVED"
