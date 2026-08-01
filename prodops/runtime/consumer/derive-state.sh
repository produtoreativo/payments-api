#!/usr/bin/env bash
# Derived State Consumer — reads CloudEvents from Timeline; last alters-state=true wins
# Usage: derive-state.sh --issue <id> [--iteration-id <id>]
#
# With --iteration-id: reads from artifacts/iterations/<id>/runtime/timelines/<issue>.json
#                      writes to   artifacts/iterations/<id>/runtime/derived-state-<issue>.json
# Without:             reads/writes artifacts/runtime/ (legacy fallback)

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
OUTPUT_FILE="$OUTPUT_DIR/derived-state.json"

TIMELINE_FILE="$TIMELINES_DIR/${ISSUE}.json"
[[ ! -f "$TIMELINE_FILE" ]] && { echo "Error: timeline not found: $TIMELINE_FILE" >&2; exit 1; }

RUNTIME_VERSION=$(yaml_get "runtime-version")
FRAMEWORK_VERSION=$(yaml_get "framework-version")
SCHEMA_VERSION=$(yaml_get "schema-version")

# All event data is in CloudEvent.data — read from there
DERIVED=$(jq \
  --arg issue             "$ISSUE" \
  --arg computed_at       "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg runtime_version   "$RUNTIME_VERSION" \
  --arg framework_version "$FRAMEWORK_VERSION" \
  --arg schema_version    "$SCHEMA_VERSION" \
  '
  ($issue) as $iss |
  ($computed_at) as $ts |

  # Restart tracking: count Restart.Completed events; collect previous correlation-ids
  ( [.[] | select(.type == "prodops.delivery.restart.completed")] ) as $restarts |
  ($restarts | length) as $restart_count |
  ( $restarts | map(.data["payload"]["previous-correlation-id"] // empty) | unique ) as $prev_corr_ids |

  [.[] | select(.data["alters-state"] == true)] |
  if length == 0 then
    {
      "issue":                       $iss,
      "state":                       "UNKNOWN",
      "last-event-type":             null,
      "runtime-correlation-id":      null,
      "restart-count":               $restart_count,
      "previous-correlation-ids":    $prev_corr_ids,
      "runtime-version":             $runtime_version,
      "framework-version":           $framework_version,
      "schema-version":              $schema_version,
      "computed-at":                 $ts
    }
  else
    last |
    {
      "issue":                       $iss,
      "state":                       .data["new-state"],
      "last-event-type":             .type,
      "runtime-correlation-id":      .data["runtime-correlation-id"],
      "restart-count":               $restart_count,
      "previous-correlation-ids":    $prev_corr_ids,
      "runtime-version":             $runtime_version,
      "framework-version":           $framework_version,
      "schema-version":              $schema_version,
      "computed-at":                 $ts
    }
  end
  ' "$TIMELINE_FILE")

mkdir -p "$OUTPUT_DIR"
echo "$DERIVED" > "$OUTPUT_DIR/derived-state-${ISSUE}.json"
echo "$DERIVED"
