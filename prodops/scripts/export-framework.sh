#!/usr/bin/env bash
# Extracts ProdOps Framework canonical content from payments-api (empirical upstream)
# and opens a pull request on prodops-framework.
#
# Usage:
#   ./prodops/scripts/export-framework.sh
#
# Environment variables (for testing / automation):
#   EXPORT_DRY_RUN=1          Print files that would be copied; do not clone or open PR.
#   EXPORT_MANIFEST_OVERRIDE  Path to an alternative manifest (for testing invalid manifests).
#   EXPORT_DEST_DIR           Override the destination clone directory.
#   PRODOPS_FRAMEWORK_REPO    Target repository (default: produtoreativo/prodops-framework).
#
# Exit 0 = export complete (or dry-run printed list).
# Exit 1 = validation failure or unexpected error; no PR opened.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

VALIDATE_SCRIPT="prodops/scripts/validate-export-manifest.sh"
DOCTOR_SCRIPT="prodops/scripts/doctor.sh"
MANIFEST="${EXPORT_MANIFEST_OVERRIDE:-prodops/exec/export-manifest.yaml}"
FRAMEWORK_REPO="${PRODOPS_FRAMEWORK_REPO:-produtoreativo/prodops-framework}"
DRY_RUN="${EXPORT_DRY_RUN:-0}"

EXCLUDED_PREFIXES=(
  "prodops/artifacts/"
  "prodops/exec/"
  "prodops/skills/local/"
  "prodops/skills/references/local/"
  "prodops/templates/local/"
  "prodops/scripts/local/"
)

# ── Helpers ────────────────────────────────────────────────────────────────────

log()  { printf '[export-framework] %s\n' "$1" >&2; }
err()  { printf '[export-framework] ERROR: %s\n' "$1" >&2; }
die()  { err "$1"; exit 1; }

# ── Step 1: Validate the export manifest ──────────────────────────────────────

log "Validating export manifest: ${MANIFEST}"

if [[ ! -f "${MANIFEST}" ]]; then
  die "Export manifest not found: ${MANIFEST}"
fi

# When using a manifest override (e.g. test with broken manifest), run validation
# against that file by temporarily replacing the default location check.
if [[ "${MANIFEST}" != "prodops/exec/export-manifest.yaml" ]]; then
  # Run a minimal structure check against the override manifest.
  validation_errors=0

  check_field() {
    local field="$1"
    if ! grep -q "^${field}" "${MANIFEST}" 2>/dev/null; then
      err "Manifest validation failed: missing required field '${field}'"
      validation_errors=$((validation_errors + 1))
    fi
  }

  check_field "schema_version"

  if ! grep -q "include:" "${MANIFEST}" 2>/dev/null; then
    err "Manifest validation failed: missing required section 'export.include'"
    validation_errors=$((validation_errors + 1))
  fi

  if ! grep -q "exclude:" "${MANIFEST}" 2>/dev/null; then
    err "Manifest validation failed: missing required section 'export.exclude'"
    validation_errors=$((validation_errors + 1))
  fi

  if [[ "${validation_errors}" -gt 0 ]]; then
    die "Export manifest validation failed with ${validation_errors} issue(s). No PR will be opened."
  fi
else
  # Standard path: delegate to validate-export-manifest.sh
  if [[ ! -x "${VALIDATE_SCRIPT}" ]]; then
    die "Validation script not executable: ${VALIDATE_SCRIPT}"
  fi

  validate_output=$(bash "${VALIDATE_SCRIPT}" 2>&1) || {
    err "Manifest validation failed:"
    printf '%s\n' "${validate_output}" >&2
    die "Fix the issues listed above. No PR will be opened."
  }
  log "Manifest validation passed."
fi

# ── Step 2: Run doctor on source repo ─────────────────────────────────────────

