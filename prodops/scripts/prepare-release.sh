#!/usr/bin/env bash
# prepare-release.sh
#
# Prepares the ProdOps Framework for a new release from the payments-api
# empirical upstream. Runs all pre-export steps that depend on the target
# version: bumps hardcoded version references, validates CHANGELOG, and
# runs a dry-run export to confirm the manifest is consistent.
#
# Must be run BEFORE export-framework.sh.
#
# Usage:
#   bash prodops/scripts/prepare-release.sh --version <tag>
#
# Flags:
#   --version <tag>   Target version (e.g. v1.6.0) — required
#   --dry-run         Show what would change without writing files
#
# Exit codes:
#   0  success — ready to export
#   1  validation failure or missing argument

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

VERSION=""
DRY_RUN="false"

# ── Terminal formatting ───────────────────────────────────────────────────────

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
  RED=$(tput setaf 1); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  BOLD='' GREEN='' YELLOW='' RED='' CYAN='' RESET=''
fi

STEP=0
ERRORS=()

step()  { STEP=$((STEP + 1)); printf '\n%s── Step %d: %s%s\n' "${BOLD}${CYAN}" "${STEP}" "$1" "${RESET}"; }
ok()    { printf '  %s[OK]%s   %s\n' "${GREEN}" "${RESET}" "$1"; }
dry()   { printf '  %s[DRY]%s  %s\n' "${YELLOW}" "${RESET}" "$1"; }
warn()  { printf '  %s[WARN]%s %s\n' "${YELLOW}" "${RESET}" "$1" >&2; }
fail()  { printf '  %s[FAIL]%s %s\n' "${RED}" "${RESET}" "$1" >&2; ERRORS+=("$1"); }

usage() {
  printf 'Usage: %s --version <tag> [--dry-run]\n' "$0" >&2
  printf 'Example: %s --version v1.6.0\n' "$0" >&2
  exit 1
}

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) [[ $# -ge 2 ]] || { printf 'ERROR: --version requires a value\n' >&2; usage; }
               VERSION="$2"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    -h|--help) usage ;;
    *) printf 'ERROR: Unknown option: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -n "${VERSION}" ]] || { printf 'ERROR: --version is required\n' >&2; usage; }

# ── Header ────────────────────────────────────────────────────────────────────

printf '\n%sProdOps Framework — Prepare Release%s\n' "${BOLD}" "${RESET}"
printf 'Version : %s%s%s\n' "${BOLD}" "${VERSION}" "${RESET}"
[[ "${DRY_RUN}" == "true" ]] && printf 'Mode    : %sDRY RUN — no files will be written%s\n' "${YELLOW}" "${RESET}"

# ── Helpers ───────────────────────────────────────────────────────────────────

# bump_version FILE PATTERN OLD_VERSION NEW_VERSION
# Replaces all occurrences of OLD_VERSION matching PATTERN with NEW_VERSION.
bump_version() {
  local file="$1"
  local old_ver="$2"
  local new_ver="$3"

  if ! grep -q "${old_ver}" "${file}" 2>/dev/null; then
    return 0  # nothing to replace
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    local count
    count=$(grep -c "${old_ver}" "${file}" || true)
    dry "Would replace ${old_ver} → ${new_ver} (${count} occurrence(s)) in ${file#"${ROOT_DIR}/"}"
  else
    # macOS-compatible sed -i
    sed -i '' "s|${old_ver}|${new_ver}|g" "${file}"
    local count
    count=$(grep -c "${new_ver}" "${file}" || true)
    ok "Bumped ${old_ver} → ${new_ver} (${count} occurrence(s)) in ${file#"${ROOT_DIR}/"}"
  fi
}

# Detect the current version from framework-lock.yaml
detect_current_version() {
  local lock="${ROOT_DIR}/prodops/exec/framework-lock.yaml"
  if [[ -f "${lock}" ]]; then
    grep 'installed_version:' "${lock}" | awk '{print $2}' | tr -d '"' | head -1
  fi
}

# ── Step 1: Validate CHANGELOG has entry for the new version ─────────────────

step "Validate CHANGELOG.md has entry for ${VERSION}"

