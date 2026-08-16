#!/usr/bin/env bash
# Validates the declarative export boundary for prodops-framework extraction.
# Does not copy files, does not modify git state, does not access the network.
#
# Usage: ./prodops/scripts/validate-export-manifest.sh
# Exit 0 = all checks pass; exit 1 = one or more checks failed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

failures=0

fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }
pass() { printf 'PASS: %s\n' "$1"; }
skip() { printf 'SKIP: %s\n' "$1" >&2; }

MANIFEST="prodops/exec/export-manifest.yaml"

check_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    pass "exists ${path}"
  else
    fail "missing ${path}"
  fi
}

# ── File existence ─────────────────────────────────────────────────────────────

check_path "${MANIFEST}"
check_path "prodops/exec/export-boundary.md"
check_path "prodops/exec/export-boundary.en.md"

# ── YAML validity ─────────────────────────────────────────────────────────────

if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import yaml" 2>/dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('${MANIFEST}'))" 2>/dev/null; then
      pass "export-manifest.yaml YAML valid"
    else
      fail "export-manifest.yaml YAML invalid"
    fi
  else
    skip "PyYAML not installed — YAML validation skipped (install pyyaml for full validation)"
  fi
else
  skip "python3 not available — YAML validation skipped"
fi

# ── Required includes ─────────────────────────────────────────────────────────

for include in "framework/**" "skills/**" "templates/**"; do
  if grep -qF "${include}" "${MANIFEST}" 2>/dev/null; then
    pass "include present: ${include}"
  else
    fail "include missing: ${include}"
  fi
done

# ── Required excludes ─────────────────────────────────────────────────────────

for exclude in "skills/local/**" "skills/references/local/**" "templates/local/**" \
               "scripts/local/**" "artifacts/**" "exec/**"; do
  if grep -qF "${exclude}" "${MANIFEST}" 2>/dev/null; then
    pass "exclude present: ${exclude}"
  else
    fail "exclude missing: ${exclude}"
  fi
done

# ── Canonical scripts included ────────────────────────────────────────────────

for script in "scripts/doctor.sh" "scripts/validate-manifest.sh" "scripts/check-env.sh" "scripts/setup-wsl.sh" "scripts/setup-mac.sh" "scripts/framework-repo/AGENTS.md" "scripts/framework-repo/CLAUDE.md"; do
  if grep -qF "${script}" "${MANIFEST}" 2>/dev/null; then
    pass "canonical script included: ${script}"
  else
    fail "canonical script not included: ${script}"
  fi
done

# ── Framework repo root files present ────────────────────────────────────────

for root_file in "prodops/scripts/framework-repo/AGENTS.md" "prodops/scripts/framework-repo/CLAUDE.md"; do
  check_path "${root_file}"
done

# ── PRODOPS_VERSION in scripts must match framework-lock.yaml ─────────────────
# This gate enforces the rule: runtime version always tracks framework version.

LOCK_FILE="prodops/exec/framework-lock.yaml"
if [[ -f "${LOCK_FILE}" ]] && command -v python3 >/dev/null 2>&1; then
  LOCK_VERSION=$(python3 -c "
import sys, re
content = open('${LOCK_FILE}').read()
m = re.search(r'^\s*version:\s*[\"\'](.*?)[\"\']', content, re.M)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
  if [[ -n "${LOCK_VERSION}" ]]; then
    for script in "prodops/scripts/setup-wsl.sh" "prodops/scripts/setup-mac.sh"; do
      if [[ -f "${script}" ]]; then
        SCRIPT_VERSION=$(python3 -c "
import sys, re
content = open('${script}').read()
m = re.search(r'PRODOPS_VERSION=[\"\'](.*?)[\"\']', content)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
        if [[ "${SCRIPT_VERSION}" == "${LOCK_VERSION}" ]]; then
          pass "PRODOPS_VERSION matches in $(basename "${script}"): ${SCRIPT_VERSION}"
        else
          fail "PRODOPS_VERSION mismatch in $(basename "${script}"): expected ${LOCK_VERSION}, got '${SCRIPT_VERSION}'"
        fi
      else
        fail "Script not found for version check: ${script}"
      fi
    done

    # runtime.yaml.example must also carry the current framework version
    RUNTIME_EXAMPLE="prodops/runtime/runtime.yaml.example"
    if [[ -f "${RUNTIME_EXAMPLE}" ]]; then
      RUNTIME_VERSION=$(python3 -c "
import sys, re
content = open('${RUNTIME_EXAMPLE}').read()
m = re.search(r'framework-version:\s*[\"\'](.*?)[\"\']', content)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
      if [[ "${RUNTIME_VERSION}" == "${LOCK_VERSION}" ]]; then
        pass "framework-version matches in runtime.yaml.example: ${RUNTIME_VERSION}"
      else
        fail "framework-version mismatch in runtime.yaml.example: expected ${LOCK_VERSION}, got '${RUNTIME_VERSION}'"
      fi
    else
      fail "runtime.yaml.example not found — cannot verify framework-version"
    fi
  else
    skip "Could not read version from framework-lock.yaml — version sync check skipped"
  fi
else
  skip "framework-lock.yaml or python3 not available — version sync check skipped"
fi

# ── Exportable root directories exist ────────────────────────────────────────

for root in prodops/framework prodops/skills prodops/templates; do
  check_path "${root}"
done

# ── Consumer-owned paths declared in conventions ──────────────────────────────

for consumer_path in "artifacts/" "skills/local/" "skills/references/local/" \
                     "templates/local/" "scripts/local/"; do
  if grep -qF "${consumer_path}" "${MANIFEST}" 2>/dev/null; then
    pass "consumer-owned path declared: ${consumer_path}"
  else
    fail "consumer-owned path not declared in conventions: ${consumer_path}"
  fi
done

# ── Installation state declared ───────────────────────────────────────────────

for install_file in "exec/manifest.yaml" "exec/framework-lock.yaml"; do
  if grep -qF "${install_file}" "${MANIFEST}" 2>/dev/null; then
    pass "installation-state file declared: ${install_file}"
  else
    fail "installation-state file not declared: ${install_file}"
  fi
done

# ── schema_version present ────────────────────────────────────────────────────

if grep -q "^schema_version:" "${MANIFEST}" 2>/dev/null; then
  pass "schema_version declared"
else
  fail "schema_version missing from export-manifest.yaml"
fi

# ── source.repository_role declared ──────────────────────────────────────────

if grep -q "repository_role:" "${MANIFEST}" 2>/dev/null; then
  pass "source.repository_role declared"
else
  fail "source.repository_role missing from export-manifest.yaml"
fi

# ── Result ────────────────────────────────────────────────────────────────────

if [[ "${failures}" -gt 0 ]]; then
  printf '\nExport manifest validation failed with %s issue(s).\n' "${failures}" >&2
  exit 1
fi

printf '\nExport manifest validation passed.\n'
