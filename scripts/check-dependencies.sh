#!/usr/bin/env bash
# check-dependencies.sh — Verifica vulnerabilidades conhecidas nas dependências
#                         (SCA via Snyk) contra o limiar de severidade exigido
#
# Gate de AUTO-MERGE, não de merge. Um resultado vermelho aqui impede que o
# `finish request` arme o auto-merge; o PR continua aberto e mergeável à mão
# por um humano. Não é um required status check — ver
# prodops/framework/journeys/delivery/phases/finish/quality-gates.md.
#
# Este gate é SCA (Software Composition Analysis): analisa as dependências de
# terceiros (api/package.json) contra o Snyk Intel DB. NÃO olha o código-fonte —
# isso é do gate `code-analysis` (SonarQube local, ./scripts/check-code-analysis.sh)
# e, no CI, do CodeQL (SAST remoto).
#
# Uso:
#   ./scripts/check-dependencies.sh              # usa o limiar do manifest
#   ./scripts/check-dependencies.sh critical     # limiar explícito de severidade
#
# Requer SNYK_TOKEN no ambiente. Sem o token o gate não pode rodar (exit 2) — o
# `finish request` então não arma o auto-merge e registra o motivo no PR.
#
# Saída: 0 = nenhuma vulnerabilidade >= limiar (auto-merge liberado)
#        1 = vulnerabilidades >= limiar          (auto-merge bloqueado)
#        2 = erro de uso/ambiente (SNYK_TOKEN ausente, snyk indisponível)

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${BOLD}${BLUE}[$(date +%H:%M:%S)]${RESET} $*"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
fail()  { echo -e "  ${RED}✗${RESET} $*"; }
abort() { echo -e "\n${RED}${BOLD}ERRO: $*${RESET}\n" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MANIFEST="${REPO_ROOT}/prodops/exec/manifest.yaml"
PROJECT_DIR="${REPO_ROOT}/api"

# ── 1. Limiar de severidade ────────────────────────────────────────────────────
# Precedência: argumento > manifest. O manifest é a fonte canônica dos gates.
THRESHOLD="${1:-}"

if [[ -z "${THRESHOLD}" ]]; then
  [[ -f "${MANIFEST}" ]] || abort "Manifest não encontrado: ${MANIFEST}"
  THRESHOLD=$(python3 - "${MANIFEST}" <<'PY'
import sys
# Lê gates.dependencies.severity_threshold sem exigir PyYAML: percorre as
# linhas rastreando a indentação, para não casar um campo de outro gate.
in_gates = in_dep = False
dep_indent = None
for raw in open(sys.argv[1]):
    line = raw.rstrip("\n")
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    stripped = line.strip()
    if indent == 0:
        in_gates = stripped.startswith("gates:")
        in_dep = False
        continue
    if not in_gates:
        continue
    if stripped.startswith("dependencies:"):
        in_dep, dep_indent = True, indent
        continue
    if in_dep:
        if indent <= dep_indent:      # saiu do bloco dependencies
            in_dep = False
            continue
        if stripped.startswith("severity_threshold:"):
            print(stripped.split(":", 1)[1].strip())
            sys.exit(0)
sys.exit(1)
PY
) || abort "gates.dependencies.severity_threshold não encontrado em ${MANIFEST}.
Passe o limiar explicitamente: ./scripts/check-dependencies.sh <low|medium|high|critical>"
fi

case "${THRESHOLD}" in
  low|medium|high|critical) ;;
  *) abort "Limiar inválido: '${THRESHOLD}'. Use low, medium, high ou critical." ;;
esac

# ── 2. Pré-condições de ambiente ────────────────────────────────────────────────
step "Verificando dependências (SCA/Snyk) — limiar de severidade: ${THRESHOLD}..."

# Fallback local: se SNYK_TOKEN não veio do ambiente (o CI o injeta via secret),
# tenta ler de api/.env — que é gitignorado. Extrai só a linha SNYK_TOKEN em vez
# de dar `source` no arquivo inteiro (evita executar conteúdo arbitrário e
# sobrescrever outras variáveis). Precedência: ambiente > api/.env. Quem usa
# `npx snyk auth` não precisa da variável — a CLI acha o token em ~/.config.
if [[ -z "${SNYK_TOKEN:-}" ]] && [[ -f "${PROJECT_DIR}/.env" ]]; then
  ENV_TOKEN=$(sed -n -E 's/^[[:space:]]*(export[[:space:]]+)?SNYK_TOKEN[[:space:]]*=[[:space:]]*"?'"'"'?([^"'"'"'#[:space:]]+).*/\2/p' "${PROJECT_DIR}/.env" | tail -1)
  if [[ -n "${ENV_TOKEN}" ]]; then
    export SNYK_TOKEN="${ENV_TOKEN}"
    ok "SNYK_TOKEN carregado de api/.env"
  fi
fi

if [[ -z "${SNYK_TOKEN:-}" ]]; then
  abort "SNYK_TOKEN ausente no ambiente — o gate de dependências não pode rodar.

O snyk test autentica contra o serviço Snyk; sem o token o scan não acontece.
Isto NÃO bloqueia o merge manual: o \`finish request\` apenas não arma o
auto-merge e registra o motivo no PR.

Para armar o gate, cadastre o secret (ação de admin):
  gh secret set SNYK_TOKEN -R <owner>/<repo>
e exponha-o no ambiente/CI como SNYK_TOKEN."
fi

# npx --no-install evita baixar snyk silenciosamente: exige que ele esteja nas
# devDependencies (api/package.json), coerente com o princípio "zero dependência
# surpresa" do Commit Workflow.
if ! (cd "${PROJECT_DIR}" && npx --no-install snyk --version) >/dev/null 2>&1; then
  abort "snyk não está disponível em ${PROJECT_DIR}.

Adicione-o às devDependencies e instale:
  cd api && npm install --save-dev snyk && npm ci"
fi

# ── 3. Scan ─────────────────────────────────────────────────────────────────────
# snyk test sai com código 1 quando encontra vulnerabilidades >= --severity-threshold,
# 0 quando limpo, e >=2 em erros de execução. Traduzimos isso nos exit codes do gate.
set +e
SNYK_OUT=$(cd "${PROJECT_DIR}" && npx --no-install snyk test --severity-threshold="${THRESHOLD}" 2>&1)
SNYK_RC=$?
set -e

echo "${SNYK_OUT}"
echo ""

case "${SNYK_RC}" in
  0)
    ok "Nenhuma vulnerabilidade de severidade >= ${THRESHOLD} nas dependências."
    ok "Auto-merge liberado."
    exit 0
    ;;
  1)
    fail "Vulnerabilidades de severidade >= ${THRESHOLD} encontradas nas dependências."
    echo ""
    warn "AUTO-MERGE BLOQUEADO."
    echo ""
    echo "  Isto NÃO bloqueia o merge manual: o PR pode ser aberto normalmente e"
    echo "  mergeado por um humano após review. O que fica desarmado é apenas o"
    echo "  auto-merge (o \`gh pr merge --auto\` do step \`finish request\`)."
    echo ""
    echo "  Para liberar o auto-merge, corrija/atualize as dependências apontadas"
    echo "  acima (\`snyk fix\` ou bump manual) e rode novamente:"
    echo "    ./scripts/check-dependencies.sh"
    echo ""
    exit 1
    ;;
  *)
    abort "snyk test falhou na execução (código ${SNYK_RC}) — não é um veredito de
vulnerabilidade. Verifique o token, a rede e a saída acima."
    ;;
esac