CHANGELOG="${ROOT_DIR}/CHANGELOG.md"

if [[ ! -f "${CHANGELOG}" ]]; then
  fail "CHANGELOG.md not found at repo root — create it before releasing"
elif ! grep -q "## \[${VERSION#v}\]" "${CHANGELOG}" && ! grep -q "## \[${VERSION}\]" "${CHANGELOG}"; then
  fail "CHANGELOG.md has no entry for ${VERSION} — add release notes before exporting"
else
  ok "CHANGELOG.md has entry for ${VERSION}"
fi

# ── Step 2: Detect current version ───────────────────────────────────────────

step "Detect current installed version"

CURRENT_VERSION=$(detect_current_version)
# Normalize: strip 'v' prefix for use as a sed pattern.
# bump_version replaces X.Y.Z occurrences in files; the 'v' prefix is preserved
# in-place (e.g. "v1.5.0" → "v1.6.0") because we match only the numeric part.
CURRENT_VERSION_BARE="${CURRENT_VERSION#v}"
VERSION_BARE="${VERSION#v}"

if [[ -z "${CURRENT_VERSION}" ]]; then
  warn "Could not detect current version from framework-lock.yaml — will scan for any vX.Y.Z"
  CURRENT_VERSION_BARE="UNKNOWN"
  ok "Will replace all vX.Y.Z patterns referencing an older version"
else
  ok "Current version: ${CURRENT_VERSION} → target: ${VERSION}"
fi

# ── Step 3: Bump version in framework/README.md + README.en.md ───────────────

step "Bump version in prodops/framework/README.md and README.en.md"

for readme in \
  "${ROOT_DIR}/prodops/framework/README.md" \
  "${ROOT_DIR}/prodops/framework/README.en.md"
do
  if [[ ! -f "${readme}" ]]; then
    warn "Not found: ${readme#"${ROOT_DIR}/"} — skipping"
    continue
  fi

  if [[ "${CURRENT_VERSION_BARE}" != "UNKNOWN" ]]; then
    bump_version "${readme}" "${CURRENT_VERSION_BARE}" "${VERSION_BARE}"
  else
    # Replace any vX.Y.Z that isn't already the target version
    while IFS= read -r old_ver; do
      [[ "${old_ver#v}" == "${VERSION_BARE}" ]] && continue
      bump_version "${readme}" "${old_ver#v}" "${VERSION_BARE}"
    done < <(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "${readme}" | sort -u || true)
  fi
done

# ── Step 4: Bump version in install-prodops.sh usage example ─────────────────

step "Bump version in prodops/scripts/install-prodops.sh usage example"

INSTALL_SCRIPT="${ROOT_DIR}/prodops/scripts/install-prodops.sh"

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  warn "install-prodops.sh not found — skipping"
else
  if [[ "${CURRENT_VERSION_BARE}" != "UNKNOWN" ]]; then
    bump_version "${INSTALL_SCRIPT}" "${CURRENT_VERSION_BARE}" "${VERSION_BARE}"
  else
    while IFS= read -r old_ver; do
      [[ "${old_ver#v}" == "${VERSION_BARE}" ]] && continue
      bump_version "${INSTALL_SCRIPT}" "${old_ver#v}" "${VERSION_BARE}"
    done < <(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "${INSTALL_SCRIPT}" | sort -u || true)
  fi
fi

# ── Step 5: Bump version in root README.md (if exists) ───────────────────────

step "Bump version in root README.md and README.en.md (if present)"

for root_readme in \
  "${ROOT_DIR}/README.md" \
  "${ROOT_DIR}/README.en.md"
do
  if [[ ! -f "${root_readme}" ]]; then
    warn "Not found: ${root_readme#"${ROOT_DIR}/"} — skipping"
    continue
  fi

  if [[ "${CURRENT_VERSION_BARE}" != "UNKNOWN" ]]; then
    bump_version "${root_readme}" "${CURRENT_VERSION_BARE}" "${VERSION_BARE}"
  else
    while IFS= read -r old_ver; do
      [[ "${old_ver#v}" == "${VERSION_BARE}" ]] && continue
      bump_version "${root_readme}" "${old_ver#v}" "${VERSION_BARE}"
    done < <(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "${root_readme}" | sort -u || true)
  fi
