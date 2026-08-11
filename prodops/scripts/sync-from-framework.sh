#!/usr/bin/env bash
# sync-from-framework.sh — DS-55 / work-item 132
#
# Syncs the ProdOps Framework in the current repository from a new version.
#
# Usage:
#   ./prodops/scripts/sync-from-framework.sh --version <tag> [--framework-source <path>]
#   ./prodops/scripts/sync-from-framework.sh --check [--framework-source <path>]
#   ./prodops/scripts/sync-from-framework.sh --dry-run --version <tag> [--framework-source <path>]
#
# Environment overrides (for testing):
#   FRAMEWORK_SOURCE   — path to framework source directory (skips git clone)
#   SYNC_REPO_ROOT     — override the repository root (for isolated testing)
#   PRODOPS_GH_DRY_RUN — if set to "true", skip actual gh pr create
#   SYNC_DOCTOR_CMD    — override doctor command (default: prodops/scripts/doctor.sh)
#
# Exit codes:
#   0  success (or no drift when using --check)
#   1  drift detected (--check), missing args, or execution error

set -euo pipefail

FRAMEWORK_REPO="produtoreativo/prodops-framework"
LOCK_FILE_REL="prodops/exec/framework-lock.yaml"
IGNORE_FILE_REL=".prodopsignore"

VERSION=""
CHECK_MODE=false
DRY_RUN=false
FRAMEWORK_SOURCE="${FRAMEWORK_SOURCE:-}"
PRODOPS_GH_DRY_RUN="${PRODOPS_GH_DRY_RUN:-false}"

# ── Helpers ───────────────────────────────────────────────────────────────────

usage() {
  printf 'Usage:\n' >&2
  printf '  %s --version <tag> [--framework-source <path>] [--dry-run]\n' "$0" >&2
  printf '  %s --check [--framework-source <path>]\n' "$0" >&2
  printf '  %s --dry-run --version <tag> [--framework-source <path>]\n' "$0" >&2
  exit 1
}

error() { printf 'ERROR: %s\n' "$1" >&2; }
info()  { printf 'INFO:  %s\n' "$1"; }

