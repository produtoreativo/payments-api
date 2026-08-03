#!/usr/bin/env bash
# Test suite for install-prodops.sh — DS-54 / work-item 131
# Pure shell tests. Covers BDD scenarios for prodops-framework-install.feature.
#
# Usage: ./prodops/scripts/test-install-prodops.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

INSTALL_SCRIPT="prodops/scripts/install-prodops.sh"

passed=0
failed=0
total=0

pass() { printf 'PASS: %s\n' "$1"; passed=$((passed + 1)); total=$((total + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failed=$((failed + 1)); total=$((total + 1)); }
skip() { printf 'SKIP: %s\n' "$1"; total=$((total + 1)); }

# ── T1: install-prodops.sh exists and is executable ──────────────────────────

if [[ -f "${INSTALL_SCRIPT}" ]]; then
  pass "T1a: ${INSTALL_SCRIPT} exists"
else
  fail "T1a: ${INSTALL_SCRIPT} does not exist"
fi

if [[ -x "${INSTALL_SCRIPT}" ]]; then
  pass "T1b: ${INSTALL_SCRIPT} is executable"
else
  fail "T1b: ${INSTALL_SCRIPT} is not executable"
fi

# ── T2: Missing --version parameter exits 1 ──────────────────────────────────
# BDD: Scenario — Instalação falha se --version ausente
# No network call needed — pure argument validation.

if [[ -f "${INSTALL_SCRIPT}" ]]; then
  set +e
  err_output=$(bash "${INSTALL_SCRIPT}" 2>&1)
  exit_code=$?
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    pass "T2a: missing --version exits non-zero (exit ${exit_code})"
  else
    fail "T2a: missing --version should exit non-zero but exited 0"
  fi

  if [[ -n "${err_output}" ]]; then
    pass "T2b: missing --version emits error message"
  else
    fail "T2b: missing --version produced no error output"
  fi

  # Must contain helpful indication about --version
  if echo "${err_output}" | grep -qi "version"; then
    pass "T2c: error message mentions version"
  else
    fail "T2c: error message does not mention version"
  fi
else
  fail "T2a: cannot test — ${INSTALL_SCRIPT} missing"
  fail "T2b: cannot test — ${INSTALL_SCRIPT} missing"
  fail "T2c: cannot test — ${INSTALL_SCRIPT} missing"
fi

# ── T3: Invalid/nonexistent version exits 1, creates no files ────────────────
# BDD Scenario: "Instalação falha se prodops-framework não tem a versão solicitada"
# Uses version v9.9.9 which does not exist.
# Requires gh CLI to be available (skipped if not).

SCRATCH=$(mktemp -d)
trap 'rm -rf "${SCRATCH}"' EXIT

if ! command -v gh >/dev/null 2>&1; then
  skip "T3a: gh CLI not available — skipping invalid-version test"
  skip "T3b: gh CLI not available — skipping invalid-version test"
  skip "T3c: gh CLI not available — skipping invalid-version test"
elif [[ -f "${INSTALL_SCRIPT}" ]]; then
  set +e
  err_output=$(bash "${INSTALL_SCRIPT}" --version v9.9.9 --target "${SCRATCH}" 2>&1)
  exit_code=$?
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    pass "T3a: invalid version exits non-zero (exit ${exit_code})"
  else
    fail "T3a: invalid version should exit non-zero but exited 0"
  fi

  if [[ -n "${err_output}" ]]; then
    pass "T3b: invalid version emits an error message"
  else
    fail "T3b: invalid version produced no error output"
  fi

  # Verify no files were created in the target directory
  file_count=$(find "${SCRATCH}" -mindepth 1 | wc -l | tr -d ' ')
  if [[ "${file_count}" -eq 0 ]]; then
    pass "T3c: invalid version creates no files in target directory"
  else
    fail "T3c: invalid version created ${file_count} file(s) in target directory (expected 0)"
  fi
else
  fail "T3a: cannot test — ${INSTALL_SCRIPT} missing"
  fail "T3b: cannot test — ${INSTALL_SCRIPT} missing"
  fail "T3c: cannot test — ${INSTALL_SCRIPT} missing"
fi

# ── T4: install-prodops.sh bash syntax check ─────────────────────────────────

if [[ -f "${INSTALL_SCRIPT}" ]]; then
  if bash -n "${INSTALL_SCRIPT}" 2>/dev/null; then
    pass "T4: ${INSTALL_SCRIPT} has valid bash syntax"
  else
    fail "T4: ${INSTALL_SCRIPT} has syntax errors"
  fi
fi

# ── T5: framework-lock.yaml fields (structural verification from BDD Scenario 2) ─
# We verify the install script would generate a lock file with correct fields
# by inspecting the script source for the required field names.
# Full integration test requires a live framework repo.

REQUIRED_FIELDS=("status: consumer" "external_source" "synchronization_mechanism: ci-pr-sync" "state: installed" "drift:" "status: ok")

if [[ -f "${INSTALL_SCRIPT}" ]]; then
  all_present=1
  for field in "${REQUIRED_FIELDS[@]}"; do
    if grep -q "${field}" "${INSTALL_SCRIPT}"; then
      : # field present in script
    else
      fail "T5: install script missing framework-lock.yaml field: ${field}"
      all_present=0
    fi
  done
  if [[ "${all_present}" -eq 1 ]]; then
    pass "T5: install script contains all required framework-lock.yaml fields"
  fi
fi

# ── T6: .prodopsignore protection paths in script ────────────────────────────

PROTECTED_PATHS=("prodops/artifacts/" "prodops/exec/manifest.yaml" "prodops/skills/local/")

if [[ -f "${INSTALL_SCRIPT}" ]]; then
  all_present=1
  for path in "${PROTECTED_PATHS[@]}"; do
    if grep -q "${path}" "${INSTALL_SCRIPT}"; then
      : # path present in script
    else
      fail "T6: install script missing protection for: ${path}"
      all_present=0
    fi
  done
  if [[ "${all_present}" -eq 1 ]]; then
    pass "T6: install script references all required protected paths"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────

printf '\n---\nResults: %d passed, %d failed out of %d tests.\n' \
  "${passed}" "${failed}" "${total}"

if [[ "${failed}" -gt 0 ]]; then
  exit 1
fi
exit 0
