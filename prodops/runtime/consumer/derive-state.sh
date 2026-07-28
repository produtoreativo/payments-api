#!/usr/bin/env bash
# Derived State Consumer — reads CloudEvents from Timeline; last alters-state=true wins
# Usage: derive-state.sh --issue <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODOPS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$RUNTIME_DIR/runtime.yaml"
TIMELINES_DIR="$PRODOPS_DIR/artifacts/runtime/timelines"
OUTPUT_FILE="$PRODOPS_DIR/artifacts/runtime/derived-state.json"

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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ISSUE" ]] && { echo "Error: --issue required" >&2; exit 1; }

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
  [.[] | select(.data["alters-state"] == true)] |
  if length == 0 then
    {
      "issue":                  $iss,
      "state":                  "UNKNOWN",
      "last-event-type":        null,
      "runtime-correlation-id": null,
      "runtime-version":        $runtime_version,
      "framework-version":      $framework_version,
      "schema-version":         $schema_version,
      "computed-at":            $ts
    }
  else
    last |
    {
      "issue":                  $iss,
      "state":                  .data["new-state"],
      "last-event-type":        .type,
      "runtime-correlation-id": .data["runtime-correlation-id"],
      "runtime-version":        $runtime_version,
      "framework-version":      $framework_version,
      "schema-version":         $schema_version,
      "computed-at":            $ts
    }
  end
  ' "$TIMELINE_FILE")

echo "$DERIVED" > "$OUTPUT_FILE"
echo "$DERIVED" > "${OUTPUT_FILE%.json}-${ISSUE}.json"
echo "$DERIVED"
