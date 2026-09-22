#!/usr/bin/env bash
# =============================================================================
# spire-submit.sh — Validate and submit service artifacts to Spire
# =============================================================================
#
# Discovers and validates governance artifacts for the Spire platform:
#   - catalog-info.yaml  (Backstage entity — required)
#   - api/openapi.yaml   (OpenAPI spec — recommended)
#   - prodops/artifacts/obcs/*.md  (OBCs — recommended)
#
# In validate-only mode, no external connection is needed.
# For submission, requires Keycloak credentials and Spire API URL.
#
# Usage:
#   ./scripts/spire-submit.sh [options]
#
# Options:
#   --validate-only           Run validation only, skip submission
#   --dry-run                 Validate + show what would be submitted
#   --catalog-url URL         GitHub raw URL of catalog-info.yaml for remote registration
#                             (default: builds from GITHUB_ORG/GITHUB_REPO/GITHUB_BRANCH)
#   --catalog FILE            Local catalog-info.yaml path (default: catalog-info.yaml)
#   --openapi FILE            Local openapi.yaml path (default: api/openapi.yaml)
#   --obcs DIR                OBCs directory (default: prodops/artifacts/obcs)
#   --ca-cert FILE            Path to CA cert for HTTPS (e.g., local Spire stack)
#   --help                    Show this help
#
# Env vars (required for submission, not for --validate-only):
#   SPIRE_URL                 https://api.spire.localhost
#   KEYCLOAK_URL              https://keycloak.spire.localhost
#   SPIRE_CLIENT_ID           payments-api-pipeline
#   SPIRE_CLIENT_SECRET       <client secret>
#   SPIRE_REALM               spire (default)
#
# Env vars (optional):
#   GITHUB_ORG                produtoreativo (used to build catalog URL)
#   GITHUB_REPO               payments-api
#   GITHUB_BRANCH             main (default)
#   CA_CERT                   path to CA cert (same as --ca-cert)
#   SPIRE_SKIP_OBC_VALIDATION false (set to true to skip OBC validation)
#
# Exit codes:
#   0  — validation passed (and submission succeeded if applicable)
#   1  — validation errors (critical — submission blocked)
#   2  — submission failed (validation passed but Spire unreachable or rejected)
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}→${RESET} $*"; }
ok()      { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
VALIDATE_ONLY=false
DRY_RUN=false
CATALOG_FILE="catalog-info.yaml"
OPENAPI_FILE="api/openapi.yaml"
OBCS_DIR="prodops/artifacts/obcs"
CATALOG_URL=""
CA_CERT="${CA_CERT:-}"
SPIRE_REALM="${SPIRE_REALM:-spire}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
SKIP_OBC="${SPIRE_SKIP_OBC_VALIDATION:-false}"

ERRORS=0
WARNINGS=0

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only)  VALIDATE_ONLY=true; shift ;;
    --dry-run)        DRY_RUN=true; shift ;;
    --catalog-url)    CATALOG_URL="$2"; shift 2 ;;
    --catalog)        CATALOG_FILE="$2"; shift 2 ;;
    --openapi)        OPENAPI_FILE="$2"; shift 2 ;;
    --obcs)           OBCS_DIR="$2"; shift 2 ;;
    --ca-cert)        CA_CERT="$2"; shift 2 ;;
    --help|-h)
      sed -n '/^# Usage/,/^# ==/p' "$0" | grep -v "^# ==" | sed 's/^# \?//'
      exit 0 ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

curl_opts=(-sk)
[[ -n "$CA_CERT" ]] && curl_opts+=(--cacert "$CA_CERT")

require_python3() {
  command -v python3 >/dev/null 2>&1 || { error "python3 is required for validation"; exit 1; }
}

require_python3

