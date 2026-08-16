#!/usr/bin/env bash
# install-prodops.sh
#
# Installs the ProdOps Framework from produtoreativo/prodops-framework
# into the current (or target) repository and runs all setup steps.
#
# Usage:
#   ./prodops/scripts/install-prodops.sh --version <tag> [--target <dir>]
#                                        [--skip-hooks] [--skip-claude]
#
# Flags:
#   --version <tag>   Framework version to install (required)
#   --target <dir>    Target repository root (default: current directory)
#   --skip-hooks      Do not configure git commit hooks
#   --skip-claude     Do not run install-claude.sh
#
# Environment overrides (for testing):
#   INSTALL_TARGET_DIR  — override target directory (lower priority than --target)
#
# Exit codes:
#   0  success
#   1  missing --version, version not found, or installation error

set -euo pipefail

FRAMEWORK_REPO="produtoreativo/prodops-framework"
FRAMEWORK_URL="https://github.com/${FRAMEWORK_REPO}"

VERSION=""
TARGET_DIR="${INSTALL_TARGET_DIR:-$(pwd)}"
SKIP_HOOKS="false"
SKIP_CLAUDE="false"

# ── Terminal formatting ───────────────────────────────────────────────────────

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  RED=$(tput setaf 1)
  CYAN=$(tput setaf 6)
  RESET=$(tput sgr0)
else
  BOLD='' GREEN='' YELLOW='' RED='' CYAN='' RESET=''
fi

STEP=0
WARNINGS=()
MANUAL_STEPS=()

# Resolved early so mode detection and is_protected() can use it before Step 5
LOCK_FILE="${TARGET_DIR}/prodops/exec/framework-lock.yaml"
IS_UPDATE="false"
PREVIOUS_VERSION=""

if [[ -f "${LOCK_FILE}" ]]; then
  IS_UPDATE="true"
  PREVIOUS_VERSION=$(python3 -c "
import sys
try:
  content = open('${LOCK_FILE}').read()
  for line in content.splitlines():
    line = line.strip()
    if line.startswith('version:'):
      print(line.split('version:',1)[1].strip().strip('\"'))
      break
except Exception:
  pass
" 2>/dev/null || grep -m1 'version:' "${LOCK_FILE}" | sed "s/.*version: *['\"]\\?\\([^'\" ]*\\).*/\\1/" 2>/dev/null || echo "unknown")
fi

step() {
  STEP=$((STEP + 1))
  printf '\n%s── Step %d: %s%s\n' "${BOLD}${CYAN}" "${STEP}" "$1" "${RESET}"
}

ok()   { printf '  %s[OK]%s   %s\n' "${GREEN}" "${RESET}" "$1"; }
skip() { printf '  %s[SKIP]%s %s\n' "${YELLOW}" "${RESET}" "$1"; }
warn() {
  printf '  %s[WARN]%s %s\n' "${YELLOW}" "${RESET}" "$1" >&2
  WARNINGS+=("$1")
}
err()  { printf '\n%s[ERROR]%s %s\n' "${RED}" "${RESET}" "$1" >&2; }
manual() { MANUAL_STEPS+=("$1"); }

usage() {
  printf 'Usage: %s --version <tag> [--target <dir>] [--skip-hooks] [--skip-claude]\n' "$0" >&2
  printf 'Example: %s --version v1.6.1\n' "$0" >&2
  exit 1
}

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { err "--version requires a value"; usage; }
      VERSION="$2"; shift 2 ;;
    --target)
      [[ $# -ge 2 ]] || { err "--target requires a value"; usage; }
      TARGET_DIR="$2"; shift 2 ;;
    --skip-hooks)  SKIP_HOOKS="true"; shift ;;
    --skip-claude) SKIP_CLAUDE="true"; shift ;;
    -h|--help) usage ;;
    *) err "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  err "--version is required"
  usage
fi

# ── Header ────────────────────────────────────────────────────────────────────

printf '\n%sProdOps Framework Installer%s\n' "${BOLD}" "${RESET}"
printf 'Version : %s\n' "${VERSION}"
printf 'Target  : %s\n' "${TARGET_DIR}"
if [[ "${IS_UPDATE}" == "true" ]]; then
  printf 'Mode    : %supdate%s (%s → %s)\n' "${CYAN}" "${RESET}" "${PREVIOUS_VERSION}" "${VERSION}"
else
  printf 'Mode    : %sfresh install%s\n' "${CYAN}" "${RESET}"
fi

# ── Step 1: Verify version ────────────────────────────────────────────────────

step "Verify framework version"

if ! gh release view "${VERSION}" --repo "${FRAMEWORK_REPO}" >/dev/null 2>&1; then
  err "Version '${VERSION}' not found in ${FRAMEWORK_REPO}"
  printf 'Available versions: gh release list --repo %s\n' "${FRAMEWORK_REPO}" >&2
  exit 1