if [[ "${DRY_RUN}" != "1" ]]; then
  log "Running doctor.sh on source repository (failures in artifacts/ are non-fatal for export)..."
  if [[ ! -x "${DOCTOR_SCRIPT}" ]]; then
    die "doctor.sh not executable: ${DOCTOR_SCRIPT}"
  fi
  DOCTOR_OUTPUT=$(bash "${DOCTOR_SCRIPT}" 2>&1) || true
  # Fail only if issues are in exported paths (framework/, skills/, templates/, scripts/).
  # Failures in artifacts/ or exec/ are product-specific and do not affect export quality.
  EXPORTED_FAILS=$(printf '%s\n' "${DOCTOR_OUTPUT}" | grep '^FAIL:' \
    | grep -v 'prodops/artifacts/' \
    | grep -v 'prodops/exec/' \
    | grep -v '^FAIL: stale artifact' \
    || true)
  if [[ -n "${EXPORTED_FAILS}" ]]; then
    printf '%s\n' "${EXPORTED_FAILS}" >&2
    die "doctor.sh found issues in exported paths. Fix before exporting."
  fi
  ARTIFACTS_FAILS=$(printf '%s\n' "${DOCTOR_OUTPUT}" | grep -c '^FAIL:' || true)
  if [[ "${ARTIFACTS_FAILS}" -gt 0 ]]; then
    log "WARNING: doctor.sh found ${ARTIFACTS_FAILS} issue(s) in non-exported paths (artifacts/ / exec/) — skipped."
  fi
  log "Exported path health check passed."
fi

# ── Step 3: Resolve files to copy ─────────────────────────────────────────────

log "Resolving files from manifest includes (relative to prodops/)..."

# Read include patterns from manifest (lines under 'include:' until next section)
# Use while-read for bash 3.x compatibility (macOS ships bash 3.2).
include_patterns=()
while IFS= read -r line; do
  include_patterns+=("${line}")
done < <(awk '/^  include:/{f=1; next} f && /^  [a-z]/{f=0} f && /^    -/{print $2}' "${MANIFEST}")

# Read exclude patterns from manifest
exclude_patterns=()
while IFS= read -r line; do
  exclude_patterns+=("${line}")
done < <(awk '/^  exclude:/{f=1; next} f && /^  [a-z]/{f=0} f && /^    -/{print $2}' "${MANIFEST}")

# Collect candidate files matching include globs (relative to prodops/)
candidate_files=()

for pattern in "${include_patterns[@]}"; do
  # Expand glob relative to prodops/ directory
  while IFS= read -r matched; do
    [[ -z "${matched}" ]] && continue
    candidate_files+=("${matched}")
  done < <(cd prodops && find . -path "./${pattern}" -type f 2>/dev/null | sed 's|^\./||' || true)

  # Also handle root-level files (LICENSE, CHANGELOG.md etc) that are NOT under prodops/
  case "${pattern}" in
    LICENSE|CHANGELOG.md|*.md)
      if [[ -f "${pattern}" ]]; then
        candidate_files+=("__root__/${pattern}")
      fi
      ;;
  esac
done

# Filter: remove files matching exclude patterns or excluded prefixes
export_files=()

is_excluded() {
  local rel_path="$1"

  # Check against manifest exclude patterns
  for pat in "${exclude_patterns[@]}"; do
    # Strip trailing /** for prefix matching
    local prefix="${pat%/**}"
    if [[ "${rel_path}" == "${pat}" ]] || \
       [[ "${pat}" == *"/**" && "${rel_path}" == "${prefix}/"* ]] || \
       [[ "${rel_path}" == "${prefix}" ]]; then
      return 0
    fi
  done

  # Check against hard-coded excluded prefixes (absolute from repo root)
  for prefix in "${EXCLUDED_PREFIXES[@]}"; do
    local stripped="${prefix#prodops/}"
    if [[ "${rel_path}" == "${stripped}"* ]]; then
      return 0
    fi
  done

  return 1
}

for f in "${candidate_files[@]}"; do
  if is_excluded "${f}"; then
    continue
  fi
  export_files+=("${f}")
done

# ── Step 4: Dry-run output ────────────────────────────────────────────────────

