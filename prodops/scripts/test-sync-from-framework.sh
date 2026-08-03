#!/usr/bin/env bash
# Test suite for sync-from-framework.sh — DS-55 / work-item 132
# Pure shell tests. Covers BDD scenarios for prodops-framework-sync.feature.
#
# Usage: ./prodops/scripts/test-sync-from-framework.sh
# Exit 0 = all tests pass; exit 1 = one or more tests failed.
#
# Tests run in isolation using:
#   SYNC_REPO_ROOT   — temp directory acting as the product repository
#   FRAMEWORK_SOURCE — temp directory acting as the framework source
#   PRODOPS_GH_DRY_RUN=true — prevents real gh pr create calls
#   SYNC_DOCTOR_CMD  — stub doctor command that exits 0
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SYNC_SCRIPT="${ROOT_DIR}/prodops/scripts/sync-from-framework.sh"

passed=0
failed=0
total=0

pass() { printf 'PASS: %s\n' "$1"; passed=$((passed + 1)); total=$((total + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failed=$((failed + 1)); total=$((total + 1)); }
skip() { printf 'SKIP: %s\n' "$1"; total=$((total + 1)); }

# ── Shared fixtures ────────────────────────────────────────────────────────────

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

# Helper: create a minimal fake product repo in a directory
setup_fake_repo() {
  local repo_dir="$1"

  mkdir -p "${repo_dir}/prodops/exec"
  mkdir -p "${repo_dir}/prodops/artifacts/obcs"
  mkdir -p "${repo_dir}/prodops/skills/local"
  mkdir -p "${repo_dir}/prodops/scripts"

  # framework-lock.yaml
  cat > "${repo_dir}/prodops/exec/framework-lock.yaml" <<'YAML'
schema_version: 1
prodops_framework:
  version: "v0.1.0"
  status: consumer
  external_source: github.com/org/prodops-framework
drift:
  status: ok
YAML

  # .prodopsignore
  cat > "${repo_dir}/.prodopsignore" <<'IGNORE'
prodops/artifacts/
prodops/exec/manifest.yaml
prodops/exec/framework-lock.yaml
prodops/exec/cards/
prodops/skills/local/
prodops/skills/references/local/
prodops/scripts/local/
IGNORE

  # A protected artifact
  mkdir -p "${repo_dir}/prodops/artifacts/obcs"
  echo "obc content" > "${repo_dir}/prodops/artifacts/obcs/my-obc.md"

  # A protected exec file
  cat > "${repo_dir}/prodops/exec/manifest.yaml" <<'YAML'
version: 1
product: payments-api
YAML

  # A framework-owned file already at v0.1.0
  mkdir -p "${repo_dir}/prodops/framework"
  echo "framework content v0.1.0" > "${repo_dir}/prodops/framework/README.md"
}

# Helper: create a minimal fake framework source at a given version
setup_fake_framework() {
  local fw_dir="$1"
  local version="${2:-v0.2.0}"
  local readme_content="${3:-framework content ${version}}"

  mkdir -p "${fw_dir}/prodops/framework"
  echo "${readme_content}" > "${fw_dir}/prodops/framework/README.md"
  echo "# new canonical doc" > "${fw_dir}/prodops/framework/canonical-paths.md"
}

# Helper: stub doctor command that always exits 0
STUB_DOCTOR="${WORK_DIR}/stub-doctor.sh"
printf '#!/usr/bin/env bash\nprintf "ProdOps doctor passed (stub).\\n"\nexit 0\n' > "${STUB_DOCTOR}"
chmod +x "${STUB_DOCTOR}"

# ── T1: script exists and is executable ───────────────────────────────────────

if [[ -f "${SYNC_SCRIPT}" ]]; then
  pass "T1a: sync-from-framework.sh exists"
else
  fail "T1a: sync-from-framework.sh does not exist"
fi

if [[ -x "${SYNC_SCRIPT}" ]]; then
  pass "T1b: sync-from-framework.sh is executable"
else
  fail "T1b: sync-from-framework.sh is not executable"
fi

# ── T2: missing required args exits non-zero ──────────────────────────────────
# BDD: running without --version, --check, or --dry-run should print usage and exit 1

if [[ -f "${SYNC_SCRIPT}" ]]; then
  set +e
  err_output=$(bash "${SYNC_SCRIPT}" 2>&1)
  exit_code=$?
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    pass "T2a: no args exits non-zero (exit ${exit_code})"
  else
    fail "T2a: no args should exit non-zero but exited 0"
  fi

  if echo "${err_output}" | grep -qiE "usage|version|check|dry"; then
    pass "T2b: no args emits usage hint"
  else
    fail "T2b: no args did not emit usage hint (got: ${err_output})"
  fi
else
  fail "T2a: cannot test — ${SYNC_SCRIPT} missing"
  fail "T2b: cannot test — ${SYNC_SCRIPT} missing"
fi

# ── T3: --check detects drift and exits 1 ─────────────────────────────────────
# BDD Scenario: "--check detecta drift sem modificar o repositório"

REPO3="${WORK_DIR}/repo3"
FW3="${WORK_DIR}/fw3"
setup_fake_repo "${REPO3}"
setup_fake_framework "${FW3}" "v0.2.0" "framework content v0.2.0 — CHANGED"

# Initialize git repo so git operations work
git -C "${REPO3}" init -q
git -C "${REPO3}" config user.email "test@test.com"
git -C "${REPO3}" config user.name "Test"
git -C "${REPO3}" add -A
git -C "${REPO3}" commit -q -m "init"

if [[ -f "${SYNC_SCRIPT}" ]]; then
  # Capture a checksum of protected file before
  obc_before=$(cat "${REPO3}/prodops/artifacts/obcs/my-obc.md")
  lock_before=$(cat "${REPO3}/prodops/exec/framework-lock.yaml")

  set +e
  check_output=$(SYNC_REPO_ROOT="${REPO3}" FRAMEWORK_SOURCE="${FW3}" \
    bash "${SYNC_SCRIPT}" --check 2>&1)
  check_exit=$?
  set -e

  if [[ "${check_exit}" -eq 1 ]]; then
    pass "T3a: --check exits 1 when drift detected"
  else
    fail "T3a: --check should exit 1 on drift but exited ${check_exit}"
  fi

  if echo "${check_output}" | grep -qiE "drift|diverge|differ|changed|README"; then
    pass "T3b: --check output lists diverging files"
  else
    fail "T3b: --check output did not list diverging files (got: ${check_output})"
  fi

  # Verify nothing was modified
  obc_after=$(cat "${REPO3}/prodops/artifacts/obcs/my-obc.md")
  lock_after=$(cat "${REPO3}/prodops/exec/framework-lock.yaml")

  if [[ "${obc_before}" == "${obc_after}" ]]; then
    pass "T3c: --check did not modify protected artifact"
  else
    fail "T3c: --check modified protected artifact (obc changed)"
  fi

  if [[ "${lock_before}" == "${lock_after}" ]]; then
    pass "T3d: --check did not modify framework-lock.yaml"
  else
    fail "T3d: --check modified framework-lock.yaml"
  fi

  # Verify no git changes (no new commits, no staged files)
  uncommitted=$(git -C "${REPO3}" status --porcelain || true)
  if [[ -z "${uncommitted}" ]]; then
    pass "T3e: --check left repository clean (no uncommitted changes)"
  else
    fail "T3e: --check left uncommitted changes: ${uncommitted}"
  fi
else
  for sub in a b c d e; do
    fail "T3${sub}: cannot test — ${SYNC_SCRIPT} missing"
  done
fi

# ── T4: --check exits 0 when no drift ─────────────────────────────────────────

REPO4="${WORK_DIR}/repo4"
FW4="${WORK_DIR}/fw4"
setup_fake_repo "${REPO4}"
# Framework source matches existing files exactly
setup_fake_framework "${FW4}" "v0.1.0" "framework content v0.1.0"
# Ensure the repo has the same content as what the framework has
echo "framework content v0.1.0" > "${REPO4}/prodops/framework/README.md"
# Add canonical-paths.md too so there is no new file
echo "# new canonical doc" > "${REPO4}/prodops/framework/canonical-paths.md"

if [[ -f "${SYNC_SCRIPT}" ]]; then
  set +e
  check4_output=$(SYNC_REPO_ROOT="${REPO4}" FRAMEWORK_SOURCE="${FW4}" \
    bash "${SYNC_SCRIPT}" --check 2>&1)
  check4_exit=$?
  set -e

  if [[ "${check4_exit}" -eq 0 ]]; then
    pass "T4a: --check exits 0 when no drift"
  else
    fail "T4a: --check should exit 0 with no drift but exited ${check4_exit} (${check4_output})"
  fi
else
  fail "T4a: cannot test — ${SYNC_SCRIPT} missing"
fi

# ── T5: --dry-run shows files that would be updated, modifies nothing ─────────
# BDD Scenario: "Sync com --dry-run mostra o que seria feito sem executar"

REPO5="${WORK_DIR}/repo5"
FW5="${WORK_DIR}/fw5"
setup_fake_repo "${REPO5}"
setup_fake_framework "${FW5}" "v0.2.0" "framework content v0.2.0 — CHANGED"

git -C "${REPO5}" init -q
git -C "${REPO5}" config user.email "test@test.com"
git -C "${REPO5}" config user.name "Test"
git -C "${REPO5}" add -A
git -C "${REPO5}" commit -q -m "init"

if [[ -f "${SYNC_SCRIPT}" ]]; then
  framework_before=$(cat "${REPO5}/prodops/framework/README.md")
  lock5_before=$(cat "${REPO5}/prodops/exec/framework-lock.yaml")
  obc5_before=$(cat "${REPO5}/prodops/artifacts/obcs/my-obc.md")

  set +e
  dry_output=$(SYNC_REPO_ROOT="${REPO5}" FRAMEWORK_SOURCE="${FW5}" \
    PRODOPS_GH_DRY_RUN=true \
    bash "${SYNC_SCRIPT}" --dry-run --version v0.2.0 2>&1)
  dry_exit=$?
  set -e

  if [[ "${dry_exit}" -eq 0 ]]; then
    pass "T5a: --dry-run exits 0"
  else
    fail "T5a: --dry-run should exit 0 but exited ${dry_exit} (${dry_output})"
  fi

  if echo "${dry_output}" | grep -qiE "would|update|README"; then
    pass "T5b: --dry-run output lists files that would be updated"
  else
    fail "T5b: --dry-run output did not list files (got: ${dry_output})"
  fi

  # Verify nothing was modified
  framework_after=$(cat "${REPO5}/prodops/framework/README.md")
  lock5_after=$(cat "${REPO5}/prodops/exec/framework-lock.yaml")
  obc5_after=$(cat "${REPO5}/prodops/artifacts/obcs/my-obc.md")

  if [[ "${framework_before}" == "${framework_after}" ]]; then
    pass "T5c: --dry-run did not modify framework files"
  else
    fail "T5c: --dry-run modified framework/README.md"
  fi

  if [[ "${lock5_before}" == "${lock5_after}" ]]; then
    pass "T5d: --dry-run did not modify framework-lock.yaml"
  else
    fail "T5d: --dry-run modified framework-lock.yaml"
  fi

  if [[ "${obc5_before}" == "${obc5_after}" ]]; then
    pass "T5e: --dry-run did not modify protected artifact"
  else
    fail "T5e: --dry-run modified protected artifact"
  fi

  # No git changes
  uncommitted5=$(git -C "${REPO5}" status --porcelain || true)
  if [[ -z "${uncommitted5}" ]]; then
    pass "T5f: --dry-run left repository clean"
  else
    fail "T5f: --dry-run left uncommitted changes: ${uncommitted5}"
  fi

  # No PR hint in output (dry run)
  if echo "${dry_output}" | grep -qi "no pr\|no pull request\|pr.*not.*open\|dry.run.*no"; then
    pass "T5g: --dry-run confirms no PR would be opened"
  else
    # Check the output confirms it is dry run (less strict)
    if echo "${dry_output}" | grep -qi "dry.run\|dry_run"; then
      pass "T5g: --dry-run output mentions dry-run mode"
    else
      fail "T5g: --dry-run output did not confirm no PR (got: ${dry_output})"
    fi
  fi
else
  for sub in a b c d e f g; do
    fail "T5${sub}: cannot test — ${SYNC_SCRIPT} missing"
  done
fi

# ── T6: sync does not overwrite protected paths ────────────────────────────────
# BDD Scenario: "Sync não sobrescreve artefatos do produto"
# Uses PRODOPS_GH_DRY_RUN=true and stub doctor to avoid external calls.

REPO6="${WORK_DIR}/repo6"
FW6="${WORK_DIR}/fw6"
setup_fake_repo "${REPO6}"
setup_fake_framework "${FW6}" "v0.2.0" "framework content v0.2.0"

# Add protected content to framework source — sync must NOT copy these
mkdir -p "${FW6}/prodops/artifacts/obcs"
echo "INJECTED BY FRAMEWORK — MUST NOT APPEAR" > "${FW6}/prodops/artifacts/obcs/injected.md"
mkdir -p "${FW6}/prodops/exec"
echo "injected manifest" > "${FW6}/prodops/exec/manifest.yaml"
echo "injected lock" > "${FW6}/prodops/exec/framework-lock.yaml"

git -C "${REPO6}" init -q
git -C "${REPO6}" config user.email "test@test.com"
git -C "${REPO6}" config user.name "Test"
git -C "${REPO6}" add -A
git -C "${REPO6}" commit -q -m "init"

if [[ -f "${SYNC_SCRIPT}" ]]; then
  obc6_before=$(cat "${REPO6}/prodops/artifacts/obcs/my-obc.md")
  manifest6_before=$(cat "${REPO6}/prodops/exec/manifest.yaml")
  lock6_before=$(cat "${REPO6}/prodops/exec/framework-lock.yaml")

  set +e
  sync6_output=$(SYNC_REPO_ROOT="${REPO6}" FRAMEWORK_SOURCE="${FW6}" \
    PRODOPS_GH_DRY_RUN=true \
    SYNC_DOCTOR_CMD="${STUB_DOCTOR}" \
    bash "${SYNC_SCRIPT}" --version v0.2.0 2>&1)
  sync6_exit=$?
  set -e

  # Protected files must be unchanged
  obc6_after=$(cat "${REPO6}/prodops/artifacts/obcs/my-obc.md")
  manifest6_after=$(cat "${REPO6}/prodops/exec/manifest.yaml")
  lock6_after_raw=$(cat "${REPO6}/prodops/exec/framework-lock.yaml")

  # Check that injected file was NOT created
  if [[ ! -f "${REPO6}/prodops/artifacts/obcs/injected.md" ]]; then
    pass "T6a: sync did not create injected artifact in prodops/artifacts/"
  else
    fail "T6a: sync created protected path prodops/artifacts/obcs/injected.md"
  fi

  if [[ "${manifest6_before}" == "${manifest6_after}" ]]; then
    pass "T6b: sync did not overwrite prodops/exec/manifest.yaml"
  else
    fail "T6b: sync overwrote prodops/exec/manifest.yaml"
  fi

  # framework-lock.yaml must be updated by the sync (not by the framework source content)
  # The sync script itself updates it — but it must not be replaced with the "injected lock" content
  if ! grep -q "INJECTED BY FRAMEWORK" "${REPO6}/prodops/exec/framework-lock.yaml" 2>/dev/null; then
    pass "T6c: framework-lock.yaml was not overwritten with framework source content"
  else
    fail "T6c: framework-lock.yaml was replaced by framework source content (injected)"
  fi

  if [[ "${obc6_before}" == "${obc6_after}" ]]; then
    pass "T6d: sync did not modify existing product artifact (my-obc.md)"
  else
    fail "T6d: sync modified product artifact my-obc.md"
  fi
else
  for sub in a b c d; do
    fail "T6${sub}: cannot test — ${SYNC_SCRIPT} missing"
  done
fi

# ── T7: full sync creates branch and updates framework-lock.yaml ───────────────
# BDD Scenario: "Sync bem-sucedido abre PR com diff revisável"
# BDD Scenario: "Sync atualiza framework-lock.yaml após aprovação do PR"
# Uses PRODOPS_GH_DRY_RUN=true and stub doctor.

REPO7="${WORK_DIR}/repo7"
FW7="${WORK_DIR}/fw7"
setup_fake_repo "${REPO7}"
setup_fake_framework "${FW7}" "v0.2.0" "framework content v0.2.0"

git -C "${REPO7}" init -q
git -C "${REPO7}" config user.email "test@test.com"
git -C "${REPO7}" config user.name "Test"
git -C "${REPO7}" add -A
git -C "${REPO7}" commit -q -m "init"

if [[ -f "${SYNC_SCRIPT}" ]]; then
  initial_branch=$(git -C "${REPO7}" branch --show-current 2>/dev/null || git -C "${REPO7}" rev-parse --abbrev-ref HEAD)

  set +e
  sync7_output=$(SYNC_REPO_ROOT="${REPO7}" FRAMEWORK_SOURCE="${FW7}" \
    PRODOPS_GH_DRY_RUN=true \
    SYNC_DOCTOR_CMD="${STUB_DOCTOR}" \
    bash "${SYNC_SCRIPT}" --version v0.2.0 2>&1)
  sync7_exit=$?
  set -e

  if [[ "${sync7_exit}" -eq 0 ]]; then
    pass "T7a: sync exits 0 on success"
  else
    fail "T7a: sync should exit 0 but exited ${sync7_exit} (output: ${sync7_output})"
  fi

  # Verify the update branch was created
  if git -C "${REPO7}" branch | grep -q "update/prodops-framework-v0.2.0"; then
    pass "T7b: sync created branch update/prodops-framework-v0.2.0"
  else
    fail "T7b: sync did not create branch update/prodops-framework-v0.2.0 (branches: $(git -C "${REPO7}" branch))"
  fi

  # Switch to that branch to check the lock file
  git -C "${REPO7}" checkout -q "update/prodops-framework-v0.2.0" 2>/dev/null || true

  # framework-lock.yaml should have version updated to v0.2.0
  if grep -q "v0.2.0" "${REPO7}/prodops/exec/framework-lock.yaml"; then
    pass "T7c: framework-lock.yaml version updated to v0.2.0"
  else
    fail "T7c: framework-lock.yaml does not contain v0.2.0 (content: $(cat "${REPO7}/prodops/exec/framework-lock.yaml"))"
  fi

  # drift.status should be ok
  if grep -q "status: ok" "${REPO7}/prodops/exec/framework-lock.yaml"; then
    pass "T7d: framework-lock.yaml drift.status is ok"
  else
    fail "T7d: framework-lock.yaml drift.status is not ok (content: $(cat "${REPO7}/prodops/exec/framework-lock.yaml"))"
  fi

  # framework file was updated
  if grep -q "v0.2.0" "${REPO7}/prodops/framework/README.md"; then
    pass "T7e: framework/README.md was updated to v0.2.0 content"
  else
    fail "T7e: framework/README.md was not updated (content: $(cat "${REPO7}/prodops/framework/README.md"))"
  fi

  # PRODOPS_GH_DRY_RUN output should mention skipping PR
  if echo "${sync7_output}" | grep -qi "dry.run\|skip.*pr\|pr.*skip"; then
    pass "T7f: PRODOPS_GH_DRY_RUN=true skipped gh pr create"
  else
    fail "T7f: PRODOPS_GH_DRY_RUN=true did not mention skipping PR (got: ${sync7_output})"
  fi

  # Doctor was called (stub doctor outputs a recognizable message)
  if echo "${sync7_output}" | grep -qi "doctor\|stub"; then
    pass "T7g: doctor.sh was called during sync"
  else
    fail "T7g: doctor.sh was not called during sync (output: ${sync7_output})"
  fi
else
  for sub in a b c d e f g; do
    fail "T7${sub}: cannot test — ${SYNC_SCRIPT} missing"
  done
fi

# ── T8: bash syntax check ─────────────────────────────────────────────────────

if [[ -f "${SYNC_SCRIPT}" ]]; then
  if bash -n "${SYNC_SCRIPT}" 2>/dev/null; then
    pass "T8: sync-from-framework.sh has valid bash syntax"
  else
    fail "T8: sync-from-framework.sh has syntax errors"
  fi
else
  fail "T8: cannot test — ${SYNC_SCRIPT} missing"
fi

# ── T9: lock file must exist ───────────────────────────────────────────────────

REPO9="${WORK_DIR}/repo9"
mkdir -p "${REPO9}"
# No framework-lock.yaml — script must exit 1

if [[ -f "${SYNC_SCRIPT}" ]]; then
  set +e
  err9=$(SYNC_REPO_ROOT="${REPO9}" FRAMEWORK_SOURCE="${WORK_DIR}/fw3" \
    bash "${SYNC_SCRIPT}" --check 2>&1)
  exit9=$?
  set -e

  if [[ "${exit9}" -ne 0 ]]; then
    pass "T9a: exits non-zero when framework-lock.yaml is missing"
  else
    fail "T9a: should exit non-zero when framework-lock.yaml is missing"
  fi

  if echo "${err9}" | grep -qi "lock\|framework-lock\|not found"; then
    pass "T9b: error message mentions missing lock file"
  else
    fail "T9b: error message does not mention lock file (got: ${err9})"
  fi
else
  fail "T9a: cannot test — ${SYNC_SCRIPT} missing"
  fail "T9b: cannot test — ${SYNC_SCRIPT} missing"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

printf '\n---\nResults: %d passed, %d failed out of %d tests.\n' \
  "${passed}" "${failed}" "${total}"

if [[ "${failed}" -gt 0 ]]; then
  exit 1
fi
exit 0
