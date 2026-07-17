#!/usr/bin/env bash
# prodops/scripts/delivery/sync.sh
#
# Executes the Sync phase of the ProdOps Delivery pipeline.
#
# Skills:
#   prodops/skills/sync/SKILL.md
#   prodops/skills/sync/steps/rebase/SKILL.md
#   prodops/skills/sync/steps/align/SKILL.md
#
# Usage:
#   sync.sh                          full flow: rebase then align
#   sync.sh rebase                   rebase step only
#   sync.sh align                    align step only
#   sync.sh --base <branch>          explicit base branch (default: inferred)
#   sync.sh --strategy merge         use git merge instead of rebase (default: rebase)
#   sync.sh --no-test                skip lint and test after rebase
#   sync.sh --dry-run                print git commands without executing them
#   sync.sh -h | --help              show this help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${ROOT_DIR}"

# ─── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ─── state ────────────────────────────────────────────────────────────────────
STEP=""          # rebase | align | "" (both)
BASE_BRANCH=""
STRATEGY="rebase" # rebase | merge
DRY_RUN=false
NO_TEST=false
ISSUES=0
WARNINGS=0

# ─── argument parsing ─────────────────────────────────────────────────────────
usage() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '^#!/' | sed 's/^# \?//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    rebase|align)   STEP="$1" ;;
    --base)         BASE_BRANCH="$2"; shift ;;
    --strategy)     STRATEGY="$2"; shift ;;
    --no-test)      NO_TEST=true ;;
    --dry-run)      DRY_RUN=true ;;
    -h|--help)      usage ;;
    *) printf 'Unknown argument: %s\nRun with --help for usage.\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

# ─── output helpers ───────────────────────────────────────────────────────────
header()  { printf "\n${BOLD}${BLUE}━━━ %s ━━━${NC}\n" "$*"; }
section() { printf "\n${BOLD}%s${NC}\n" "$*"; }
info()    { printf "  ${BLUE}→${NC} %s\n" "$*"; }
pass()    { printf "  ${GREEN}✔${NC} %s\n" "$*"; }
warn()    { printf "  ${YELLOW}⚠${NC} %s\n" "$*"; WARNINGS=$((WARNINGS + 1)); }
fail()    { printf "  ${RED}✘${NC} %s\n" "$*"; ISSUES=$((ISSUES + 1)); }
note()    { printf "  ${DIM}%s${NC}\n" "$*"; }
cmd()     { printf "  ${DIM}\$${NC} %s\n" "$*"; }

run() {
  cmd "$*"
  if [[ "${DRY_RUN}" == "false" ]]; then
    "$@"
  fi
}

run_capture() {
  # Like run but returns output even in dry-run (reads state, doesn't modify)
  "$@"
}

# ─── base branch inference ────────────────────────────────────────────────────
infer_base() {
  local current
  current=$(git branch --show-current)

  # 1. upstream tracking branch (when it differs from current)
  local upstream
  upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null | sed 's|^origin/||' || true)
  if [[ -n "${upstream}" && "${upstream}" != "${current}" ]]; then
    echo "${upstream}"; return
  fi

  # 2. origin/HEAD symbolic ref
  local head_branch
  head_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || true)
  if [[ -n "${head_branch}" ]]; then
    echo "${head_branch}"; return
  fi

  # 3. main / master
  for b in main master; do
    if git show-ref --verify --quiet "refs/remotes/origin/${b}" 2>/dev/null; then
      echo "${b}"; return
    fi
  done

  echo ""
}