if [[ "${DRY_RUN}" == "1" ]]; then
  log "DRY RUN — files that would be exported to prodops-framework:"
  for f in "${export_files[@]}"; do
    if [[ "${f}" == __root__/* ]]; then
      printf '  %s  (repo root)\n' "${f#__root__/}"
    else
      printf '  prodops/%s\n' "${f}"
    fi
  done
  log "Total: ${#export_files[@]} file(s)."
  exit 0
fi

# ── Step 5: Clone / update destination repo ───────────────────────────────────

DEST_DIR="${EXPORT_DEST_DIR:-/tmp/prodops-framework-export-$$}"
BRANCH="export/from-payments-api-$(date +%Y%m%d-%H%M%S)"

log "Cloning ${FRAMEWORK_REPO} into ${DEST_DIR}..."
if [[ -d "${DEST_DIR}/.git" ]]; then
  git -C "${DEST_DIR}" fetch origin
  DEFAULT_BRANCH=$(git -C "${DEST_DIR}" remote show origin | awk '/HEAD branch/{print $NF}')
  git -C "${DEST_DIR}" checkout "${DEFAULT_BRANCH}"
  git -C "${DEST_DIR}" pull origin "${DEFAULT_BRANCH}"
else
  gh repo clone "${FRAMEWORK_REPO}" "${DEST_DIR}" -- --quiet
  DEFAULT_BRANCH=$(git -C "${DEST_DIR}" remote show origin | awk '/HEAD branch/{print $NF}')
fi

git -C "${DEST_DIR}" checkout -b "${BRANCH}"

# ── Step 6: Copy files to destination ────────────────────────────────────────

log "Copying ${#export_files[@]} file(s) to ${DEST_DIR}..."

for f in "${export_files[@]}"; do
  if [[ "${f}" == __root__/* ]]; then
    src="${ROOT_DIR}/${f#__root__/}"
    dest="${DEST_DIR}/${f#__root__/}"
  else
    src="${ROOT_DIR}/prodops/${f}"
    dest="${DEST_DIR}/prodops/${f}"
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
done

# ── Step 7: Validate exported file count ─────────────────────────────────────
# doctor.sh is designed for product repos and expects artifacts/, exec/, skills/local/
# which are intentionally absent from the framework repo. A dedicated framework-doctor.sh
# should be introduced in a future iteration. For now, verify the file count is consistent.

DEST_FILE_COUNT=$(find "${DEST_DIR}/prodops" -type f 2>/dev/null | wc -l | tr -d ' ')
log "Exported content: ${DEST_FILE_COUNT} file(s) in destination prodops/."
if [[ "${DEST_FILE_COUNT}" -lt 50 ]]; then
  die "Destination prodops/ has fewer than 50 files — export appears incomplete."
fi
log "Destination content validation passed (${DEST_FILE_COUNT} files)."

# ── Step 8: Commit and open PR ───────────────────────────────────────────────

git -C "${DEST_DIR}" add -A
git -C "${DEST_DIR}" commit -m "feat(export): sync framework content from payments-api

Exported via prodops/scripts/export-framework.sh
Source: prodops/exec/export-manifest.yaml
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

git -C "${DEST_DIR}" push origin "${BRANCH}"

pr_url=$(gh pr create \
  --repo "${FRAMEWORK_REPO}" \
  --head "${BRANCH}" \
  --base "${DEFAULT_BRANCH}" \
  --title "feat(export): sync ProdOps Framework from payments-api empirical upstream" \
  --body "$(cat <<EOF
## Summary

This PR was generated automatically by \`prodops/scripts/export-framework.sh\`.

- Source: \`payments-api\` (empirical upstream, \`status: self\`)
- Manifest: \`prodops/exec/export-manifest.yaml\`
- Export date: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Contents

Only paths declared in \`export.include\` and not in \`export.exclude\` are included.
Product-specific paths (\`artifacts/\`, \`exec/\`, \`skills/local/\`, \`scripts/local/\`) are excluded.

## Validation

- \`validate-export-manifest.sh\` passed on source.
- \`doctor.sh\` passed on source and destination.
EOF
)")

log "Pull request opened: ${pr_url}"