fi

ok "Version ${VERSION} found in ${FRAMEWORK_REPO}"

# ── Step 2: Clone framework ───────────────────────────────────────────────────

step "Clone framework at ${VERSION}"

SCRATCH=$(mktemp -d)
trap 'rm -rf "${SCRATCH}"' EXIT

if ! git clone --quiet --depth 1 --branch "${VERSION}" \
    "https://github.com/${FRAMEWORK_REPO}.git" "${SCRATCH}/framework" 2>/dev/null; then
  err "Failed to clone ${FRAMEWORK_REPO} at ${VERSION}"
  exit 1
fi

ok "Cloned ${FRAMEWORK_REPO}@${VERSION}"

# ── Step 3: Create directory structure ───────────────────────────────────────

step "Create prodops/ directory structure"

mkdir -p "${TARGET_DIR}/prodops/framework"
mkdir -p "${TARGET_DIR}/prodops/skills"
mkdir -p "${TARGET_DIR}/prodops/templates"
mkdir -p "${TARGET_DIR}/prodops/exec"
mkdir -p "${TARGET_DIR}/prodops/scripts"

ok "Base directories created"

# ── Protected path check ──────────────────────────────────────────────────────

is_protected() {
  local rel="$1"
  local target_file="${TARGET_DIR}/${rel}"
  case "${rel}" in
    # Consumer root files — never touched, regardless of framework content
    README.md|README.en.md|\
    .gitignore|.gitattributes|\
    LICENSE|CHANGELOG.md)
      return 0 ;;
    # Consumer-owned paths inside prodops/ — skip only when they already exist
    prodops/artifacts/*|\
    prodops/skills/local/*|\
    prodops/exec/manifest.yaml|\
    prodops/runtime/runtime.yaml)
      [[ -e "${target_file}" ]] && return 0 ;;
  esac
  return 1
}

# ── Step 4: Copy framework content ───────────────────────────────────────────
# Only files inside prodops/ are copied. Consumer root files (README.md,
# .gitignore, LICENSE, etc.) are never reached by this loop, and is_protected()
# also guards them explicitly as a belt-and-suspenders measure.

step "Copy framework files"

FRAMEWORK_SRC="${SCRATCH}/framework"
COPIED=0
SKIPPED=0

if [[ -d "${FRAMEWORK_SRC}/prodops" ]]; then
  while IFS= read -r src_file; do
    rel="${src_file#"${FRAMEWORK_SRC}/"}"
    # Paranoia guard: reject any path that does not start with prodops/
    if [[ "${rel}" != prodops/* ]]; then
      warn "Unexpected path outside prodops/ — skipped: ${rel}"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
    if is_protected "${rel}"; then
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
    target_file="${TARGET_DIR}/${rel}"
    mkdir -p "$(dirname "${target_file}")"
    cp "${src_file}" "${target_file}"
    COPIED=$((COPIED + 1))
  done < <(find "${FRAMEWORK_SRC}/prodops" -type f | LC_ALL=C sort)
fi

ok "${COPIED} files copied, ${SKIPPED} protected files skipped"

# ── Step 5: Generate / update framework-lock.yaml ────────────────────────────

step "Generate/update prodops/exec/framework-lock.yaml"

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
  installed_version: "${VERSION}"
  available_version: "${VERSION}"
  last_checked: "$(date +%Y-%m-%d)"
  reason: >
    Versão instalada igual à versão disponível — sem drift.
    Re-checar após nova release publicada em prodops-framework.
EOF
  ok "Created prodops/exec/framework-lock.yaml (version: ${VERSION})"
else
  # Update: rewrite version fields in place, preserve all other consumer content.
  TODAY="$(date +%Y-%m-%d)"
  if python3 - "${LOCK_FILE}" "${VERSION}" "${TODAY}" <<'PYEOF' 2>/dev/null; then
import sys, re

path, version, today = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()

def replace_quoted(key, val, text):
    return re.sub(
        r'(?m)^(\s*' + re.escape(key) + r':\s*)["\']?[^"\'\n]*["\']?',
        r'\g<1>"' + val + '"',
        text,
    )

content = replace_quoted('version',           version, content)
content = replace_quoted('installed_version', version, content)
content = replace_quoted('available_version', version, content)
content = replace_quoted('last_checked',      today,   content)
content = re.sub(r'(?m)^(\s*status:\s*).*', r'\g<1>ok', content)

open(path, 'w').write(content)
PYEOF
    ok "Updated framework-lock.yaml: ${PREVIOUS_VERSION} → ${VERSION}"
  else
    warn "Could not update framework-lock.yaml automatically — update version fields manually"
    manual "Set version fields to ${VERSION} in prodops/exec/framework-lock.yaml"
  fi
fi

# ── Step 5b: Update runtime.yaml framework-version ───────────────────────────

step "Update runtime.yaml framework-version"

RUNTIME_YAML="${TARGET_DIR}/prodops/runtime/runtime.yaml"

RUNTIME_YAML_EXAMPLE="${TARGET_DIR}/prodops/runtime/runtime.yaml.example"

if [[ ! -f "${RUNTIME_YAML}" ]] && [[ -f "${RUNTIME_YAML_EXAMPLE}" ]]; then
  cp "${RUNTIME_YAML_EXAMPLE}" "${RUNTIME_YAML}"
  # Update framework-version in the freshly copied file
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
    ok "Created runtime.yaml from example (framework-version: ${VERSION})"
  else
    ok "Created runtime.yaml from example"
    warn "Could not set framework-version automatically"
    manual "Set framework-version to \"${VERSION}\" in prodops/runtime/runtime.yaml"
  fi
  manual "Fill in product-specific values in prodops/runtime/runtime.yaml (github org, project number, Datadog service, CloudEvents source)"
elif [[ ! -f "${RUNTIME_YAML}" ]]; then
  skip "prodops/runtime/runtime.yaml not found and runtime.yaml.example unavailable"
  manual "Create prodops/runtime/runtime.yaml from runtime.yaml.example when available"
else
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
    ok "Updated runtime.yaml framework-version → ${VERSION}"
  else
    warn "Could not update framework-version in runtime.yaml automatically"
    manual "Set framework-version to \"${VERSION}\" in prodops/runtime/runtime.yaml"
  fi
fi

# ── Step 6: Create .prodopsignore ─────────────────────────────────────────────

step "Create .prodopsignore"

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

# ── Product artifacts ─────────────────────────────────────────────────────────
prodops/artifacts/

# ── Operational configuration ─────────────────────────────────────────────────
prodops/exec/manifest.yaml
prodops/exec/framework-lock.yaml
prodops/exec/cards/

# ── Runtime configuration ─────────────────────────────────────────────────────
# runtime.yaml contains product-specific values (GitHub org, project number,
# Datadog service, CloudEvents source). It must not be overwritten by sync.
prodops/runtime/runtime.yaml

# ── Product-local skills ──────────────────────────────────────────────────────
prodops/skills/local/

# ── Product-local scripts ─────────────────────────────────────────────────────
prodops/scripts/local/

# ── Product-local references ──────────────────────────────────────────────────
prodops/skills/references/local/
IGNORE
  ok "Created .prodopsignore"
else
  skip ".prodopsignore already exists"
fi

# ── Step 7: Generate exec/manifest.yaml ──────────────────────────────────────

step "Generate prodops/exec/manifest.yaml"

MANIFEST_FILE="${TARGET_DIR}/prodops/exec/manifest.yaml"

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  # Pre-fill product.name and product.repository with the directory basename
  # so at least those two fields don't need manual editing.
  INFERRED_NAME="$(basename "${TARGET_DIR}")"
  cat >"${MANIFEST_FILE}" <<EOF
# prodops/exec/manifest.yaml
#
# Operational configuration for this product.
# Generated by install-prodops.sh — fill in the remaining placeholders below.
# This file is never overwritten by framework sync.
#
# Required: replace every <PLACEHOLDER> before running doctor.sh.

schema_version: 1

product:
  name: "${INFERRED_NAME}"             # e.g. "payments-api"
  org: "<GITHUB_ORG>"                  # e.g. "acme-corp"
  repository: "${INFERRED_NAME}"       # e.g. "payments-api"
  service: "<SERVICE_NAME>"            # e.g. "payments"

paths:
  obcs:               prodops/artifacts/obcs
  bdd:                prodops/artifacts/bdd
  business_intents:   prodops/artifacts/business-intents
  architecture:       prodops/artifacts/architecture
  event_storming:     prodops/artifacts/event-storming
  plans:              prodops/artifacts/plans
  reliability_plans:  prodops/artifacts/plans/reliability
  trails:             prodops/artifacts/trails
  release_trail:      prodops/artifacts/trails/release-trail.md
  evidence:           prodops/artifacts/evidence
  experiments:        prodops/artifacts/experiments
  risks:              prodops/artifacts/risks/risks.md
  product:            prodops/artifacts/product
  templates:          prodops/templates
  iteration_plan:     prodops/artifacts/plans/iteration-plan.md

skills:
  bootstrap:  prodops/skills/bootstrap/SKILL.md
  hack:       prodops/skills/hack/SKILL.md
  sync:       prodops/skills/sync/SKILL.md
  finish:     prodops/skills/finish/SKILL.md
  ship:       prodops/skills/ship/SKILL.md
  validate:   prodops/skills/validate/SKILL.md
  promote:    prodops/skills/promote/SKILL.md
  upstream:   prodops/skills/upstream/SKILL.md
  downstream: prodops/skills/downstream/SKILL.md

gates:
  lint:
    cmd: "echo 'configure your lint command here'"
    expect: 0
    when: pre-commit
  acceptance:
    cmd: "echo 'configure your acceptance test command here'"
    expect: 0
    when: pre-ship

github:
  org: "<GITHUB_ORG>"
  repository: "${INFERRED_NAME}"
  projects:
    product_repository:
      number: 0          # replace with your GitHub Project number
      name: "<PROJECT_NAME>"

diligence:
  schema_version: 1
  checks_catalog: prodops/framework/journeys/diligence/checks/catalog.yaml
  instances: prodops/artifacts/diligence
  id_policy:
    finding:     FND
    evidence:    EVD
    remediation: RMD
    waiver:      WVR
    diligence:   DIL
EOF
  ok "Created prodops/exec/manifest.yaml (name/repository pre-filled as '${INFERRED_NAME}')"
  manual "Fill in remaining placeholders in prodops/exec/manifest.yaml: <GITHUB_ORG>, <SERVICE_NAME>, <PROJECT_NAME>, github.projects.number"
else
  skip "prodops/exec/manifest.yaml already exists (protected)"
fi

# ── Step 8: Create artifacts directory tree ───────────────────────────────────

step "Create prodops/artifacts/ directory tree"

ARTIFACTS_DIRS=(
  "prodops/artifacts/obcs"
  "prodops/artifacts/bdd"
  "prodops/artifacts/business-intents"
  "prodops/artifacts/architecture"
  "prodops/artifacts/event-storming"
  "prodops/artifacts/plans/reliability"
  "prodops/artifacts/trails"
  "prodops/artifacts/evidence"
  "prodops/artifacts/experiments"
  "prodops/artifacts/risks"
  "prodops/artifacts/product"
  "prodops/artifacts/diligence"
  "prodops/skills/local"
  "prodops/skills/references/local"
  "prodops/scripts/local"
)

for dir in "${ARTIFACTS_DIRS[@]}"; do
  target_path="${TARGET_DIR}/${dir}"
  if [[ ! -d "${target_path}" ]]; then
    mkdir -p "${target_path}"
    touch "${target_path}/.gitkeep"
  fi
done

TRAILS_FILE="${TARGET_DIR}/prodops/artifacts/trails/release-trail.md"
[[ ! -f "${TRAILS_FILE}" ]] && printf '# Release Trail\n' >"${TRAILS_FILE}"

RISKS_FILE="${TARGET_DIR}/prodops/artifacts/risks/risks.md"
[[ ! -f "${RISKS_FILE}" ]] && printf '# Risks\n' >"${RISKS_FILE}"

# prodops/README.md — lido obrigatoriamente pelo agente na primeira sessão (AGENTS.md Step 0)
README_FILE="${TARGET_DIR}/prodops/README.md"
if [[ ! -f "${README_FILE}" ]]; then
  cat >"${README_FILE}" <<EOF
# ${INFERRED_NAME} — ProdOps

Este repositório usa o **ProdOps Framework**.

## Produto

- **Nome:** ${INFERRED_NAME}
- **Org GitHub:** <GITHUB_ORG>
- **Serviço:** <SERVICE_NAME>

## Jornadas

| Jornada | Skill de entrada | Quando usar |
|---|---|---|
| Delivery | \`/downstream\` | Feature, bugfix, segurança |
| Discovery | \`/upstream\` | Investigação técnica, análise |
| Diligence | \`/diligence\` | Auditoria, risco, conformidade |

## Links rápidos

- Manifesto: \`prodops/exec/manifest.yaml\`
- Princípios: \`prodops/framework/principles.md\`
- Runtime: \`prodops/runtime/runtime.yaml\`
EOF
  ok "Created prodops/README.md"
  manual "Fill in <GITHUB_ORG> and <SERVICE_NAME> in prodops/README.md"
else
  skip "prodops/README.md already exists"
fi

# Local skill and script dirs — READMEs required by doctor.sh
SKILLS_LOCAL_README="${TARGET_DIR}/prodops/skills/local/README.md"
if [[ ! -f "${SKILLS_LOCAL_README}" ]]; then
  printf '# Skills locais do %s\n\nAdicione aqui skills específicas deste produto.\n' \
    "${INFERRED_NAME}" >"${SKILLS_LOCAL_README}"
fi

REFS_LOCAL_README="${TARGET_DIR}/prodops/skills/references/local/README.md"
if [[ ! -f "${REFS_LOCAL_README}" ]]; then
  printf '# Referências de engenharia locais\n\nAdicione aqui referências específicas deste produto.\n' \
    >"${REFS_LOCAL_README}"
fi

# Engineering reference dirs required by doctor.sh
for _eng_dir in \
  "${TARGET_DIR}/prodops/skills/references/local/engineering/clean-code" \
  "${TARGET_DIR}/prodops/skills/references/local/engineering/ddd"; do
  if [[ ! -d "${_eng_dir}" ]]; then
    mkdir -p "${_eng_dir}"
    touch "${_eng_dir}/.gitkeep"
  fi
done

SCRIPTS_LOCAL_README="${TARGET_DIR}/prodops/scripts/local/README.md"
if [[ ! -f "${SCRIPTS_LOCAL_README}" ]]; then
  printf '# Scripts locais do %s\n\nAdicione aqui scripts específicos deste produto.\n' \
    "${INFERRED_NAME}" >"${SCRIPTS_LOCAL_README}"
fi

ok "Artifact directories and seed files created"

# ── Step 9: Configure git hooks ───────────────────────────────────────────────

step "Configure git commit hooks"

HOOKS_PATH="prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks"

if [[ "${SKIP_HOOKS}" == "true" ]]; then
  skip "Skipped (--skip-hooks)"
  manual "Configure git hooks manually: git config core.hooksPath ${HOOKS_PATH}"
elif ! git -C "${TARGET_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
  warn "Not a git repository — skipping hooks configuration"
  manual "Initialize git and then run: git config core.hooksPath ${HOOKS_PATH}"
elif [[ ! -d "${TARGET_DIR}/${HOOKS_PATH}" ]]; then
  warn "Hooks directory not found at ${HOOKS_PATH} — framework files may not have copied correctly"
  manual "After verifying framework files, run: git config core.hooksPath ${HOOKS_PATH}"
else
  git -C "${TARGET_DIR}" config core.hooksPath "${HOOKS_PATH}"
  ok "git config core.hooksPath → ${HOOKS_PATH}"
fi

# ── Step 10: Install Claude Code (.claude/) ───────────────────────────────────

step "Install Claude Code support (.claude/)"

INSTALL_CLAUDE="${TARGET_DIR}/prodops/scripts/install-claude.sh"

if [[ "${SKIP_CLAUDE}" == "true" ]]; then
  skip "Skipped (--skip-claude)"
  manual "Run manually: bash prodops/scripts/install-claude.sh"
elif [[ ! -f "${INSTALL_CLAUDE}" ]]; then
  warn "install-claude.sh not found — skipping"
  manual "Run manually when available: bash prodops/scripts/install-claude.sh"
else
  if bash "${INSTALL_CLAUDE}" --target "${TARGET_DIR}" 2>&1 | sed 's/^/  /'; then
    ok ".claude/ structure installed"
  else
    warn "install-claude.sh reported issues — review output above"
    manual "Re-run manually: bash prodops/scripts/install-claude.sh"
  fi
fi

# ── Step 11: Generate / update CLAUDE.md ─────────────────────────────────────

step "Generate/update CLAUDE.md"

CLAUDE_MD="${TARGET_DIR}/CLAUDE.md"

# CLAUDE.md is fully framework-owned — short pointer, no product-specific content.
# On update: compare with the canonical template; backup and overwrite if different.
CLAUDE_MD_CONTENT='# Claude Code Instructions

Leia `AGENTS.md` — é o guia operacional do repositório e a fonte de autoridade
para todos os agentes. As regras de jornada, skills, autorização e protocolo de
recebimento de trabalho estão lá.

## Comportamento específico do Claude Code

- Invoque os skills das fases via `/bootstrap`, `/hack`, `/sync`, `/finish`,
  `/ship`, `/validate`, `/promote` (e `/upstream`, `/downstream` para modo).
- Não armazenar contexto de negócio em arquivos exclusivos do Claude.
  Adicionar ou atualizar o arquivo apropriado sob `prodops/`.
- Memória: apenas convenções estáveis do repositório — decisões de release
  pertencem a `prodops/`.'

if [[ ! -f "${CLAUDE_MD}" ]]; then
  printf '%s\n' "${CLAUDE_MD_CONTENT}" >"${CLAUDE_MD}"
  ok "Created CLAUDE.md"
elif [[ "$(cat "${CLAUDE_MD}")" == "${CLAUDE_MD_CONTENT}" ]]; then
  skip "CLAUDE.md is up to date"
else
  if [[ "${IS_UPDATE}" == "true" && -n "${PREVIOUS_VERSION:-}" && "${PREVIOUS_VERSION}" != "unknown" ]]; then
    CLAUDE_BAK="${CLAUDE_MD}.${PREVIOUS_VERSION}.bak"
  else
    CLAUDE_BAK="${CLAUDE_MD}.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  cp "${CLAUDE_MD}" "${CLAUDE_BAK}"
  printf '%s\n' "${CLAUDE_MD_CONTENT}" >"${CLAUDE_MD}"
  ok "Updated CLAUDE.md (backup: $(basename "${CLAUDE_BAK}"))"
fi

# ── Step 12: Generate / update AGENTS.md ─────────────────────────────────────

step "Generate/update AGENTS.md"

AGENTS_MD="${TARGET_DIR}/AGENTS.md"

# Derive a product name from the target directory basename (used in both create and update).
PRODUCT_NAME="$(basename "${TARGET_DIR}")"

if [[ ! -f "${AGENTS_MD}" ]]; then
  cat >"${AGENTS_MD}" <<EOF
# ${PRODUCT_NAME} — Guia do Agente

## AÇÃO OBRIGATÓRIA — execute antes de responder qualquer mensagem

Este repositório usa o **ProdOps Framework**. Você **não tem contexto suficiente**
para classificar ou executar nenhum pedido sem ler os arquivos abaixo.

**Leia agora, nesta ordem, antes de responder:**

\`\`\`
1. prodops/exec/manifest.yaml
2. prodops/framework/principles.md
3. prodops/README.md
\`\`\`

Não pule essa etapa. Não responda ao usuário antes de completar essas leituras.
Se qualquer um dos arquivos não existir, informe e aguarde instrução.

Após as leituras, use o protocolo de recebimento de trabalho abaixo.
Nas etapas seguintes da mesma sessão, não releia — o contexto já está estabelecido.

## Permissões pré-autorizadas para subagentes

Todas as operações abaixo estão pré-autorizadas pelo operador para esta sessão.
Subagentes **não devem pausar para solicitar confirmação** dessas operações:

- **Read** — qualquer arquivo do repositório, incluindo:
  - \`prodops/artifacts/bdd/*.feature\`
  - \`prodops/artifacts/obcs/*.md\`
  - \`prodops/runtime/**\`
  - \`prodops/skills/**\`
  - \`prodops/framework/**\`
- **Bash** — comandos de leitura, git local, gh CLI e scripts do runtime, conforme
  prescrito pelas Skills.

---

## Protocolo de recebimento de trabalho

**Antes de qualquer ação**, classificar o pedido e propor a jornada adequada.
Nunca iniciar implementação, refatoração, correção ou criação de artefatos sem
passar por este protocolo — independentemente de quem solicita ou como.

### Passo 0 — Classificar o trabalho

| Tipo de pedido | Jornada | Skill de entrada |
|---|---|---|
| Nova feature, endpoint, comportamento de negócio | **Delivery** | \`/downstream\` |
| Correção de bug com impacto em contrato ou comportamento | **Delivery** | \`/downstream\` |
| Atualização de dependência com impacto em runtime | **Delivery** | \`/downstream\` |
| Correção de vulnerabilidade de segurança | **Delivery** | \`/downstream\` |
| Investigação, descoberta, análise técnica | **Upstream** | \`/upstream\` |
| Auditoria, risco, conformidade, sinal de negócio | **Diligence** | \`/diligence\` |
| Pergunta, explicação, leitura de código | nenhuma jornada | responder diretamente |

### Passo 1 — Verificar artefatos de produto

Para pedidos do tipo **Delivery**, antes de propor execução, verificar:

1. Existe OBC em \`prodops/artifacts/obcs/<capability>.md\`?
2. Existe BDD Feature em \`prodops/artifacts/bdd/<capability>.feature\`?
3. Risco documentado em \`prodops/artifacts/risks/risks.md\`?
4. Item no Iteration Plan com status \`Entrou\`?

### Passo 2 — Propor, não executar

Apresentar ao operador:

\`\`\`
Jornada identificada: <Delivery | Upstream | Diligence>
Skill de entrada: <skill>
Artefatos presentes: <lista>
Artefatos ausentes: <lista — bloqueia readiness>
Próxima ação proposta: <descrição>
\`\`\`

Aguardar confirmação **exceto** quando o pedido já invocou explicitamente um
skill (\`/downstream\`, \`/upstream\`, \`/hack\`, etc.) — nesse caso executar
diretamente sem parar para propor.

### Passo 3 — Executar via skill

Após confirmação, executar exclusivamente via skill correspondente.
Nunca implementar código de produção fora do ciclo Bootstrap → Hack → Sync → Finish.

---

## Como trabalhar

1. **Trabalho de Delivery:** invoque o skill da fase — \`/bootstrap\`, \`/hack\`,
   \`/sync\`, \`/finish\`, \`/ship\`, \`/validate\`, \`/promote\`.
2. **Exploração:** \`/upstream\`. **Implementação governada:** \`/downstream\`.
3. **Paths canônicos, quality gates e vocabulário:** \`prodops/exec/manifest.yaml\`
EOF
  ok "Created AGENTS.md (product name: ${PRODUCT_NAME})"
  manual "Review AGENTS.md and adjust product-specific sections (name, permissions, gates)"
else
  # On update: regenerate into a temp file and compare with the existing AGENTS.md.
  # The template uses PRODUCT_NAME which may differ from the installed version.
  AGENTS_TMP=$(mktemp)
  trap 'rm -f "${AGENTS_TMP}"' RETURN 2>/dev/null || true
  cat >"${AGENTS_TMP}" <<EOF
# ${PRODUCT_NAME} — Guia do Agente

## AÇÃO OBRIGATÓRIA — execute antes de responder qualquer mensagem

Este repositório usa o **ProdOps Framework**. Você **não tem contexto suficiente**
para classificar ou executar nenhum pedido sem ler os arquivos abaixo.

**Leia agora, nesta ordem, antes de responder:**

\`\`\`
1. prodops/exec/manifest.yaml
2. prodops/framework/principles.md
3. prodops/README.md
\`\`\`

Não pule essa etapa. Não responda ao usuário antes de completar essas leituras.
Se qualquer um dos arquivos não existir, informe e aguarde instrução.

Após as leituras, use o protocolo de recebimento de trabalho abaixo.
Nas etapas seguintes da mesma sessão, não releia — o contexto já está estabelecido.

## Permissões pré-autorizadas para subagentes

Todas as operações abaixo estão pré-autorizadas pelo operador para esta sessão.
Subagentes **não devem pausar para solicitar confirmação** dessas operações:

- **Read** — qualquer arquivo do repositório, incluindo:
  - \`prodops/artifacts/bdd/*.feature\`
  - \`prodops/artifacts/obcs/*.md\`
  - \`prodops/runtime/**\`
  - \`prodops/skills/**\`
  - \`prodops/framework/**\`
- **Bash** — comandos de leitura, git local, gh CLI e scripts do runtime, conforme
  prescrito pelas Skills.

---

## Protocolo de recebimento de trabalho

**Antes de qualquer ação**, classificar o pedido e propor a jornada adequada.
Nunca iniciar implementação, refatoração, correção ou criação de artefatos sem
passar por este protocolo — independentemente de quem solicita ou como.

### Passo 0 — Classificar o trabalho

| Tipo de pedido | Jornada | Skill de entrada |
|---|---|---|
| Nova feature, endpoint, comportamento de negócio | **Delivery** | \`/downstream\` |
| Correção de bug com impacto em contrato ou comportamento | **Delivery** | \`/downstream\` |
| Atualização de dependência com impacto em runtime | **Delivery** | \`/downstream\` |
| Correção de vulnerabilidade de segurança | **Delivery** | \`/downstream\` |
| Investigação, descoberta, análise técnica | **Upstream** | \`/upstream\` |
| Auditoria, risco, conformidade, sinal de negócio | **Diligence** | \`/diligence\` |
| Pergunta, explicação, leitura de código | nenhuma jornada | responder diretamente |

### Passo 1 — Verificar artefatos de produto

Para pedidos do tipo **Delivery**, antes de propor execução, verificar:

1. Existe OBC em \`prodops/artifacts/obcs/<capability>.md\`?
2. Existe BDD Feature em \`prodops/artifacts/bdd/<capability>.feature\`?
3. Risco documentado em \`prodops/artifacts/risks/risks.md\`?
4. Item no Iteration Plan com status \`Entrou\`?

### Passo 2 — Propor, não executar

Apresentar ao operador:

\`\`\`
Jornada identificada: <Delivery | Upstream | Diligence>
Skill de entrada: <skill>
Artefatos presentes: <lista>
Artefatos ausentes: <lista — bloqueia readiness>
Próxima ação proposta: <descrição>
\`\`\`

Aguardar confirmação **exceto** quando o pedido já invocou explicitamente um
skill (\`/downstream\`, \`/upstream\`, \`/hack\`, etc.) — nesse caso executar
diretamente sem parar para propor.

### Passo 3 — Executar via skill

Após confirmação, executar exclusivamente via skill correspondente.
Nunca implementar código de produção fora do ciclo Bootstrap → Hack → Sync → Finish.

---

## Como trabalhar

1. **Trabalho de Delivery:** invoque o skill da fase — \`/bootstrap\`, \`/hack\`,
   \`/sync\`, \`/finish\`, \`/ship\`, \`/validate\`, \`/promote\`.
2. **Exploração:** \`/upstream\`. **Implementação governada:** \`/downstream\`.
3. **Paths canônicos, quality gates e vocabulário:** \`prodops/exec/manifest.yaml\`
EOF

  if diff -q "${AGENTS_TMP}" "${AGENTS_MD}" >/dev/null 2>&1; then
    skip "AGENTS.md is up to date"
    rm -f "${AGENTS_TMP}"
  else
    if [[ "${IS_UPDATE}" == "true" && -n "${PREVIOUS_VERSION:-}" && "${PREVIOUS_VERSION}" != "unknown" ]]; then
      AGENTS_BAK="${AGENTS_MD}.${PREVIOUS_VERSION}.bak"
    else
      AGENTS_BAK="${AGENTS_MD}.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    cp "${AGENTS_MD}" "${AGENTS_BAK}"
    mv "${AGENTS_TMP}" "${AGENTS_MD}"
    ok "Updated AGENTS.md (backup: $(basename "${AGENTS_BAK}"))"
    manual "Review AGENTS.md — your customizations are in $(basename "${AGENTS_BAK}")"
  fi
fi

# ── Step 13: Run doctor.sh ────────────────────────────────────────────────────

step "Run prodops/scripts/doctor.sh"

DOCTOR_SCRIPT="${TARGET_DIR}/prodops/scripts/doctor.sh"

if [[ ! -f "${DOCTOR_SCRIPT}" ]]; then
  warn "doctor.sh not found — skipping validation"
  manual "Run validation when available: bash prodops/scripts/doctor.sh"
else
  DOCTOR_OUT=$(bash "${DOCTOR_SCRIPT}" 2>&1) || true
  DOCTOR_FAILS=$(printf '%s\n' "${DOCTOR_OUT}" | grep -c '^FAIL:' || true)
  if [[ "${DOCTOR_FAILS}" -eq 0 ]]; then
    ok "doctor.sh passed — no issues found"
  else
    warn "doctor.sh found ${DOCTOR_FAILS} issue(s) — review before committing"
    printf '%s\n' "${DOCTOR_OUT}" | grep '^FAIL:' | sed 's/^/    /' >&2
    manual "Fix doctor.sh issues then re-run: bash prodops/scripts/doctor.sh"
  fi
fi

# ── Step 14: Run validate-manifest.sh ────────────────────────────────────────

step "Run prodops/scripts/validate-manifest.sh"

VALIDATE_SCRIPT="${TARGET_DIR}/prodops/scripts/validate-manifest.sh"

if [[ ! -f "${VALIDATE_SCRIPT}" ]]; then
  warn "validate-manifest.sh not found — skipping"
  manual "Run when available: bash prodops/scripts/validate-manifest.sh"
elif grep -q '<PLACEHOLDER>' "${TARGET_DIR}/prodops/exec/manifest.yaml" 2>/dev/null; then
  skip "manifest.yaml has unfilled placeholders — skipping validation"
  manual "Fill placeholders in prodops/exec/manifest.yaml, then run: bash prodops/scripts/validate-manifest.sh"
else
  VALIDATE_OUT=$(bash "${VALIDATE_SCRIPT}" 2>&1) || true
  VALIDATE_FAILS=$(printf '%s\n' "${VALIDATE_OUT}" | grep -ci 'error\|fail' || true)
  if [[ "${VALIDATE_FAILS}" -eq 0 ]]; then
    ok "validate-manifest.sh passed"
  else
    warn "validate-manifest.sh reported issues"
    printf '%s\n' "${VALIDATE_OUT}" | sed 's/^/    /' >&2
    manual "Fix manifest issues then re-run: bash prodops/scripts/validate-manifest.sh"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

printf '\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${BOLD}" "${RESET}"
if [[ "${IS_UPDATE}" == "true" ]]; then
  printf '%sProdOps Framework updated: %s → %s%s\n' "${BOLD}${GREEN}" "${PREVIOUS_VERSION}" "${VERSION}" "${RESET}"
else
  printf '%sProdOps Framework %s installed at %s%s\n' "${BOLD}${GREEN}" "${VERSION}" "${TARGET_DIR}" "${RESET}"
fi
printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "${BOLD}" "${RESET}"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  printf '\n%sWarnings (%d):%s\n' "${YELLOW}${BOLD}" "${#WARNINGS[@]}" "${RESET}"
  for w in "${WARNINGS[@]}"; do
    printf '  %s⚠%s  %s\n' "${YELLOW}" "${RESET}" "${w}"
  done
fi

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  printf '\n%sRequired manual steps:%s\n' "${BOLD}" "${RESET}"
  IDX=1
  for m in "${MANUAL_STEPS[@]}"; do
    printf '  %s%d.%s %s\n' "${BOLD}" "${IDX}" "${RESET}" "${m}"
    IDX=$((IDX + 1))
  done
fi

printf '\n%sCommit when ready:%s\n' "${BOLD}" "${RESET}"
printf '  git add prodops/ .claude/ .prodopsignore CLAUDE.md AGENTS.md\n'
if [[ "${IS_UPDATE}" == "true" ]]; then
  printf '  git commit -m "chore(prodops): update ProdOps Framework %s → %s"\n' "${PREVIOUS_VERSION}" "${VERSION}"
else
  printf '  git commit -m "chore(prodops): install ProdOps Framework %s"\n' "${VERSION}"
fi
printf '\n'