# ── Validation: catalog-info.yaml ─────────────────────────────────────────────
validate_catalog() {
  local file="$1"
  header "Validating catalog-info.yaml"

  if [[ ! -f "$file" ]]; then
    error "catalog-info.yaml not found at: $file"
    ((ERRORS++)); return
  fi

  python3 - <<PYEOF
import yaml, sys

try:
    with open("$file") as f:
        docs = list(yaml.safe_load_all(f))
except yaml.YAMLError as e:
    print(f"ERROR: YAML parse error: {e}")
    sys.exit(1)

errors = []
warnings = []

component = next((d for d in docs if d and d.get("kind") == "Component"), None)
if not component:
    errors.append("No 'kind: Component' document found")
else:
    meta = component.get("metadata", {})
    spec = component.get("spec", {})
    api_version = component.get("apiVersion", "")

    if not api_version.startswith("backstage.io/"):
        errors.append(f"apiVersion must start with 'backstage.io/' (got: {api_version!r})")
    if not meta.get("name"):
        errors.append("metadata.name is required")
    if not meta.get("description"):
        warnings.append("metadata.description is recommended")
    if not spec.get("type"):
        errors.append("spec.type is required")
    if not spec.get("owner"):
        errors.append("spec.owner is required")
    if not spec.get("lifecycle"):
        errors.append("spec.lifecycle is required (production|experimental|deprecated)")
    if spec.get("system") != "spire":
        errors.append(f"spec.system must be 'spire' for Spire governance (got: {spec.get('system')!r})")
    if not spec.get("providesApis") and not spec.get("consumesApis"):
        warnings.append("spec.providesApis is recommended for service components")

for e in errors:
    print(f"ERROR: {e}")
for w in warnings:
    print(f"WARNING: {w}")

if not errors:
    name = component["metadata"]["name"]
    stype = component["spec"]["type"]
    lifecycle = component["spec"]["lifecycle"]
    print(f"OK: Component '{name}' (type={stype}, lifecycle={lifecycle})")

sys.exit(len(errors))
PYEOF

  local exit_code=$?
  [[ $exit_code -eq 0 ]] && ok "catalog-info.yaml valid" || ((ERRORS += exit_code))
}

# ── Validation: openapi.yaml ──────────────────────────────────────────────────
validate_openapi() {
  local file="$1"
  header "Validating openapi.yaml"

  if [[ ! -f "$file" ]]; then
    warn "openapi.yaml not found at: $file (recommended — add an OpenAPI spec)"
    ((WARNINGS++)); return
  fi

  python3 - <<PYEOF
import yaml, sys

try:
    with open("$file") as f:
        doc = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"ERROR: YAML parse error: {e}")
    sys.exit(1)

errors = []
warnings = []

version = str(doc.get("openapi", ""))
if not version.startswith("3."):
    errors.append(f"openapi field must be 3.x.x (got: {version!r})")

info_block = doc.get("info", {})
if not info_block.get("title"):
    errors.append("info.title is required")
if not info_block.get("version"):
    errors.append("info.version is required")
if not info_block.get("description"):
    warnings.append("info.description is recommended")

paths = doc.get("paths", {})
if not paths:
    errors.append("paths must not be empty")
else:
    # Check for operations without operationId
    missing_ids = []
    for path, methods in paths.items():
        for method, op in methods.items():
            if method in ("get","post","put","patch","delete","options","head") and isinstance(op, dict):
                if not op.get("operationId"):
                    missing_ids.append(f"{method.upper()} {path}")
    if missing_ids:
        warnings.append(f"Missing operationId on: {', '.join(missing_ids[:3])}" + (" ..." if len(missing_ids) > 3 else ""))

servers = doc.get("servers", [])
if not servers:
    warnings.append("servers[] is recommended (defines staging/production URLs)")

for e in errors:
    print(f"ERROR: {e}")
for w in warnings:
    print(f"WARNING: {w}")

if not errors:
    paths_count = len(paths)
    title = info_block.get("title", "?")
    ver = info_block.get("version", "?")
    print(f"OK: OpenAPI '{title}' v{ver} — {paths_count} paths")

sys.exit(len(errors))
PYEOF

  local exit_code=$?
  [[ $exit_code -eq 0 ]] && ok "openapi.yaml valid" || ((ERRORS += exit_code))
}