done

# ── Step 6: Bump version in framework-lock.yaml ───────────────────────────────

step "Update prodops/exec/framework-lock.yaml to ${VERSION}"

LOCK_FILE="${ROOT_DIR}/prodops/exec/framework-lock.yaml"

if [[ ! -f "${LOCK_FILE}" ]]; then
  warn "framework-lock.yaml not found — skipping"
elif [[ "${DRY_RUN}" == "true" ]]; then
  dry "Would update version fields in prodops/exec/framework-lock.yaml"
else
  TODAY=$(date +%Y-%m-%d)
  sed -i '' \
    -e "s/version: \"[^\"]*\"/version: \"${VERSION}\"/" \
    -e "s/installed_version: \"[^\"]*\"/installed_version: \"${VERSION}\"/" \
    -e "s/available_version: \"[^\"]*\"/available_version: \"${VERSION}\"/" \
    -e "s/last_checked: \"[^\"]*\"/last_checked: \"${TODAY}\"/" \
    "${LOCK_FILE}"
  ok "Updated framework-lock.yaml → version: ${VERSION}, last_checked: ${TODAY}"
fi

# ── Step 6b: Bump framework-version in runtime.yaml ─────────────────────────

step "Update prodops/runtime/runtime.yaml framework-version to ${VERSION}"

RUNTIME_YAML="${ROOT_DIR}/prodops/runtime/runtime.yaml"

_bump_framework_version() {
  local path="$1" ver="$2"
  python3 - "${path}" "${ver}" <<'PYEOF' 2>/dev/null
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
}

if [[ ! -f "${RUNTIME_YAML}" ]]; then
  warn "runtime.yaml not found — skipping"
elif [[ "${DRY_RUN}" == "true" ]]; then
  dry "Would update framework-version in prodops/runtime/runtime.yaml → ${VERSION}"
else
  if _bump_framework_version "${RUNTIME_YAML}" "${VERSION}"; then
    ok "Updated runtime.yaml framework-version → ${VERSION}"
  else
    warn "Could not update runtime.yaml automatically — update framework-version manually"
  fi
fi

# ── Step 6c: Bump framework-version in runtime.yaml.example ──────────────────

step "Update prodops/runtime/runtime.yaml.example framework-version to ${VERSION}"

RUNTIME_EXAMPLE="${ROOT_DIR}/prodops/runtime/runtime.yaml.example"

if [[ ! -f "${RUNTIME_EXAMPLE}" ]]; then
  warn "runtime.yaml.example not found — skipping"
elif [[ "${DRY_RUN}" == "true" ]]; then
  dry "Would update framework-version in prodops/runtime/runtime.yaml.example → ${VERSION}"
else
  if _bump_framework_version "${RUNTIME_EXAMPLE}" "${VERSION}"; then
    ok "Updated runtime.yaml.example framework-version → ${VERSION}"
  else
    warn "Could not update runtime.yaml.example automatically — update framework-version manually"
  fi
fi

# ── Step 6d: Bump PRODOPS_VERSION in setup-wsl.sh and setup-mac.sh ───────────

step "Update PRODOPS_VERSION in setup-wsl.sh and setup-mac.sh to ${VERSION}"

for _setup_script in \
  "${ROOT_DIR}/prodops/scripts/setup-wsl.sh" \
  "${ROOT_DIR}/prodops/scripts/setup-mac.sh"; do

  _script_name="$(basename "${_setup_script}")"

  if [[ ! -f "${_setup_script}" ]]; then
    warn "${_script_name} not found — skipping"
    continue
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    dry "Would update PRODOPS_VERSION and header comment in ${_script_name} → ${VERSION}"
    continue
  fi

  if python3 - "${_setup_script}" "${VERSION}" <<'PYEOF' 2>/dev/null; then
