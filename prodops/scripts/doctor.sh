#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

skip() {
  printf 'SKIP: %s\n' "$1" >&2
}

check_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    pass "exists ${path}"
  else
    fail "missing ${path}"
  fi
}

check_path "prodops/framework/canonical-paths.md"

# ── Artifact directories — type-based layout (post-reorganization) ────────────
check_path "prodops/artifacts/obcs"
check_path "prodops/artifacts/bdd"
check_path "prodops/artifacts/business-intents"
check_path "prodops/artifacts/architecture"
check_path "prodops/artifacts/event-storming"
check_path "prodops/artifacts/plans"
check_path "prodops/artifacts/plans/reliability"
check_path "prodops/artifacts/trails"
check_path "prodops/artifacts/trails/release-trail.md"
check_path "prodops/artifacts/evidence"
check_path "prodops/artifacts/experiments"
check_path "prodops/artifacts/risks/risks.md"
check_path "prodops/artifacts/product"

# ── Old category containers must be absent ────────────────────────────────────
if [[ -e "prodops/artifacts/business" ]]; then
  fail "prodops/artifacts/business/ still exists — should be removed after reorganization"
else
  pass "prodops/artifacts/business/ correctly removed"
fi

if [[ -e "prodops/artifacts/governance" ]]; then
  fail "prodops/artifacts/governance/ still exists — should be removed after reorganization"
else
  pass "prodops/artifacts/governance/ correctly removed"
fi

# ── Framework structure ────────────────────────────────────────────────────────
check_path "prodops/framework/journeys"
check_path "prodops/framework/execution-model"
check_path "prodops/framework/journeys/operation"
check_path "prodops/framework/journeys/delivery/phases/bootstrap/README.md"
check_path "prodops/framework/journeys/delivery/phases/hack/README.md"
check_path "prodops/framework/journeys/delivery/phases/finish/quality-gates.md"
check_path "prodops/framework/execution-model/upstream.md"
check_path "prodops/framework/execution-model/downstream.md"

if [[ -e "prodops/journeys" ]]; then
  fail "prodops/journeys/ still exists — should have been moved to prodops/framework/journeys/"
else
  pass "prodops/journeys/ correctly moved to framework"
fi

if [[ -e "prodops/execution-model" ]]; then
  fail "prodops/execution-model/ still exists — should have been moved to prodops/framework/execution-model/"
else
  pass "prodops/execution-model/ correctly moved to framework"
fi

# Verify key committed OBC artifacts exist for items with Entrou status
for obc in api-token-validation create-invoice-boleto webhook-configuration credit-card-authorization-confirmation; do
  check_path "prodops/artifacts/obcs/${obc}.md"
done

while IFS= read -r experiment_dir; do
  [[ -z "${experiment_dir}" ]] && continue
  check_path "${experiment_dir}/experiment.md"
  check_path "${experiment_dir}/upstream-trail.md"
done < <(find prodops/artifacts/experiments -mindepth 1 -maxdepth 1 -type d | sort)

# Legacy ProdOps path references. Trails and experiment records are exempt
# because they legitimately record old layouts as history. `prodops/product/`
# keeps a trailing slash so references to existing files such as
# docs/prodops/product-deck.md do not false-positive on the old
# prodops/product/ directory pattern.
#
# Also catches paths moved in the journeys→artifacts split:
#   journeys/discovery/experiments/ → artifacts/experiments/
#   journeys/assessment/risks.md    → artifacts/risks/risks.md
#   journeys/assessment/opportunities.md → artifacts/risks/opportunities.md
# (assessment/reliability-plans and assessment/event-storming are already
#  caught by the existing pattern prefixes.)
legacy_pattern='prodops/(upstream|product/|downstream/release-trail\.md|assessment/reliability-plan|assessment/reliability-plans|assessment/iteration-plans|assessment/event-storming|assessment/architecture|journeys/|execution-model/|skills/payments-api-local-testing/|skills/references/engineering/clean-code/|skills/references/engineering/ddd/)|prodops/operation/|delivery/flows/|journeys/discovery/experiments/|journeys/assessment/risks\.md|journeys/assessment/opportunities\.md|artifacts/business/(obcs|bdd|intents)|artifacts/governance/(plans|trails|evidence)|artifacts/product/(architecture|event-storming)'

legacy_targets=(
  AGENTS.md
  prodops/README.md
  prodops/framework
  prodops/framework/execution-model
  prodops/framework/journeys
  prodops/skills
  prodops/templates
  prodops/artifacts/business-intents
)

# Repo-wide coverage: agent/tool instruction dirs and docs.
for extra_target in .codex .claude .github docs; do
  if [[ -e "${extra_target}" ]]; then
    legacy_targets+=("${extra_target}")
  fi
done