# ── Validation: OBCs ──────────────────────────────────────────────────────────
validate_obcs() {
  local dir="$1"
  header "Validating OBCs (Observable Business Contracts)"

  if [[ ! -d "$dir" ]]; then
    warn "OBCs directory not found: $dir (recommended)"
    ((WARNINGS++)); return
  fi

  local obc_count=0 valid=0 obc_warnings=0

  while IFS= read -r obc; do
    local fname
    fname="$(basename "$obc")"

    # Skip README and non-OBC files
    [[ "$fname" == README* ]] && continue

    obc_count=$((obc_count + 1))
    local file_errors=0

    # Required sections
    if ! grep -q "^## Business Outcome" "$obc"; then
      warn "$fname: missing '## Business Outcome'"
      file_errors=$((file_errors + 1))
    fi
    if ! grep -q "^## Observable Events" "$obc"; then
      warn "$fname: missing '## Observable Events'"
      file_errors=$((file_errors + 1))
    fi

    # Recommended sections
    if ! grep -q "^## Initial SLIs" "$obc"; then
      info "$fname: missing '## Initial SLIs' (recommended)"
    fi
    if ! grep -q "^## Reliability Rules" "$obc"; then
      info "$fname: missing '## Reliability Rules' (recommended)"
    fi

    if [[ $file_errors -eq 0 ]]; then
      valid=$((valid + 1))
    else
      obc_warnings=$((obc_warnings + 1))
      WARNINGS=$((WARNINGS + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -name "*.md" | LC_ALL=C sort)

  if [[ $obc_count -eq 0 ]]; then
    warn "No OBC files found in $dir"
    ((WARNINGS++))
    return
  fi

  ok "OBCs: $obc_count found — $valid valid, $obc_warnings with warnings"
}

# ── Build validation report ───────────────────────────────────────────────────
build_report() {
  local service_name
  service_name=$(python3 -c "
import yaml
try:
    docs = list(yaml.safe_load_all(open('$CATALOG_FILE')))
    comp = next((d for d in docs if d and d.get('kind') == 'Component'), None)
    print(comp['metadata']['name'] if comp else 'unknown')
except: print('unknown')
" 2>/dev/null)

  local status="valid"
  [[ $WARNINGS -gt 0 ]] && status="warnings"
  [[ $ERRORS -gt 0 ]] && status="invalid"

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  python3 - <<PYEOF
import json
report = {
    "service": "$service_name",
    "timestamp": "$timestamp",
    "status": "$status",
    "summary": {
        "errors": $ERRORS,
        "warnings": $WARNINGS,
    },
    "artifacts": {
        "catalog": "$CATALOG_FILE",
        "openapi": "$OPENAPI_FILE",
        "obcs_dir": "$OBCS_DIR"
    }
}
print(json.dumps(report, indent=2))
PYEOF
}

# ── Submission ────────────────────────────────────────────────────────────────
submit_to_spire() {
  header "Submitting to Spire"

  # Build catalog URL if not provided
  if [[ -z "$CATALOG_URL" ]]; then
    local org="${GITHUB_ORG:-}"
    local repo="${GITHUB_REPO:-}"
    if [[ -n "$org" && -n "$repo" ]]; then
      CATALOG_URL="https://raw.githubusercontent.com/${org}/${repo}/${GITHUB_BRANCH}/catalog-info.yaml"
    else
      # Try to infer from git remote
      local remote
      remote=$(git remote get-url origin 2>/dev/null || echo "")
      if [[ "$remote" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        local inferred_org="${BASH_REMATCH[1]}"
        local inferred_repo="${BASH_REMATCH[2]}"
        CATALOG_URL="https://raw.githubusercontent.com/${inferred_org}/${inferred_repo}/${GITHUB_BRANCH}/catalog-info.yaml"
        info "Inferred catalog URL from git remote: $CATALOG_URL"
      else
        error "Cannot determine GitHub URL. Set GITHUB_ORG + GITHUB_REPO or --catalog-url"
        return 2
      fi
    fi
  fi

  # Validate env vars for submission
  local missing=()
  [[ -z "${SPIRE_URL:-}" ]]            && missing+=("SPIRE_URL")
  [[ -z "${KEYCLOAK_URL:-}" ]]         && missing+=("KEYCLOAK_URL")
  [[ -z "${SPIRE_CLIENT_ID:-}" ]]      && missing+=("SPIRE_CLIENT_ID")
  [[ -z "${SPIRE_CLIENT_SECRET:-}" ]]  && missing+=("SPIRE_CLIENT_SECRET")

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing env vars for submission: ${missing[*]}"
    error "Run with --validate-only to skip submission, or set the required vars."
    return 2
  fi

  info "Authenticating with Keycloak ($KEYCLOAK_URL)..."

  local token_response
  token_response=$(curl "${curl_opts[@]}" \
    -X POST "$KEYCLOAK_URL/realms/$SPIRE_REALM/protocol/openid-connect/token" \
    -d "client_id=$SPIRE_CLIENT_ID&client_secret=$SPIRE_CLIENT_SECRET&grant_type=client_credentials" \
    2>/dev/null)

  local jwt
  jwt=$(echo "$token_response" | python3 -c "
import json,sys
try:
    r=json.load(sys.stdin)
except Exception as e:
    print(f'ERROR: could not parse Keycloak response: {e}', file=sys.stderr)
    sys.exit(1)
if 'access_token' in r:
    print(r['access_token'])
else:
    print('ERROR: ' + r.get('error','?') + ': ' + r.get('error_description',''), file=sys.stderr)
    sys.exit(1)
" 2>&1)

  if [[ $? -ne 0 || "$jwt" == ERROR:* ]]; then
    error "Keycloak auth failed: $jwt"
    return 2
  fi
  ok "Authenticated (client_credentials)"

  if $DRY_RUN; then
    info "[dry-run] Would submit to: $SPIRE_URL"
    info "[dry-run] Catalog URL: $CATALOG_URL"
    info "[dry-run] POST $SPIRE_URL/backstage/api/catalog/locations"
    info "[dry-run] Body: {\"type\": \"url\", \"target\": \"$CATALOG_URL\"}"
    ok "Dry run complete"
    return 0
  fi

  info "Registering catalog location in Backstage..."
  info "  URL: $CATALOG_URL"

  local http_code body
  http_code=$(curl "${curl_opts[@]}" \
    -o /tmp/spire_submit_response.json \
    -w "%{http_code}" \
    -X POST "$SPIRE_URL/backstage/api/catalog/locations" \
    -H "Authorization: Bearer $jwt" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"url\", \"target\": \"$CATALOG_URL\"}" \
    2>/dev/null)
  body=$(cat /tmp/spire_submit_response.json 2>/dev/null || echo "{}")

  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    local entity_name
    entity_name=$(echo "$body" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    loc=d.get('location',{})
    print(loc.get('target','?'))
except: print('(see Backstage catalog)')
" 2>/dev/null || echo "(see Backstage catalog)")
    ok "Service registered! Location: $entity_name"
    info "View in Backstage: ${BACKSTAGE_URL:-https://backstage.spire.localhost}/catalog"
    return 0
  elif [[ "$http_code" == "401" ]]; then
    error "Authorization failed (HTTP 401) — check SPIRE_CLIENT_ID/SECRET and spire-registrar role"
    return 2
  elif [[ "$http_code" == "403" ]]; then
    error "Access denied (HTTP 403) — service account may not have spire-registrar role"
    return 2
  elif [[ "$http_code" == "409" ]]; then
    ok "Service already registered (HTTP 409 — location exists, Backstage will refresh)"
    return 0
  else
    error "Registration failed (HTTP $http_code): $body"
    return 2
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}═══════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Spire Governance Submission                          ${RESET}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════${RESET}"
  echo -e "  Repo: $(pwd)"
  echo -e "  Mode: $( $VALIDATE_ONLY && echo "validate-only" || ($DRY_RUN && echo "dry-run" || echo "validate + submit") )"
  echo ""

  # Run all validations
  validate_catalog "$CATALOG_FILE"
  validate_openapi "$OPENAPI_FILE"
  [[ "$SKIP_OBC" != "true" ]] && validate_obcs "$OBCS_DIR"

  # Summary
  header "Validation Summary"
  echo ""
  if [[ $ERRORS -gt 0 ]]; then
    error "Errors: $ERRORS — submission blocked"
    [[ $WARNINGS -gt 0 ]] && warn "Warnings: $WARNINGS"
  else
    ok "Errors: 0"
    [[ $WARNINGS -gt 0 ]] && warn "Warnings: $WARNINGS" || ok "Warnings: 0"
  fi

  echo ""
  echo -e "${BOLD}Validation Report (JSON):${RESET}"
  build_report

  # Abort if validation failed
  if [[ $ERRORS -gt 0 ]]; then
    echo ""
    error "Fix errors before submitting to Spire."
    exit 1
  fi

  # Submission
  if $VALIDATE_ONLY; then
    echo ""
    ok "Validation passed. Run without --validate-only to submit."
    exit 0
  fi

  local sub_exit=0
  submit_to_spire || sub_exit=$?

  echo ""
  [[ $sub_exit -eq 0 ]] && ok "Done." || { error "Submission failed (exit $sub_exit)."; exit $sub_exit; }
}

main "$@"