import sys, re
path, version = sys.argv[1], sys.argv[2]
content = open(path).read()
# Update variable assignment: PRODOPS_VERSION="vX.Y.Z"
content = re.sub(
    r'(PRODOPS_VERSION=)["\'].*?["\']',
    r'\g<1>"' + version + '"',
    content,
)
# Update comment header: # ProdOps Framework vX.Y.Z
content = re.sub(
    r'(# ProdOps Framework )v[\d.]+',
    r'\g<1>' + version,
    content,
)
open(path, 'w').write(content)
PYEOF
    ok "Updated ${_script_name}: PRODOPS_VERSION → ${VERSION}"
  else
    warn "Could not update ${_script_name} automatically — update PRODOPS_VERSION manually"
  fi
done

# ── Step 7: Print checklist for framework repo root READMEs ──────────────────

step "Checklist for prodops-framework repo (manual or post-export)"

printf '\n  The following files in the framework repo root are NOT part of the export\n'
printf '  manifest and must be updated manually after pushing:\n\n'
printf '    %sREADME.md%s   — bump version references to %s\n' "${BOLD}" "${RESET}" "${VERSION}"
printf '    %sREADME.en.md%s — bump version references to %s\n' "${BOLD}" "${RESET}" "${VERSION}"
printf '\n  If the framework repo clone is at /tmp/prodops-framework-latest:\n'
printf '    sed -i '"'"'' "s/v[0-9]*\.[0-9]*\.[0-9]*/${VERSION}/g" "' \\\n"
printf '      /tmp/prodops-framework-latest/README.md \\\n'
printf '      /tmp/prodops-framework-latest/README.en.md\n'
printf '    git -C /tmp/prodops-framework-latest add README.md README.en.md\n'
printf '    git -C /tmp/prodops-framework-latest commit -m "chore: bump version to %s in READMEs"\n' "${VERSION}"
printf '    git -C /tmp/prodops-framework-latest push origin master\n'

# ── Step 8: Export dry-run ────────────────────────────────────────────────────

step "Validate export manifest (dry run)"

EXPORT_SCRIPT="${ROOT_DIR}/prodops/scripts/export-framework.sh"

if [[ ! -f "${EXPORT_SCRIPT}" ]]; then
  warn "export-framework.sh not found — skipping dry-run validation"
elif [[ "${DRY_RUN}" == "true" ]]; then
  dry "Would run: EXPORT_DRY_RUN=1 bash prodops/scripts/export-framework.sh"
else
  printf '\n'
  EXPORT_OUT=$(EXPORT_DRY_RUN=1 bash "${EXPORT_SCRIPT}" 2>&1) || true
  FILE_COUNT=$(printf '%s\n' "${EXPORT_OUT}" | grep 'Total:' | grep -o '[0-9]\+' | head -1 || true)
  if printf '%s\n' "${EXPORT_OUT}" | grep -q 'Manifest validation passed'; then
    ok "Export manifest valid — ${FILE_COUNT} file(s) would be exported"
  else
    fail "Export manifest validation failed — fix before running export-framework.sh"
    printf '%s\n' "${EXPORT_OUT}" | grep -i 'error\|fail' | sed 's/^/    /' >&2
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

printf '\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${BOLD}" "${RESET}"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  printf '%sRelease preparation FAILED — fix the issues below before exporting:%s\n' "${RED}${BOLD}" "${RESET}"
  for e in "${ERRORS[@]}"; do
    printf '  ✗ %s\n' "${e}"
  done
  printf '\n'
  exit 1
fi

printf '%sRelease %s ready for export%s\n' "${BOLD}${GREEN}" "${VERSION}" "${RESET}"
printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${BOLD}" "${RESET}"
printf '\n%sNext steps:%s\n' "${BOLD}" "${RESET}"
printf '  1. Review the file changes above (git diff)\n'
printf '  2. Update framework repo root READMEs (see checklist in Step 7 above)\n'
printf '  3. EXPORT_DIRECT_PUSH=1 bash prodops/scripts/export-framework.sh\n'
printf '  4. git -C /tmp/prodops-framework-latest tag %s\n' "${VERSION}"
printf '  5. git -C /tmp/prodops-framework-latest push origin %s\n' "${VERSION}"
printf '  6. gh release create %s --repo produtoreativo/prodops-framework --title "%s" --notes-from-tag\n' "${VERSION}" "${VERSION}"
printf '\n'
