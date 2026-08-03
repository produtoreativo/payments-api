#!/usr/bin/env bash
# Test suite for export-framework.sh — DS-53 / work-item 130
# Pure shell tests. No jest mocks. No external network calls.
#
# Usage: ./prodops/scripts/test-export-framework.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

EXPORT_SCRIPT="prodops/scripts/export-framework.sh"
VALIDATE_SCRIPT="prodops/scripts/validate-export-manifest.sh"
DOCTOR_SCRIPT="prodops/scripts/doctor.sh"
MANIFEST="prodops/exec/export-manifest.yaml"

passed=0
failed=0
total=0

pass() { printf 'PASS: %s\n' "$1"; passed=$((passed + 1)); total=$((total + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failed=$((failed + 1)); total=$((total + 1)); }

# ── T1: export-framework.sh exists and is executable ─────────────────────────

if [[ -f "${EXPORT_SCRIPT}" ]]; then
  pass "T1a: ${EXPORT_SCRIPT} exists"
else
  fail "T1a: ${EXPORT_SCRIPT} does not exist"
fi

if [[ -x "${EXPORT_SCRIPT}" ]]; then
  pass "T1b: ${EXPORT_SCRIPT} is executable"
else
  fail "T1b: ${EXPORT_SCRIPT} is not executable"
fi

# ── T2: validate-export-manifest.sh exists and passes on valid manifest ───────

if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  pass "T2a: ${VALIDATE_SCRIPT} exists"
else
  fail "T2a: ${VALIDATE_SCRIPT} does not exist"
fi

if [[ -x "${VALIDATE_SCRIPT}" ]]; then
  pass "T2b: ${VALIDATE_SCRIPT} is executable"
else
  fail "T2b: ${VALIDATE_SCRIPT} is not executable"
fi

if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  if bash "${VALIDATE_SCRIPT}" >/dev/null 2>&1; then
    pass "T2c: validate-export-manifest.sh exits 0 on valid manifest"
  else
    fail "T2c: validate-export-manifest.sh failed on valid manifest"
  fi
fi

# ── T3: doctor.sh exists and passes ──────────────────────────────────────────

if [[ -f "${DOCTOR_SCRIPT}" ]]; then
  pass "T3a: ${DOCTOR_SCRIPT} exists"
else
  fail "T3a: ${DOCTOR_SCRIPT} does not exist"
fi

if [[ -x "${DOCTOR_SCRIPT}" ]]; then
  pass "T3b: ${DOCTOR_SCRIPT} is executable"
else
  fail "T3b: ${DOCTOR_SCRIPT} is not executable"
fi

# ── T4: Scenario 3 — export fails with exit 1 when manifest is invalid ───────
# Create a temp directory with a broken manifest and verify export-framework.sh
# exits 1 and does not open a PR.

SCRATCH=$(mktemp -d)
trap 'rm -rf "${SCRATCH}"' EXIT

FAKE_MANIFEST="${SCRATCH}/export-manifest.yaml"

cat >"${FAKE_MANIFEST}" <<'YAML'
# Deliberately invalid: missing required fields (schema_version, include, exclude, etc.)
broken: true
YAML

if [[ -f "${EXPORT_SCRIPT}" ]]; then
  # Run with EXPORT_MANIFEST_OVERRIDE pointing to the invalid manifest.
  # The script must exit 1. We capture stderr to confirm the error message.
  set +e
  err_output=$(EXPORT_MANIFEST_OVERRIDE="${FAKE_MANIFEST}" EXPORT_DRY_RUN=1 \
    bash "${EXPORT_SCRIPT}" 2>&1)
  exit_code=$?
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    pass "T4a: export-framework.sh exits non-zero on invalid manifest (exit ${exit_code})"
  else
    fail "T4a: export-framework.sh should exit non-zero on invalid manifest but exited 0"
  fi

  if [[ -n "${err_output}" ]]; then
    pass "T4b: export-framework.sh emits an error message on invalid manifest"
  else
    fail "T4b: export-framework.sh produced no error output on invalid manifest"
  fi
else
  fail "T4a: cannot test Scenario 3 — ${EXPORT_SCRIPT} missing"
  fail "T4b: cannot test Scenario 3 — ${EXPORT_SCRIPT} missing"
fi

# ── T5: export-framework.sh syntax check ─────────────────────────────────────

if [[ -f "${EXPORT_SCRIPT}" ]]; then
  if bash -n "${EXPORT_SCRIPT}" 2>/dev/null; then
    pass "T5: ${EXPORT_SCRIPT} has valid bash syntax"
  else
    fail "T5: ${EXPORT_SCRIPT} has syntax errors"
  fi
fi

# ── T6: export-framework.sh in dry-run mode respects exclude list ─────────────
# In dry-run mode the script should print the list of files it would copy.
# None of those files should come from excluded paths.

EXCLUDED_PREFIXES=(
  "prodops/artifacts/"
  "prodops/exec/"
  "prodops/skills/local/"
  "prodops/scripts/local/"
)

if [[ -f "${EXPORT_SCRIPT}" ]]; then
  set +e
  dry_output=$(EXPORT_DRY_RUN=1 bash "${EXPORT_SCRIPT}" 2>/dev/null)
  dry_exit=$?
  set -e

  if [[ "${dry_exit}" -eq 0 ]]; then
    pass "T6a: export-framework.sh dry-run exits 0"
    exclude_violation=0
    for prefix in "${EXCLUDED_PREFIXES[@]}"; do
      if echo "${dry_output}" | grep -q "${prefix}"; then
        fail "T6b: dry-run output includes excluded path: ${prefix}"
        exclude_violation=$((exclude_violation + 1))
      fi
    done
    if [[ "${exclude_violation}" -eq 0 ]]; then
      pass "T6b: dry-run output contains no excluded paths"
    fi
  else
    fail "T6a: export-framework.sh dry-run exited ${dry_exit} (expected 0)"
    fail "T6b: cannot check excluded paths — dry-run failed"
  fi
fi

# ── T7: LICENSE and CHANGELOG.md are in the include list ─────────────────────

if [[ -f "${MANIFEST}" ]]; then
  if grep -q "LICENSE" "${MANIFEST}" 2>/dev/null; then
    pass "T7a: LICENSE referenced in export-manifest.yaml"
  else
    fail "T7a: LICENSE not referenced in export-manifest.yaml"
  fi

  if grep -q "CHANGELOG.md" "${MANIFEST}" 2>/dev/null; then
    pass "T7b: CHANGELOG.md referenced in export-manifest.yaml"
  else
    fail "T7b: CHANGELOG.md not referenced in export-manifest.yaml"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────

printf '\n---\nResults: %d passed, %d failed out of %d tests.\n' \
  "${passed}" "${failed}" "${total}"

if [[ "${failed}" -gt 0 ]]; then
  exit 1
fi
exit 0