# ─── rebase step ──────────────────────────────────────────────────────────────
step_rebase() {
  header "SYNC → REBASE"
  note "Ref: prodops/skills/sync/steps/rebase/SKILL.md"

  # ── 1. preflight ────────────────────────────────────────────────────────────
  section "1/7  Preflight"

  local current_branch
  current_branch=$(git branch --show-current)
  info "Current branch: ${current_branch}"

  # Guard: do not run on protected branches
  if [[ "${current_branch}" =~ ^(main|master|develop|staging|production)$ ]]; then
    fail "Running sync rebase on a shared base branch (${current_branch}) is not allowed."
    fail "Switch to your feature branch first."
    return 1
  fi
  pass "Branch is a feature branch"

  # Check working tree
  local dirty
  dirty=$(git status --short)
  if [[ -n "${dirty}" ]]; then
    fail "Working tree has uncommitted changes:"
    git status --short | while IFS= read -r line; do note "  ${line}"; done
    printf "\n"
    printf "  Choose one of:\n"
    printf "    commit  →  run /hack commit (or git commit)\n"
    printf "    stash   →  git stash -u\n"
    printf "    stop    →  investigate before proceeding\n"
    return 1
  fi
  pass "Working tree is clean"

  # ── 2. resolve base ─────────────────────────────────────────────────────────
  section "2/7  Resolve base branch"

  if [[ -z "${BASE_BRANCH}" ]]; then
    BASE_BRANCH=$(infer_base)
  fi

  if [[ -z "${BASE_BRANCH}" ]]; then
    fail "Could not infer base branch. Specify with: --base <branch>"
    return 1
  fi
  info "Base branch: ${BASE_BRANCH}"

  # Verify base exists on remote
  if ! git show-ref --verify --quiet "refs/remotes/origin/${BASE_BRANCH}" 2>/dev/null; then
    warn "origin/${BASE_BRANCH} not found — proceeding with local ref only"
  else
    pass "origin/${BASE_BRANCH} exists"
  fi

  # ── 3. fetch ────────────────────────────────────────────────────────────────
  section "3/7  Fetch remote"
  run git fetch --all --prune
  pass "Fetched and pruned remotes"

  # Show divergence
  local ahead behind
  ahead=$(git rev-list --count "origin/${BASE_BRANCH}..HEAD" 2>/dev/null || echo "?")
  behind=$(git rev-list --count "HEAD..origin/${BASE_BRANCH}" 2>/dev/null || echo "?")
  info "Feature branch: ${ahead} commit(s) ahead, ${behind} commit(s) behind origin/${BASE_BRANCH}"

  # ── 4. update base ──────────────────────────────────────────────────────────
  section "4/7  Update base (fast-forward only)"
  run git switch "${BASE_BRANCH}"

  local ff_result=0
  if [[ "${DRY_RUN}" == "false" ]]; then
    git pull --ff-only || ff_result=$?
  else
    cmd "git pull --ff-only"
  fi

  if [[ ${ff_result} -ne 0 ]]; then
    fail "Fast-forward failed — origin/${BASE_BRANCH} has diverged from local ${BASE_BRANCH}."
    fail "Investigate with: git log --oneline --decorate --graph --max-count=20 --all"
    run git switch "${current_branch}"
    return 1
  fi
  pass "Base branch is up to date"

  run git switch "${current_branch}"

  # ── 5. integrate ────────────────────────────────────────────────────────────
  section "5/7  Integrate base into feature branch (${STRATEGY})"

  local integrate_result=0
  if [[ "${STRATEGY}" == "rebase" ]]; then
    if [[ "${DRY_RUN}" == "false" ]]; then
      git rebase "${BASE_BRANCH}" || integrate_result=$?
    else
      cmd "git rebase ${BASE_BRANCH}"
    fi
  else
    if [[ "${DRY_RUN}" == "false" ]]; then
      git merge "${BASE_BRANCH}" --no-edit || integrate_result=$?
    else
      cmd "git merge ${BASE_BRANCH} --no-edit"
    fi
  fi

  if [[ ${integrate_result} -ne 0 ]]; then
    fail "Integration has conflicts. Resolve them manually:"
    git diff --name-only --diff-filter=U 2>/dev/null | while IFS= read -r f; do note "  conflict: ${f}"; done
    printf "\n"
    printf "  After resolving each file:\n"
    if [[ "${STRATEGY}" == "rebase" ]]; then
      printf "    git add <resolved> && git rebase --continue\n"
    else
      printf "    git add <resolved> && git commit\n"
    fi
    printf "\n"
    printf "  Then run this script again to validate.\n"
    printf "\n"
    warn "Guardrail: Inspect both sides before editing. Preserve all tests."
    return 1
  fi
  pass "Integration complete (no conflicts)"

  # ── 5b. push after rebase if branch tracks a remote ─────────────────────────
  if [[ "${STRATEGY}" == "rebase" ]]; then
    local remote_tracking
    remote_tracking=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)
    if [[ -n "${remote_tracking}" ]]; then
      section "5b/7  Push rebased branch (--force-with-lease)"
      if [[ "${DRY_RUN}" == "false" ]]; then
        git push --force-with-lease && pass "Branch pushed" || {
          fail "--force-with-lease rejected: remote was updated since last fetch."
          fail "Run: git fetch && git log --oneline -5 ${remote_tracking}"
          fail "Then resolve the divergence before pushing."
          return 1
        }
      else
        cmd "git push --force-with-lease"
      fi
    fi
  fi

  # ── 6. preserve TDD ─────────────────────────────────────────────────────────
  section "6/7  TDD preservation check"

  # Check if any test files were deleted in the merge/rebase
  local deleted_tests
  deleted_tests=$(git diff "${BASE_BRANCH}...HEAD" --name-only --diff-filter=D | grep -E '\.(spec|test)\.(ts|js)$' || true)
  if [[ -n "${deleted_tests}" ]]; then
    fail "Test files were deleted during integration:"
    echo "${deleted_tests}" | while IFS= read -r f; do fail "  deleted: ${f}"; done
    fail "Restore them — never remove tests to complete a sync."
    return 1
  fi

  # Check for .skip or .only patterns introduced by the integration
  local skip_patterns
  skip_patterns=$(git diff "${BASE_BRANCH}...HEAD" -U0 | grep '^+' | grep -E '\.(skip|only)\(' || true)
  if [[ -n "${skip_patterns}" ]]; then
    warn "test.skip() or test.only() introduced by integration:"
    echo "${skip_patterns}" | head -5 | while IFS= read -r line; do note "  ${line}"; done
    warn "Remove .skip/.only before proceeding — they suppress test coverage."
  else
    pass "No test.skip() or test.only() introduced"
  fi
  pass "No test files deleted"

  # ── 7. validate ─────────────────────────────────────────────────────────────
  section "7/7  Validate"

  if [[ "${NO_TEST}" == "true" ]]; then
    warn "Skipping lint and tests (--no-test)"
  else
    # Detect which packages were touched
    local touched_packages
    touched_packages=$(git diff "${BASE_BRANCH}...HEAD" --name-only | grep '^api/' | head -1 || true)

    if [[ -n "${touched_packages}" ]]; then
      info "Running lint in api/"
      if [[ "${DRY_RUN}" == "false" ]]; then
        (cd api && npm run lint) && pass "Lint clean" || { fail "Lint failed — fix errors before proceeding"; return 1; }

        info "Running tests in api/"
        (cd api && npm run test) && pass "Tests pass" || { fail "Tests failed — fix failures before proceeding"; return 1; }
      else
        cmd "cd api && npm run lint"
        cmd "cd api && npm run test"
      fi
    else
      info "No api/ files touched — skipping package validation"
    fi
  fi

  # Final state
  printf "\n"
  run_capture git status --short --branch

  pass "Rebase step complete"
}

