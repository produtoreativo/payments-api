#!/usr/bin/env bash
# check-coverage-threshold.sh — Verifica se a cobertura atinge o limiar exigido
#
# Gate de AUTO-MERGE, não de merge. Um resultado vermelho aqui impede que o
# `finish request` arme o auto-merge; o PR continua aberto e mergeável à mão
# por um humano. Não é um required status check — ver
# prodops/framework/journeys/delivery/phases/finish/quality-gates.md.
#
# Uso:
#   ./scripts/check-coverage-threshold.sh              # usa o limiar do manifest
#   ./scripts/check-coverage-threshold.sh 80           # limiar explícito (%)
#   COVERAGE_XML=path ./scripts/check-coverage-threshold.sh
#
# Saída: 0 = cobertura >= limiar (auto-merge liberado)
#        1 = cobertura < limiar  (auto-merge bloqueado)
#        2 = erro de uso/ambiente (XML ausente ou inválido)

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

COVERAGE_XML="${COVERAGE_XML:-${REPO_ROOT}/api/coverage/cobertura-coverage.xml}"
MANIFEST="${REPO_ROOT}/prodops/exec/manifest.yaml"

# ── 1. Limiar ──────────────────────────────────────────────────────────────────
# Precedência: argumento > manifest. O manifest é a fonte canônica dos gates.
THRESHOLD="${1:-}"

if [[ -z "${THRESHOLD}" ]]; then
  [[ -f "${MANIFEST}" ]] || abort "Manifest não encontrado: ${MANIFEST}"
  THRESHOLD=$(python3 - "${MANIFEST}" <<'PY'
import sys
# Lê gates.coverage.threshold_pct sem exigir PyYAML instalado: percorre as
# linhas rastreando a indentação, para não casar um threshold_pct de outro gate.
in_gates = in_cov = False
cov_indent = None
for raw in open(sys.argv[1]):
    line = raw.rstrip("\n")
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    stripped = line.strip()
    if indent == 0:
        in_gates = stripped.startswith("gates:")
        in_cov = False
        continue
    if not in_gates:
        continue
    if stripped.startswith("coverage:"):
        in_cov, cov_indent = True, indent
        continue
    if in_cov:
        if indent <= cov_indent:      # saiu do bloco coverage
            in_cov = False
            continue
        if stripped.startswith("threshold_pct:"):
            print(stripped.split(":", 1)[1].strip())
            sys.exit(0)
sys.exit(1)
PY
) || abort "gates.coverage.threshold_pct não encontrado em ${MANIFEST}.
Passe o limiar explicitamente: ./scripts/check-coverage-threshold.sh <pct>"
fi

if ! [[ "${THRESHOLD}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  abort "Limiar inválido: '${THRESHOLD}'. Use um número (ex.: 100)."
fi

# ── 2. Relatório de cobertura ──────────────────────────────────────────────────
step "Verificando cobertura contra o limiar de ${THRESHOLD}%..."

if [[ ! -f "${COVERAGE_XML}" ]]; then
  abort "Relatório de cobertura não encontrado: ${COVERAGE_XML}

Rode a suíte de aceitação antes — é ela que gera o XML:
  ./scripts/test-acceptance.sh"
fi

# Usa as CONTAGENS (branches-covered/branches-valid), não o branch-rate: o rate
# vem arredondado em 4 casas e exibiria 1.0000 para 99,995%, deixando passar um
# branch descoberto num limiar de 100%.
METRICS=$(python3 - "${COVERAGE_XML}" <<'PY'
import sys, xml.etree.ElementTree as ET
try:
    root = ET.parse(sys.argv[1]).getroot()
except Exception as e:
    print(f"PARSE_ERROR {e}"); sys.exit(0)
if root.tag != "coverage":
    print(f"PARSE_ERROR raiz inesperada: <{root.tag}>"); sys.exit(0)
try:
    bc = int(root.get("branches-covered")); bv = int(root.get("branches-valid"))
    lc = int(root.get("lines-covered"));    lv = int(root.get("lines-valid"))
except (TypeError, ValueError):
    print("PARSE_ERROR atributos de cobertura ausentes no XML"); sys.exit(0)
# Sem branches no projeto, o gate de branches é vacuamente satisfeito.
brate = (bc / bv * 100) if bv else 100.0
lrate = (lc / lv * 100) if lv else 100.0
print(f"OK {brate:.4f} {bc} {bv} {lrate:.4f} {lc} {lv}")
PY
)

case "${METRICS}" in
  PARSE_ERROR*) abort "XML de cobertura inválido (${COVERAGE_XML}): ${METRICS#PARSE_ERROR }" ;;
esac

read -r _ BRANCH_PCT BRANCHES_COVERED BRANCHES_VALID LINE_PCT LINES_COVERED LINES_VALID <<<"${METRICS}"

# ── 3. Veredito ────────────────────────────────────────────────────────────────
# A métrica do gate é BRANCHES — critério mais rigoroso e o que indica caminhos
# efetivamente exercitados. Linhas entram só como informação de contexto.
echo ""
echo -e "  ${BOLD}branches${RESET}  ${BRANCH_PCT}%  (${BRANCHES_COVERED}/${BRANCHES_VALID})   ← métrica do gate"
echo -e "  ${BOLD}linhas${RESET}    ${LINE_PCT}%  (${LINES_COVERED}/${LINES_VALID})   (informativo)"
echo ""

PASSED=$(python3 -c "print('yes' if float('${BRANCH_PCT}') >= float('${THRESHOLD}') else 'no')")

if [[ "${PASSED}" == "yes" ]]; then
  ok "Cobertura de branches ${BRANCH_PCT}% atinge o limiar de ${THRESHOLD}%."
  ok "Auto-merge liberado."
  exit 0
fi

MISSING=$(( BRANCHES_VALID - BRANCHES_COVERED ))
fail "Cobertura de branches ${BRANCH_PCT}% abaixo do limiar de ${THRESHOLD}%."
echo ""
warn "AUTO-MERGE BLOQUEADO — faltam ${MISSING} branches sem cobertura."
echo ""
echo "  Isto NÃO bloqueia o merge manual: o PR pode ser aberto normalmente e"
echo "  mergeado por um humano após review. O que fica desarmado é apenas o"
echo "  auto-merge (o \`gh pr merge --auto\` do step \`finish request\`)."
echo ""
echo "  Para liberar o auto-merge, cubra os branches restantes com testes de"
echo "  aceitação (ciclo TDD do Hack) e rode novamente:"
echo "    ./scripts/test-acceptance.sh && ./scripts/check-coverage-threshold.sh"
echo ""
exit 1
