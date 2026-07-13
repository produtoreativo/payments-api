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

check_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    pass "exists ${path}"
  else
    fail "missing ${path}"
  fi
}

check_path "prodops/framework/canonical-paths.md"
check_path "prodops/artifacts/product"
check_path "prodops/artifacts/bdd"
check_path "prodops/artifacts/obcs"
check_path "prodops/artifacts/plans"
check_path "prodops/artifacts/trails/release-trail.md"
check_path "prodops/journeys/discovery/experiments"
check_path "prodops/journeys/assessment/reliability-plans"
check_path "prodops/journeys/assessment/risks.md"
check_path "prodops/journeys/operation"
check_path "prodops/journeys/delivery/phases/bootstrap/README.md"
check_path "prodops/journeys/delivery/phases/hack/README.md"
check_path "prodops/journeys/delivery/phases/finish/quality-gates.md"

# Verify key committed OBC artifacts exist for items with Entrou status
for obc in api-token-validation create-invoice-boleto webhook-configuration credit-card-authorization-confirmation; do
  check_path "prodops/artifacts/obcs/${obc}.md"
done

while IFS= read -r experiment_dir; do
  [[ -z "${experiment_dir}" ]] && continue
  check_path "${experiment_dir}/experiment.md"
  check_path "${experiment_dir}/upstream-trail.md"
done < <(find prodops/journeys/discovery/experiments -mindepth 1 -maxdepth 1 -type d | sort)

# Legacy ProdOps path references. Trails and experiment records are exempt
# because they legitimately record old layouts as history. `prodops/product/`
# keeps a trailing slash so references to existing files such as
# docs/prodops/product-deck.md do not false-positive on the old
# prodops/product/ directory pattern.
legacy_pattern='prodops/(upstream|product/|downstream/release-trail\.md|assessment/reliability-plan|assessment/reliability-plans|assessment/iteration-plans|assessment/event-storming|assessment/architecture)|prodops/operation/|delivery/flows/'

legacy_targets=(
  AGENTS.md
  prodops/README.md
  prodops/framework
  prodops/execution-model
  prodops/journeys
  prodops/skills
  prodops/templates
  prodops/business-intents
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
  echo "doctor: ripgrep não encontrado — usando fallback com grep" >&2
fi

if have_rg; then
  legacy_refs="$(
    rg -n \
      "${legacy_pattern}" \
      "${legacy_targets[@]}" \
      -g '!prodops/framework/canonical-paths*.md' \
      -g '!prodops/journeys/discovery/upstream-trail*.md' \
      -g '!prodops/journeys/discovery/experiments/**/upstream-trail*.md' \
      -g '!prodops/journeys/discovery/experiments/**/experiment*.md' \
      -g '!prodops/documentation-review*.md' \
      || true
  )"
else
  legacy_refs="$(
    grep -rEn "${legacy_pattern}" "${legacy_targets[@]}" 2>/dev/null \
      | grep -vE '^(prodops/framework/canonical-paths(\.en)?\.md|prodops/journeys/discovery/upstream-trail(\.en)?\.md|prodops/documentation-review(\.en)?\.md):' \
      | grep -vE '^prodops/journeys/discovery/experiments/[^:]*/(upstream-trail|experiment)(\.en)?\.md:' \
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
done < <(find . -type f -name '*.md' -not -path './.git/*' -not -path '*/node_modules/*' | LC_ALL=C sort)

if [[ "${broken_links}" -eq 0 ]]; then
  pass "all relative markdown links resolve"
fi

if [[ "${failures}" -gt 0 ]]; then
  printf '\nProdOps doctor found %s issue(s).\n' "${failures}" >&2
  printf 'Run the fix/* branches or repair the listed files.\n' >&2
  exit 1
fi

printf '\nProdOps doctor passed.\n'