# ─── align step ───────────────────────────────────────────────────────────────
step_align() {
  header "SYNC → ALIGN"
  note "Ref: prodops/skills/sync/steps/align/SKILL.md"

  # Resolve base for diff
  if [[ -z "${BASE_BRANCH}" ]]; then
    BASE_BRANCH=$(infer_base)
  fi
  if [[ -z "${BASE_BRANCH}" ]]; then
    fail "Could not infer base branch. Specify with: --base <branch>"
    return 1
  fi

  # Get the full diff of this branch
  local diff_files
  diff_files=$(git diff "${BASE_BRANCH}...HEAD" --name-only 2>/dev/null || true)

  if [[ -z "${diff_files}" ]]; then
    pass "No changes relative to ${BASE_BRANCH} — nothing to align"
    return 0
  fi

  local total_files
  total_files=$(echo "${diff_files}" | wc -l | tr -d ' ')
  info "Diff against ${BASE_BRANCH}: ${total_files} file(s) changed"

  # ── 1. BDD Features ─────────────────────────────────────────────────────────
  section "1/4  BDD Features"
  note "Rule: behavior change → prodops/artifacts/business/bdd/<capability>.feature must reflect it"

  local changed_modules
  changed_modules=$(echo "${diff_files}" | grep '^api/src/modules/' | sed 's|api/src/modules/\([^/]*\)/.*|\1|' | sort -u || true)

  if [[ -z "${changed_modules}" ]]; then
    pass "No module source files changed"
  else
    local bdd_needs_review=false
    for module in ${changed_modules}; do
      # Look for a matching BDD feature
      local matches
      matches=$(find prodops/artifacts/business/bdd -name "*.feature" 2>/dev/null | xargs grep -l "${module}" 2>/dev/null || true)

      # Also check by filename pattern
      local by_name
      by_name=$(find prodops/artifacts/business/bdd -name "*${module}*" 2>/dev/null || true)
      matches="${matches}${by_name}"

      if [[ -z "${matches}" ]]; then
        warn "Module '${module}' changed — no BDD Feature references it in prodops/artifacts/business/bdd/"
        note "  If this module's behavior changed, add or update the feature file."
        bdd_needs_review=true
      else
        # Check if the feature file was also updated in this branch
        local feature_updated
        feature_updated=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "prodops/artifacts/business/bdd/" | grep -v '^$' || true)
        if [[ -n "${feature_updated}" ]]; then
          pass "Module '${module}' — BDD Feature updated in this branch"
        else
          warn "Module '${module}' changed — BDD Feature NOT updated in this branch"
          note "  Review: ${matches}" | head -3
          note "  Update if the behavior changed; leave if only internals changed."
          bdd_needs_review=true
        fi
      fi
    done
    [[ "${bdd_needs_review}" == "false" ]] && pass "BDD Features appear consistent"
  fi

  # ── 2. Domain Events → Event Storming ───────────────────────────────────────
  section "2/4  Event Storming"
  note "Rule: new/renamed/removed domain event → prodops/journeys/assessment/event-storming/plan.json"

  local event_diff
  event_diff=$(git diff "${BASE_BRANCH}...HEAD" -U0 -- "api/" | grep '^+' | grep -E "eventEmitter\.emit\(|@OnEvent\(" || true)

  if [[ -n "${event_diff}" ]]; then
    warn "Domain event changes detected:"
    echo "${event_diff}" | head -10 | while IFS= read -r line; do note "    ${line}"; done
    note "  Update prodops/journeys/assessment/event-storming/plan.json:"
    note "    - customEvents: add/rename/remove event entries"
    note "    - sloSuggestions: add entry if event is on the critical path"
    note "    - assumptions[last]: update date and summary"
    note "  Format ref: prodops/journeys/assessment/event-storming/plan-model.json"

    # Check if event-storming was already updated
    local es_updated
    es_updated=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "prodops/journeys/assessment/event-storming/" || true)
    if [[ -n "${es_updated}" ]]; then
      pass "event-storming/plan.json was updated in this branch"
    else
      warn "event-storming/plan.json was NOT updated in this branch"
    fi
  else
    pass "No domain event changes detected"
  fi

  # ── 3. Architecture ─────────────────────────────────────────────────────────
  section "3/4  Architecture"
  note "Rule: new module / route / external dep / table / event topic → overview.md"

  local arch_needs_review=false

  # New modules (directories that didn't exist on base)
  local all_modules
  all_modules=$(echo "${diff_files}" | grep '^api/src/modules/' | sed 's|api/src/modules/\([^/]*\)/.*|\1|' | sort -u || true)
  for module in ${all_modules}; do
    if ! git show "${BASE_BRANCH}:api/src/modules/${module}/" > /dev/null 2>&1; then
      warn "New module detected: '${module}'"
      note "  Add to Mermaid diagram in prodops/artifacts/product/architecture/overview.md"
      arch_needs_review=true
    fi
  done

  # Infrastructure changes
  local infra_changed
  infra_changed=$(echo "${diff_files}" | grep -E '^api/infra/|^api/src/infra/' || true)
  if [[ -n "${infra_changed}" ]]; then
    warn "Infrastructure files changed:"
    echo "${infra_changed}" | while IFS= read -r f; do note "  ${f}"; done
    note "  Review prodops/artifacts/product/architecture/overview.md for needed updates."
    arch_needs_review=true
  fi

  # New external dependencies in package.json
  local pkg_diff
  pkg_diff=$(git diff "${BASE_BRANCH}...HEAD" -- "api/package.json" | grep '^+' | grep -v '^+++' | grep '"' || true)
  if [[ -n "${pkg_diff}" ]]; then
    warn "api/package.json changed — verify if a new external dependency requires an architecture note"
    arch_needs_review=true
  fi

  if [[ "${arch_needs_review}" == "false" ]]; then
    pass "No structural changes detected"
  else
    # Check if architecture was updated
    local arch_updated
    arch_updated=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "prodops/artifacts/product/architecture/" || true)
    if [[ -n "${arch_updated}" ]]; then
      pass "architecture/overview.md was updated in this branch"
    else
      warn "architecture/overview.md was NOT updated in this branch"
    fi
  fi

  # ── 4. OBC criteria ─────────────────────────────────────────────────────────
  section "4/4  OBC Criteria"
  note "Rule: if implementation diverges from OBC acceptance criteria, update the OBC"

  local changed_obcs=""
  for module in ${changed_modules:-}; do
    local obc_file
    obc_file=$(find prodops/artifacts/business/obcs -name "*${module}*" 2>/dev/null | head -1 || true)
    if [[ -n "${obc_file}" ]]; then
      local obc_updated
      obc_updated=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "${obc_file}" || true)
      if [[ -z "${obc_updated}" ]]; then
        note "  OBC exists for '${module}': ${obc_file}"
        note "  Not updated in this branch — verify criteria are still accurate."
        changed_obcs="${changed_obcs} ${obc_file}"
      else
        pass "OBC for '${module}' updated"
      fi
    fi
  done
  [[ -z "${changed_obcs}" ]] && pass "No OBC updates required (or already applied)"

  # ── Release Trail ────────────────────────────────────────────────────────────
  section "  Release Trail"

  local trail_updated
  trail_updated=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "prodops/artifacts/governance/trails/release-trail.md" || true)
  if [[ -z "${trail_updated}" ]]; then
    warn "Release Trail not updated in this branch"
    note "  Append an entry to prodops/artifacts/governance/trails/release-trail.md"
    note "  Template: prodops/templates/delivery/release-entry.md"
  else
    pass "Release Trail updated"
  fi

  # ── Markdown links ───────────────────────────────────────────────────────────
  section "  Internal link check (updated ProdOps files)"

  local updated_prodops_files
  updated_prodops_files=$(git diff "${BASE_BRANCH}...HEAD" --name-only -- "prodops/" | grep '\.md$' || true)

  if [[ -n "${updated_prodops_files}" ]]; then
    local broken_count=0
    while IFS= read -r md_file; do
      [[ -z "${md_file}" ]] && continue
      [[ ! -f "${md_file}" ]] && continue
      # Extract relative markdown links (skip http/https anchors and bare anchors)
      local links
      links=$(grep -oE '\[([^]]+)\]\(([^)]+)\)' "${md_file}" 2>/dev/null \
              | grep -oE '\(([^)]+)\)' | tr -d '()' \
              | grep -v '^http' | grep -v '^#' || true)
      while IFS= read -r link; do
        [[ -z "${link}" ]] && continue
        # Strip fragment
        local path_part="${link%%#*}"
        [[ -z "${path_part}" ]] && continue
        # Resolve relative to file's directory (macOS-compatible)
        local base_dir
        base_dir="$(dirname "${md_file}")"
        local target="${base_dir}/${path_part}"
        # Normalize with python (available on macOS, avoids GNU realpath -m)
        target="$(python3 -c "import os,sys; print(os.path.normpath(sys.argv[1]))" "${target}" 2>/dev/null || echo "${target}")"
        if [[ ! -e "${target}" ]]; then
          warn "Broken link in ${md_file}: ${link}"
          broken_count=$((broken_count + 1))
        fi
      done <<< "${links}"
    done <<< "${updated_prodops_files}"
    if [[ "${broken_count}" -eq 0 ]]; then
      pass "Internal links in updated files resolve"
    fi
  else
    pass "No ProdOps markdown files updated — no link check needed"
  fi

  pass "Align step complete"
}

# ─── summary ──────────────────────────────────────────────────────────────────
print_summary() {
  printf "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  if [[ "${ISSUES}" -gt 0 ]]; then
    printf "${RED}${BOLD}SYNC BLOCKED — %d issue(s) must be resolved.${NC}\n" "${ISSUES}"
  elif [[ "${WARNINGS}" -gt 0 ]]; then
    printf "${YELLOW}${BOLD}SYNC COMPLETE with %d warning(s) — review before Finish.${NC}\n" "${WARNINGS}"
  else
    printf "${GREEN}${BOLD}SYNC COMPLETE — ready for Finish.${NC}\n"
  fi
  printf "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"

  if [[ "${ISSUES}" -gt 0 ]]; then
    exit 1
  fi
}

# ─── main ─────────────────────────────────────────────────────────────────────
main() {
  printf "${BOLD}ProdOps Sync${NC}"
  [[ "${DRY_RUN}" == "true" ]] && printf " ${YELLOW}[dry-run]${NC}"
  printf "\n"
  note "Ref: prodops/skills/sync/SKILL.md"

  case "${STEP}" in
    rebase) step_rebase ;;
    align)  step_align  ;;
    "")     step_rebase && step_align ;;
  esac

  print_summary
}

main