# Update framework-lock.yaml with new version and drift.status=ok.
# Attempts python3 first; falls back to portable sed.
update_lock_file() {
  local lock_path="$1"
  local new_version="$2"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "${lock_path}" "${new_version}" <<'PYEOF'
import sys, re

lock_file = sys.argv[1]
new_version = sys.argv[2]

with open(lock_file, 'r') as f:
    content = f.read()

# Replace version field under prodops_framework block.
# Matches: "  version: ..." (indented, within prodops_framework section)
content = re.sub(
    r'(\bversion:\s*)["\']?[^\n"\'#]+["\']?',
    lambda m: m.group(1) + '"' + new_version + '"',
    content,
    count=1
)

# Replace drift.status value
content = re.sub(
    r'(drift:\s*\n\s*status:\s*)\S+',
    lambda m: m.group(1) + 'ok',
    content,
    count=1
)

with open(lock_file, 'w') as f:
    f.write(content)
PYEOF
    info "Updated ${lock_path}: version=${new_version}, drift.status=ok (via python3)"
  else
    # Portable sed: write to temp then move (avoids -i portability issues)
    local tmp
    tmp=$(mktemp)
    sed "s/version: \"[^\"]*\"/version: \"${new_version}\"/" "${lock_path}" > "${tmp}"
    mv "${tmp}" "${lock_path}"
    info "Updated ${lock_path}: version=${new_version} (via sed; drift.status may need manual update)"
  fi
}

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { error "--version requires a value"; usage; }
      VERSION="$2"
      shift 2
      ;;
    --check)
      CHECK_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --framework-source)
      [[ $# -ge 2 ]] || { error "--framework-source requires a value"; usage; }
      FRAMEWORK_SOURCE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      error "Unknown option: $1"
      usage
      ;;
  esac
done

# At least one mode must be specified
if [[ "${CHECK_MODE}" == false && "${DRY_RUN}" == false && -z "${VERSION}" ]]; then
  error "one of --version <tag>, --check, or --dry-run is required"
  usage
fi

# ── Repository root ───────────────────────────────────────────────────────────
# SYNC_REPO_ROOT is an env override for isolated testing; defaults to two dirs up from script.

if [[ -n "${SYNC_REPO_ROOT:-}" ]]; then
  ROOT_DIR="${SYNC_REPO_ROOT}"
else
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

cd "${ROOT_DIR}"

LOCK_FILE="${ROOT_DIR}/${LOCK_FILE_REL}"
IGNORE_FILE="${ROOT_DIR}/${IGNORE_FILE_REL}"

# ── Doctor command ────────────────────────────────────────────────────────────
# SYNC_DOCTOR_CMD allows tests to inject a stub that exits 0 without real checks.

if [[ -n "${SYNC_DOCTOR_CMD:-}" ]]; then
  DOCTOR_CMD="${SYNC_DOCTOR_CMD}"
else
  DOCTOR_CMD="${ROOT_DIR}/prodops/scripts/doctor.sh"
fi

# ── Pre-flight: verify lock file ──────────────────────────────────────────────

if [[ ! -f "${LOCK_FILE}" ]]; then
  error "${LOCK_FILE_REL} not found — is this a ProdOps-enabled repository?"
  exit 1
fi

# Read installed version from lock file
INSTALLED_VERSION="$(grep -E '^\s*version:' "${LOCK_FILE}" | head -1 \
  | sed 's/.*version:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]')"

# ── Protected-path helpers ────────────────────────────────────────────────────

read_ignored_patterns() {
  [[ -f "${IGNORE_FILE}" ]] || return 0
  grep -v '^#' "${IGNORE_FILE}" | grep -v '^[[:space:]]*$'
}

is_ignored() {
  local target_path="$1"
  while IFS= read -r pattern; do
    [[ -z "${pattern}" ]] && continue
    local clean="${pattern%/}"
    if [[ "${target_path}" == "${clean}" || "${target_path}" == "${clean}/"* ]]; then
      return 0
    fi
  done < <(read_ignored_patterns)
  return 1
}

# ── Framework source setup ────────────────────────────────────────────────────

SCRATCH=""
cleanup() {
  if [[ -n "${SCRATCH}" && -d "${SCRATCH}" ]]; then
    rm -rf "${SCRATCH}"
  fi
}
trap cleanup EXIT

if [[ -z "${FRAMEWORK_SOURCE}" ]]; then
  local_version="${VERSION:-${INSTALLED_VERSION}}"
  if [[ -z "${local_version}" ]]; then
    error "cannot determine framework version to fetch; provide --version or FRAMEWORK_SOURCE"
    exit 1
  fi
  SCRATCH=$(mktemp -d)
  info "Cloning framework version ${local_version} from ${FRAMEWORK_REPO}..."
  git clone --depth 1 --branch "${local_version}" \
    "https://github.com/${FRAMEWORK_REPO}.git" \
    "${SCRATCH}/framework" >/dev/null 2>&1
  FRAMEWORK_SOURCE="${SCRATCH}/framework"
fi

# ── Compute diverging files ───────────────────────────────────────────────────

compute_changed_files() {
  local src_dir="$1"
  local -a changed=()

  while IFS= read -r src_file; do
    local rel_path="${src_file#${src_dir}/}"
    is_ignored "${rel_path}" && continue

    local dest_file="${ROOT_DIR}/${rel_path}"
    if [[ ! -f "${dest_file}" ]]; then
      changed+=("${rel_path} (new)")
    elif ! diff -q "${src_file}" "${dest_file}" >/dev/null 2>&1; then
      changed+=("${rel_path} (modified)")
    fi
  done < <(find "${src_dir}" -type f -not -path "${src_dir}/.git/*" | sort)

  printf '%s\n' "${changed[@]+"${changed[@]}"}"
}

# ── --check mode ──────────────────────────────────────────────────────────────

if [[ "${CHECK_MODE}" == true ]]; then
  info "Checking for drift (installed: ${INSTALLED_VERSION})..."

  drift_count=0
  while IFS= read -r entry; do
    [[ -z "${entry}" ]] && continue
    printf '  - %s\n' "${entry}" >&2
    drift_count=$((drift_count + 1))
  done < <(compute_changed_files "${FRAMEWORK_SOURCE}" || true)

  if [[ "${drift_count}" -eq 0 ]]; then
    info "No drift detected. Repository is up to date."
    exit 0
  fi

  printf 'DRIFT DETECTED: %d file(s) diverge from framework source\n' \
    "${drift_count}" >&2
  exit 1
fi

# ── --dry-run mode ────────────────────────────────────────────────────────────

if [[ "${DRY_RUN}" == true ]]; then
  info "DRY-RUN: showing what would be updated (no changes will be made, no PR opened)"

  dry_count=0
  while IFS= read -r entry; do
    [[ -z "${entry}" ]] && continue
    printf '  WOULD UPDATE: %s\n' "${entry}"
    dry_count=$((dry_count + 1))
  done < <(compute_changed_files "${FRAMEWORK_SOURCE}" || true)

  if [[ "${dry_count}" -eq 0 ]]; then
    info "No files would be updated."
  fi

  info "DRY-RUN complete: no files were modified, no PR opened."
  exit 0
fi

# ── Full sync mode ─────────────────────────────────────────────────────────────

BRANCH="update/prodops-framework-${VERSION}"

info "Starting framework sync to version ${VERSION} (installed: ${INSTALLED_VERSION})"

# Pre-sync doctor check
info "Running doctor.sh pre-sync check..."
if ! bash "${DOCTOR_CMD}"; then
  error "doctor.sh failed pre-sync — aborting sync."
  exit 1
fi
info "Pre-sync doctor check passed."

# Create or switch to the sync branch (never commits directly to main/master)
info "Creating branch ${BRANCH}..."
if git rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
  git checkout "${BRANCH}"
else
  git checkout -b "${BRANCH}"
fi

# Copy framework files — skip protected paths declared in .prodopsignore
info "Copying framework files..."
while IFS= read -r src_file; do
  rel_path="${src_file#${FRAMEWORK_SOURCE}/}"

  if is_ignored "${rel_path}"; then
    info "  SKIP (protected): ${rel_path}"
    continue
  fi

  dest_file="${ROOT_DIR}/${rel_path}"
  mkdir -p "$(dirname "${dest_file}")"
  cp "${src_file}" "${dest_file}"
  info "  COPY: ${rel_path}"
done < <(find "${FRAMEWORK_SOURCE}" -type f -not -path "${FRAMEWORK_SOURCE}/.git/*" | sort)

# Update framework-lock.yaml with new version and drift.status=ok
update_lock_file "${LOCK_FILE}" "${VERSION}"

# Update framework-version in runtime.yaml if it exists (protected file — only version field changes)
RUNTIME_YAML="${ROOT_DIR}/prodops/runtime/runtime.yaml"
if [[ -f "${RUNTIME_YAML}" ]]; then
  if python3 - "${RUNTIME_YAML}" "${VERSION}" <<'PYEOF' 2>/dev/null; then
import sys, re
path, version = sys.argv[1], sys.argv[2]
content = open(path).read()
content = re.sub(
    r'(?m)^(framework-version:\s*)["\']?[^"\'\n]*["\']?',
    r'\g<1>"' + version + '"',
    content,
)
open(path, 'w').write(content)
PYEOF
    info "Updated runtime.yaml framework-version → ${VERSION}"
  else
    info "WARNING: could not update framework-version in runtime.yaml — update manually"
  fi
fi

# Commit on the sync branch
git add -A
git commit -m "chore(framework): sync prodops-framework to ${VERSION}

Automated sync of framework files from ${INSTALLED_VERSION} to ${VERSION}.
Protected paths declared in .prodopsignore were not modified.

Co-Authored-By: ProdOps Sync Bot <noreply@prodops>"

# Post-sync doctor check
info "Running doctor.sh post-sync check..."
if ! bash "${DOCTOR_CMD}"; then
  error "doctor.sh failed post-sync — review the diff before merging."
  exit 1
fi
info "Post-sync doctor check passed."

# Open PR (or skip for dry-run guard)
if [[ "${PRODOPS_GH_DRY_RUN}" == "true" ]]; then
  info "PRODOPS_GH_DRY_RUN=true — skipping gh pr create (dry run mode)"
else
  info "Opening PR for branch ${BRANCH}..."
  gh pr create \
    --title "chore(framework): sync prodops-framework to ${VERSION}" \
    --body "$(cat <<EOF
## Framework Sync — ${VERSION}

Automated update of ProdOps Framework files from \`${INSTALLED_VERSION}\` to \`${VERSION}\`.

### What changed
See commit diff for the full list of updated files.

### Protected paths (not modified)
- \`prodops/artifacts/\`
- \`prodops/exec/manifest.yaml\`
- \`prodops/exec/framework-lock.yaml\`
- \`prodops/runtime/runtime.yaml\` (framework-version field updated automatically)
- \`prodops/skills/local/\`
- \`prodops/skills/references/local/\`
- \`prodops/scripts/local/\`

### Pre-merge checklist
- [ ] Review diff for unexpected changes
- [ ] Confirm \`prodops/scripts/doctor.sh\` passes on this branch
- [ ] Merge — do NOT squash (preserves sync authorship)

Generated by \`prodops/scripts/sync-from-framework.sh\`
EOF
    )"
fi

info "Sync complete. Branch: ${BRANCH}"