# ripgrep quando disponível; fallback para grep (runners de CI não trazem rg).
have_rg() { command -v rg >/dev/null 2>&1; }
if ! have_rg; then
  skip "ripgrep not found — install rg for stale-ref check (grep fallback active; worktrees excluded)"
fi

if have_rg; then
  legacy_refs="$(
    rg -n \
      "${legacy_pattern}" \
      "${legacy_targets[@]}" \
      -g '!prodops/framework/canonical-paths*.md' \
      -g '!prodops/framework/journeys/discovery/upstream-trail*.md' \
      -g '!prodops/artifacts/experiments/**/upstream-trail*.md' \
      -g '!prodops/artifacts/experiments/**/experiment*.md' \
      -g '!prodops/documentation-review*.md' \
      -g '!.claude/worktrees/**' \
      -g '!.codex/worktrees/**' \
      -g '!.claude/settings*.json' \
      || true
  )"
else
  legacy_refs="$(
    grep -rEn "${legacy_pattern}" "${legacy_targets[@]}" 2>/dev/null \
      | grep -vE '^\.(claude|codex)/worktrees/' \
      | grep -vE '^(prodops/framework/canonical-paths(\.en)?\.md|prodops/framework/journeys/discovery/upstream-trail(\.en)?\.md|prodops/documentation-review(\.en)?\.md):' \
      | grep -vE '^prodops/artifacts/experiments/[^:]*/(upstream-trail|experiment)(\.en)?\.md:' \
      | grep -vE '^\.(claude)/settings.*\.json:' \
      || true
  )"
fi

if [[ -n "${legacy_refs}" ]]; then
  printf '%s\n' "${legacy_refs}" >&2
  fail "legacy ProdOps path references found in operational docs"
else
  pass "no legacy ProdOps path references in operational docs"
fi

# Stale artifact references. Unlike the legacy layout paths above, these files
# were renamed or removed and every reference -- including trails -- is
# expected to point at the current location, so trails are not exempt here.
stale_pattern='api/test/create-invoice\.acceptance\.e2e-spec\.ts|prodops/journeys/discovery/features/'

# Referências históricas anotadas com (migrado:|removido:|renomeado:) — ou os
# equivalentes em inglês nos twins .en.md — apontam para a localização atual
# preservando a leitura append-only dos trails; são consideradas resolvidas.
# PROJECT-REVIEW.md discute os paths como findings de auditoria, mesma classe
# de documentation-review.md.
stale_annotation='\((migrado|removido|renomeado|migrated|removed|renamed):'

if have_rg; then
  stale_refs="$(
    rg -n \
      "${stale_pattern}" \
      --hidden \
      -g '*.md' \
      -g '!.git/**' \
      -g '!node_modules/**' \
      -g '!api/node_modules/**' \
      -g '!.claude/worktrees/**' \
      -g '!.codex/worktrees/**' \
      -g '!prodops/framework/canonical-paths*.md' \
      -g '!prodops/documentation-review*.md' \
      -g '!PROJECT-REVIEW.md' \
      | grep -vE "${stale_annotation}" \
      || true
  )"
else
  stale_refs="$(
    grep -rEn --include='*.md' --exclude-dir=.git --exclude-dir=node_modules \
      "${stale_pattern}" . 2>/dev/null \
      | sed 's|^\./||' \
      | grep -vE '^\.(claude|codex)/worktrees/' \
      | grep -vE '^(prodops/framework/canonical-paths(\.en)?\.md|prodops/documentation-review(\.en)?\.md|PROJECT-REVIEW\.md):' \
      | grep -vE "${stale_annotation}" \
      || true
  )"
fi

if [[ -n "${stale_refs}" ]]; then
  printf '%s\n' "${stale_refs}" >&2
  fail "stale artifact references found (renamed or removed files)"
else
  pass "no stale artifact references"
fi

# Relative markdown link check. Extracts inline links and images
# `[text](target)` from every markdown file and verifies that relative
# targets resolve from the file's directory (leading `/` resolves from the
# repo root). External links (scheme://, mailto:, tel:, data:) and pure
# anchor links are skipped; `#fragment` suffixes, optional `"title"` parts
# and <angle-bracket> wrapping are stripped. Reference-style links
# ([text][ref]) are deliberately not resolved.
link_re='\]\(([^()]+)\)'
broken_links=0

