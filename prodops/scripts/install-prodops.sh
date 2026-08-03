#!/usr/bin/env bash
# install-prodops.sh — DS-54 / work-item 131
#
# Installs the ProdOps Framework from produtoreativo/prodops-framework
# into the current (or target) repository.
#
# Usage:
#   ./prodops/scripts/install-prodops.sh --version <tag> [--target <dir>]
#
# Environment overrides (for testing):
#   INSTALL_TARGET_DIR  — override target directory (takes lower priority than --target)
#
# Exit codes:
#   0  success
#   1  missing --version, version not found, or installation error

set -euo pipefail

FRAMEWORK_REPO="produtoreativo/prodops-framework"
FRAMEWORK_URL="https://github.com/${FRAMEWORK_REPO}"

VERSION=""
TARGET_DIR="${INSTALL_TARGET_DIR:-$(pwd)}"

# ── Helpers ───────────────────────────────────────────────────────────────────

usage() {
  printf 'Usage: %s --version <tag> [--target <dir>]\n' "$0" >&2
  printf 'Example: %s --version v0.1.0\n' "$0" >&2
  exit 1
}

error() {
  printf 'ERROR: %s\n' "$1" >&2
}

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { error "--version requires a value"; usage; }
      VERSION="$2"
      shift 2
      ;;
    --target)
      [[ $# -ge 2 ]] || { error "--target requires a value"; usage; }
      TARGET_DIR="$2"
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

if [[ -z "${VERSION}" ]]; then
  error "--version is required"
  usage
fi

# ── Verify version exists in the framework repository ────────────────────────

printf 'Verifying version %s in %s...\n' "${VERSION}" "${FRAMEWORK_REPO}"

if ! gh release view "${VERSION}" --repo "${FRAMEWORK_REPO}" >/dev/null 2>&1; then
  error "Version '${VERSION}' not found in ${FRAMEWORK_REPO}"
  printf 'To list available versions, run: gh release list --repo %s\n' "${FRAMEWORK_REPO}" >&2
  exit 1
fi

printf 'Version %s verified.\n' "${VERSION}"

# ── Clone the framework at the specified version ──────────────────────────────

SCRATCH=$(mktemp -d)
trap 'rm -rf "${SCRATCH}"' EXIT

printf 'Cloning %s at %s...\n' "${FRAMEWORK_REPO}" "${VERSION}"

if ! git clone --quiet --depth 1 --branch "${VERSION}" \
    "https://github.com/${FRAMEWORK_REPO}.git" "${SCRATCH}/framework" 2>/dev/null; then
  error "Failed to clone ${FRAMEWORK_REPO} at version ${VERSION}"
  exit 1
fi

# ── Create target directory structure ────────────────────────────────────────

printf 'Creating directory structure in %s...\n' "${TARGET_DIR}"

mkdir -p "${TARGET_DIR}/prodops/framework"
mkdir -p "${TARGET_DIR}/prodops/skills"
mkdir -p "${TARGET_DIR}/prodops/templates"
mkdir -p "${TARGET_DIR}/prodops/exec"
mkdir -p "${TARGET_DIR}/prodops/scripts"

# ── Protected paths — never overwrite if target file exists ──────────────────
#
# Per .prodopsignore and BDD Scenario 3:
#   prodops/artifacts/       — product OBCs, BDD, plans, trails, etc.
#   prodops/skills/local/    — product-local skills
#   prodops/exec/manifest.yaml — operational configuration

is_protected() {
  local rel="$1"
  local target_file="${TARGET_DIR}/${rel}"

  # Paths whose existing content must never be overwritten
  case "${rel}" in
    prodops/artifacts/*|prodops/skills/local/*|prodops/exec/manifest.yaml)
      [[ -e "${target_file}" ]] && return 0
      ;;
  esac
  return 1
}

# ── Copy framework content ────────────────────────────────────────────────────

FRAMEWORK_SRC="${SCRATCH}/framework"

if [[ -d "${FRAMEWORK_SRC}/prodops" ]]; then
  while IFS= read -r src_file; do
    rel="${src_file#"${FRAMEWORK_SRC}/"}"

    if is_protected "${rel}"; then
      printf 'SKIP (protected): %s\n' "${rel}"
      continue
    fi

    target_file="${TARGET_DIR}/${rel}"
    mkdir -p "$(dirname "${target_file}")"
    cp "${src_file}" "${target_file}"
  done < <(find "${FRAMEWORK_SRC}/prodops" -type f | LC_ALL=C sort)
fi

# ── Generate framework-lock.yaml ──────────────────────────────────────────────
#
# Fields required by BDD Scenario 2:
#   status: consumer
#   external_source: <framework URL>
#   synchronization_mechanism: ci-pr-sync
#   distribution.state: installed
#   drift.status: ok
#   version: <requested version>

LOCK_FILE="${TARGET_DIR}/prodops/exec/framework-lock.yaml"

if [[ ! -f "${LOCK_FILE}" ]]; then
  mkdir -p "$(dirname "${LOCK_FILE}")"
  cat >"${LOCK_FILE}" <<EOF
schema_version: 1

prodops_framework:
  version: "${VERSION}"
  status: consumer
  external_source: ${FRAMEWORK_URL}
  synchronization_mechanism: ci-pr-sync

distribution:
  state: installed

drift:
  status: ok
EOF
  printf 'Created: prodops/exec/framework-lock.yaml\n'
else
  printf 'SKIP (protected): prodops/exec/framework-lock.yaml\n'
fi

# ── Create .prodopsignore ─────────────────────────────────────────────────────

IGNORE_FILE="${TARGET_DIR}/.prodopsignore"

if [[ ! -f "${IGNORE_FILE}" ]]; then
  cat >"${IGNORE_FILE}" <<'IGNORE'
# .prodopsignore
#
# Declares areas of this repository that must not be overwritten by the
# Framework sync mechanism (e.g. CI+PR sync from prodops-framework).
#
# Rule: any path listed here belongs to the product, not the Framework.
# The Framework defines the structure (schema); the content belongs to the product.
#
# This file does NOT replace .gitignore.
# Paths listed here remain versioned and visible to git.

# ── Product artifacts ────────────────────────────────────────────────────────
# Knowledge Space: OBCs, BDD, plans, trails, intents, evidence, etc.
prodops/artifacts/

# ── Operational configuration ─────────────────────────────────────────────────
# manifest.yaml declares execution configuration for this specific product.
# framework-lock.yaml tracks the installed Framework version.
# Both are generated and maintained by the product; never by sync.
prodops/exec/manifest.yaml
prodops/exec/framework-lock.yaml
prodops/exec/cards/

# ── Product-local skills ──────────────────────────────────────────────────────
# Protects the entire product-local skills directory.
prodops/skills/local/

# ── Product-local scripts ─────────────────────────────────────────────────────
prodops/scripts/local/

# ── Product-local references ──────────────────────────────────────────────────
prodops/skills/references/local/
IGNORE
  printf 'Created: .prodopsignore\n'
else
  printf 'SKIP (exists): .prodopsignore\n'
fi

# ── Run doctor.sh at target if available ─────────────────────────────────────

DOCTOR_SCRIPT="${TARGET_DIR}/prodops/scripts/doctor.sh"
if [[ -f "${DOCTOR_SCRIPT}" ]]; then
  printf 'Running doctor.sh at target...\n'
  if bash "${DOCTOR_SCRIPT}" >/dev/null 2>&1; then
    printf 'doctor.sh: passed.\n'
  else
    printf 'WARNING: doctor.sh reported issues — review and fix before committing.\n' >&2
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

printf '\nProdOps Framework %s installed successfully at %s\n' "${VERSION}" "${TARGET_DIR}"