while IFS= read -r md_file; do
  md_file="${md_file#./}"
  md_dir="$(dirname "${md_file}")"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    rest="${line}"
    while [[ "${rest}" =~ ${link_re} ]]; do
      link="${BASH_REMATCH[1]}"
      rest="${rest#*"${BASH_REMATCH[0]}"}"
      link="${link#"${link%%[![:space:]]*}"}"
      link="${link%"${link##*[![:space:]]}"}"
      link="${link%%[[:space:]]\"*}"
      link="${link%%[[:space:]]\'*}"
      if [[ "${link}" == \<*\> ]]; then
        link="${link:1:${#link}-2}"
      fi
      case "${link}" in
        '' | \#* | mailto:* | tel:* | data:*) continue ;;
      esac
      [[ "${link}" == *"://"* ]] && continue
      link="${link%%#*}"
      [[ -z "${link}" ]] && continue
      if [[ "${link}" == /* ]]; then
        link_target="${ROOT_DIR}${link}"
      else
        link_target="${md_dir}/${link}"
      fi
      if [[ ! -e "${link_target}" ]]; then
        fail "${md_file}: broken link -> ${link}"
        broken_links=$((broken_links + 1))
      fi
    done
  done < "${md_file}"
done < <(find . -type f -name '*.md' \
  -not -path './.git/*' \
  -not -path '*/node_modules/*' \
  -not -path './.claude/worktrees/*' \
  -not -path './.codex/worktrees/*' \
  | LC_ALL=C sort)

if [[ "${broken_links}" -eq 0 ]]; then
  pass "all relative markdown links resolve"
fi

# ── Framework distribution integrity ──────────────────────────────────────────

check_path ".prodopsignore"
check_path "prodops/exec/framework-lock.yaml"

if [[ -f "prodops/exec/framework-lock.yaml" ]]; then
  if grep -q "status: self" prodops/exec/framework-lock.yaml; then
    pass "framework-lock.yaml: status is self (empirical phase)"
  else
    fail "framework-lock.yaml: expected 'status: self' for empirical phase"
  fi
fi

if grep -q "payments-api-local-testing" prodops/framework/canonical-paths.md 2>/dev/null; then
  fail "canonical-paths.md references product-local skill (payments-api-local-testing) — remove it"
else
  pass "canonical-paths.md: no product-local skill references"
fi

# ── Product-local skills space ─────────────────────────────────────────────
check_path "prodops/skills/local"
check_path "prodops/skills/local/README.md"
check_path "prodops/skills/local/payments-api-local-testing/SKILL.md"

if [[ -e "prodops/skills/payments-api-local-testing" ]]; then
  fail "prodops/skills/payments-api-local-testing still exists — should be at prodops/skills/local/payments-api-local-testing"
else
  pass "prodops/skills/payments-api-local-testing correctly moved to local/"
fi

if grep -q "prodops/skills/local/" .prodopsignore 2>/dev/null; then
  pass ".prodopsignore protects prodops/skills/local/"
else
  fail ".prodopsignore missing prodops/skills/local/ protection"
fi

# ── Engineering references layout ─────────────────────────────────────────
check_path "prodops/skills/references/engineering/tdd-prodops"
check_path "prodops/skills/references/local"
check_path "prodops/skills/references/local/README.md"
check_path "prodops/skills/references/local/engineering/clean-code"
check_path "prodops/skills/references/local/engineering/ddd"

if [[ -e "prodops/skills/references/engineering/clean-code" ]]; then
  fail "prodops/skills/references/engineering/clean-code still exists — should be at references/local/engineering/clean-code"
else
  pass "clean-code correctly moved to references/local/"
fi

if [[ -e "prodops/skills/references/engineering/ddd" ]]; then
  fail "prodops/skills/references/engineering/ddd still exists — should be at references/local/engineering/ddd"
else
  pass "ddd correctly moved to references/local/"
fi

if grep -q "prodops/skills/references/local/" .prodopsignore 2>/dev/null; then
  pass ".prodopsignore protects prodops/skills/references/local/"
else
  fail ".prodopsignore missing prodops/skills/references/local/ protection"
fi

# ── Canonical templates layout ────────────────────────────────────────────────
check_path "prodops/templates/README.md"
check_path "prodops/templates/business-intents/intent.md"
check_path "prodops/templates/discovery/experiment.md"
check_path "prodops/templates/discovery/learning.md"
check_path "prodops/templates/discovery/trail.md"
check_path "prodops/templates/assessment/decision-trail.md"
check_path "prodops/templates/assessment/reliability-checklist.md"
check_path "prodops/templates/delivery/context-capsule.md"
check_path "prodops/templates/delivery/pull-request-checklist.md"
check_path "prodops/templates/delivery/release-entry.md"
check_path "prodops/templates/engineering/definition-of-done.md"
check_path "prodops/templates/engineering/test-plan.md"
check_path "prodops/templates/obcs/local-obc.md"
check_path "prodops/templates/obcs/global-obc.md"
check_path "prodops/templates/obcs/obc.md"
check_path "prodops/templates/operation/runbook.md"
check_path "prodops/templates/operation/postmortem.md"

if [[ "${failures}" -gt 0 ]]; then
  printf '\nProdOps doctor found %s issue(s).\n' "${failures}" >&2
  printf 'Run the fix/* branches or repair the listed files.\n' >&2
  exit 1
fi

printf '\nProdOps doctor passed.\n'
