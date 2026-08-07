#!/usr/bin/env bash
# check-code-analysis.sh — Análise estática do código-fonte (SonarQube local)
#                          contra o quality gate do servidor
#
# Gate de AUTO-MERGE, não de merge. Um resultado vermelho aqui impede que o
# `finish request` arme o auto-merge; o PR continua aberto e mergeável à mão
# por um humano. Não é um required status check — ver
# prodops/framework/journeys/delivery/phases/finish/quality-gates.md.
#
# Analisa o código-fonte em api/src: manutenibilidade, confiabilidade e
# segurança. Não é um gate só de segurança — SAST é um subconjunto do que o
# Sonar faz. Complementar ao gate `dependencies`, que é SCA (bibliotecas de
# terceiros via Snyk). No CI o SAST remoto segue coberto pelo CodeQL — este gate
# é a contraparte local sobre o mesmo código, para falhar antes do push.
#
# Uso:
#   ./scripts/check-code-analysis.sh          # sobe/reusa o container e analisa
#   ./scripts/check-code-analysis.sh --keep   # não para o container ao final
#
# Requer Docker. Diferente do Snyk, não requer secret: o servidor SonarQube é
# efêmero e local, e o script provisiona o token nele automaticamente. Se
# SONAR_TOKEN existir no ambiente (ou em api/.env), ele tem precedência.
#
# Saída: 0 = quality gate OK          (auto-merge liberado)
#        1 = quality gate vermelho    (auto-merge bloqueado)
#        2 = erro de uso/ambiente (sem Docker, servidor não subiu) — o gate não
#            pôde rodar; o `finish request` não arma o auto-merge e registra o motivo

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

SONAR_CONTAINER="sonarqube"
SONAR_PORT="9000"
SONAR_HOST="http://localhost:${SONAR_PORT}"
SONAR_IMAGE="sonarqube:latest"
SCANNER_IMAGE="sonarsource/sonar-scanner-cli:latest"

KEEP_CONTAINER=0
[[ "${1:-}" == "--keep" ]] && KEEP_CONTAINER=1

# ── 1. Chave do projeto (do manifest) ──────────────────────────────────────────
# O manifest é a fonte canônica dos gates. Parser por indentação, sem exigir
# PyYAML — mesmo molde de check-dependencies.sh / check-coverage-threshold.sh.
[[ -f "${MANIFEST}" ]] || abort "Manifest não encontrado: ${MANIFEST}"

PROJECT_KEY=$(python3 - "${MANIFEST}" <<'PY' || true
import sys
in_gates = in_ca = False
ca_indent = None
for raw in open(sys.argv[1]):
    line = raw.rstrip("\n")
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    stripped = line.strip()
    if indent == 0:
        in_gates = stripped.startswith("gates:")
        in_ca = False
        continue
    if not in_gates:
        continue
    if stripped.startswith("code-analysis:"):
        in_ca, ca_indent = True, indent
        continue
    if in_ca:
        if indent <= ca_indent:        # saiu do bloco code-analysis
            in_ca = False
            continue
        if stripped.startswith("project_key:"):
            print(stripped.split(":", 1)[1].strip().strip('"').strip("'"))
            sys.exit(0)
sys.exit(1)
PY
)

if [[ -z "${PROJECT_KEY}" ]]; then
  abort "gates.code-analysis.project_key não encontrado em ${MANIFEST}."
fi

# ── 2. Pré-condições de ambiente ───────────────────────────────────────────────
step "Analisando código-fonte (SonarQube local) — projeto: ${PROJECT_KEY}..."

if ! command -v docker &>/dev/null; then
  abort "Docker não encontrado — o gate de análise de código não pode rodar.

O SonarQube roda como container local (mesmo molde do LocalStack no gate de
aceitação). Instale em https://docs.docker.com/get-docker/

Isto NÃO bloqueia o merge manual: o \`finish request\` apenas não arma o
auto-merge e registra o motivo no PR."
fi

if ! docker info &>/dev/null; then
  abort "Docker daemon não está rodando — o gate de análise de código não pode rodar.

Inicie o Docker Desktop e tente novamente. Isto NÃO bloqueia o merge manual:
o \`finish request\` apenas não arma o auto-merge e registra o motivo no PR."
fi

ok "Docker disponível"

# ── 3. Servidor SonarQube ──────────────────────────────────────────────────────
step "Verificando servidor SonarQube..."

CONTAINER_STATUS=$(docker inspect "${SONAR_CONTAINER}" --format '{{.State.Status}}' 2>/dev/null | tr -d '[:space:]' || true)
[[ -z "${CONTAINER_STATUS}" ]] && CONTAINER_STATUS="missing"

case "${CONTAINER_STATUS}" in
  running)
    ok "Container '${SONAR_CONTAINER}' já está rodando"
    ;;
  exited|created|paused)
    warn "Container '${SONAR_CONTAINER}' existe mas está '${CONTAINER_STATUS}' — reiniciando..."
    docker start "${SONAR_CONTAINER}" >/dev/null \
      || abort "Falha ao reiniciar o container '${SONAR_CONTAINER}'."
    ok "Container reiniciado"
    ;;
  missing)
    warn "Container '${SONAR_CONTAINER}' não existe — criando com docker run..."
    docker run -d \
      --name "${SONAR_CONTAINER}" \
      -p "127.0.0.1:${SONAR_PORT}:9000" \
      -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
      "${SONAR_IMAGE}" >/dev/null \
      || abort "Falha ao criar o container SonarQube. Verifique permissões do Docker."
    ok "Container criado (${SONAR_IMAGE})"
    ;;
  *)
    abort "Estado inesperado do container '${SONAR_CONTAINER}': ${CONTAINER_STATUS}"
    ;;
esac

# ── 4. Aguardar o servidor ficar saudável ──────────────────────────────────────
# O SonarQube sobe em ~1-2 min (Elasticsearch interno). /api/system/status
# responde antes de estar pronto, com status=STARTING — só UP serve.
step "Aguardando SonarQube ficar saudável (máx 180s)..."

MAX_WAIT=180
WAITED=0
until [[ "$(curl -sf "${SONAR_HOST}/api/system/status" 2>/dev/null | sed -n -E 's/.*"status"[[:space:]]*:[[:space:]]*"([A-Z]+)".*/\1/p')" == "UP" ]]; do
  if [[ ${WAITED} -ge ${MAX_WAIT} ]]; then
    abort "SonarQube não ficou saudável em ${MAX_WAIT}s.

Verifique os logs com:
  docker logs ${SONAR_CONTAINER}

E o endpoint:
  curl ${SONAR_HOST}/api/system/status"
  fi
  sleep 5
  WAITED=$((WAITED + 5))
  echo -n "."
done
echo ""
ok "SonarQube saudável (${SONAR_HOST})"

# ── 5. Token do scanner ────────────────────────────────────────────────────────
# Num servidor efêmero local o token é gerado no próprio servidor. Precedência:
# ambiente > api/.env > provisionamento automático via API (admin/admin, as
# credenciais default do container recém-subido).
#
# Fallback de api/.env extrai só a linha SONAR_TOKEN em vez de dar `source` no
# arquivo (evita executar conteúdo arbitrário e sobrescrever outras variáveis).
if [[ -z "${SONAR_TOKEN:-}" ]] && [[ -f "${PROJECT_DIR}/.env" ]]; then
  ENV_TOKEN=$(sed -n -E 's/^[[:space:]]*(export[[:space:]]+)?SONAR_TOKEN[[:space:]]*=[[:space:]]*"?'"'"'?([^"'"'"'#[:space:]]+).*/\2/p' "${PROJECT_DIR}/.env" | tail -1)
  if [[ -n "${ENV_TOKEN}" ]]; then
    export SONAR_TOKEN="${ENV_TOKEN}"
    ok "SONAR_TOKEN carregado de api/.env"
  fi
fi

if [[ -z "${SONAR_TOKEN:-}" ]]; then
  step "Provisionando token no servidor local..."
  # Nome único por execução: a API rejeita gerar um token com nome já existente.
  TOKEN_NAME="finish-validate-$(date +%s)"
  TOKEN_JSON=$(curl -sf -u admin:admin -X POST \
    "${SONAR_HOST}/api/user_tokens/generate?name=${TOKEN_NAME}" 2>/dev/null || true)
  SONAR_TOKEN=$(echo "${TOKEN_JSON}" | sed -n -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')

  if [[ -z "${SONAR_TOKEN}" ]]; then
    abort "Não foi possível provisionar o token no SonarQube local.

As credenciais default (admin/admin) podem ter sido alteradas neste container.
Gere um token na UI (${SONAR_HOST} → Account → Security) e exporte:
  export SONAR_TOKEN=<token>

Ou remova o container para recomeçar limpo:
  docker rm -f ${SONAR_CONTAINER}"
  fi
  export SONAR_TOKEN
  ok "Token provisionado (${TOKEN_NAME})"
else
  ok "SONAR_TOKEN fornecido pelo ambiente"
fi

# ── 5b. Quality gate próprio (sem cobertura) ──────────────────────────────────
# O quality gate default do container ("Sonar way") inclui `new_coverage >= 80`.
# Essa condição é redundante e nociva aqui: quem mede cobertura é `gates.coverage`
# (branches, limiar 100%, código inteiro) — estritamente mais rigoroso que o
# new_coverage do Sonar (linhas, 80%, só código novo). Pior, o scanner não recebe
# relatório de cobertura neste fluxo, então o Sonar leria 0.0% e reprovaria um
# código que está limpo, mascarando o veredito de segurança.
#
# Cada gate tem uma responsabilidade única (ver prodops/exec/manifest.yaml):
# cobertura é de `gates.coverage`; este gate é vulnerabilidade, code smell e
# duplicação.
#
# O servidor é efêmero, então isto é provisionado a cada execução — não dá para
# configurar pela UI e esperar que persista.
step "Provisionando quality gate sem condição de cobertura..."

QG_NAME="prodops-code-analysis"

# create é idempotente na prática: se já existe (container reusado com --keep),
# a API responde erro e seguimos para ajustar o gate existente.
curl -sf -u "${SONAR_TOKEN}:" -X POST \
  "${SONAR_HOST}/api/qualitygates/create?name=${QG_NAME}" >/dev/null 2>&1 || true

# ATENÇÃO: um gate recém-criado NÃO nasce vazio — o SonarQube o pré-popula com as
# condições CAYC ("Clean as You Code"), entre elas new_coverage >= 80. Portanto
# não basta acrescentar condições: é preciso REMOVER as de cobertura, senão o
# gate próprio reprova exatamente como o default.
QG_JSON=$(curl -sf -u "${SONAR_TOKEN}:" \
  "${SONAR_HOST}/api/qualitygates/show?name=${QG_NAME}" 2>/dev/null || true)

# Extrai o id das condições de cobertura (new_coverage e coverage) para deletar.
COVERAGE_COND_IDS=$(echo "${QG_JSON}" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for c in data.get("conditions", []):
    if c.get("metric") in ("new_coverage", "coverage"):
        print(c.get("id", ""))
' 2>/dev/null || true)

for CID in ${COVERAGE_COND_IDS}; do
  [[ -z "${CID}" ]] && continue
  curl -sf -u "${SONAR_TOKEN}:" -X POST \
    "${SONAR_HOST}/api/qualitygates/delete_condition" \
    -d "id=${CID}" >/dev/null 2>&1 || true
done

# Garante as condições que este gate de fato responde (idempotente: se já vieram
# do CAYC, a API rejeita a duplicata e seguimos).
#   new_violations > 0               → qualquer problema novo reprova
#   new_duplicated_lines_density > 3 → duplicação em código novo
for COND in "new_violations|GT|0" "new_duplicated_lines_density|GT|3"; do
  IFS='|' read -r METRIC OP VAL <<< "${COND}"
  curl -sf -u "${SONAR_TOKEN}:" -X POST \
    "${SONAR_HOST}/api/qualitygates/create_condition" \
    -d "gateName=${QG_NAME}&metric=${METRIC}&op=${OP}&error=${VAL}" >/dev/null 2>&1 || true
done

# O projeto precisa existir antes de receber o gate. Se ainda não foi analisado,
# a associação falha aqui e o scan usaria o gate default — por isso criamos o
# projeto explicitamente (idempotente).
curl -sf -u "${SONAR_TOKEN}:" -X POST \
  "${SONAR_HOST}/api/projects/create?project=${PROJECT_KEY}&name=${PROJECT_KEY}" >/dev/null 2>&1 || true

if curl -sf -u "${SONAR_TOKEN}:" -X POST \
  "${SONAR_HOST}/api/qualitygates/select" \
  -d "gateName=${QG_NAME}&projectKey=${PROJECT_KEY}" >/dev/null 2>&1; then
  ok "Quality gate '${QG_NAME}' associado (violations + duplicação; cobertura fica com gates.coverage)"
else
  warn "Não foi possível associar o quality gate '${QG_NAME}' — o scan usará o gate default do servidor.
  Isso reintroduz new_coverage >= 80, que reprova por falta de relatório de cobertura.
  O veredito abaixo pode ser um falso negativo; confira as condições em
  ${SONAR_HOST}/dashboard?id=${PROJECT_KEY}"
fi

# ── 6. Scan ────────────────────────────────────────────────────────────────────
# O scanner roda em container (não exige sonar-scanner instalado na máquina) e
# fala com o servidor pela rede do host. Analisa api/src — o código de produto;
# testes e build ficam de fora via sonar.exclusions.
step "Executando sonar-scanner sobre api/src..."
echo ""

set +e
docker run --rm \
  --network host \
  -v "${REPO_ROOT}:/usr/src" \
  -w /usr/src \
  -e SONAR_HOST_URL="${SONAR_HOST}" \
  -e SONAR_TOKEN="${SONAR_TOKEN}" \
  "${SCANNER_IMAGE}" \
  -Dsonar.projectKey="${PROJECT_KEY}" \
  -Dsonar.sources=api/src \
  -Dsonar.exclusions="**/*.spec.ts,**/node_modules/**,**/dist/**" \
  -Dsonar.qualitygate.wait=true
SCANNER_RC=$?
set -e

echo ""

# ── 7. Veredito ────────────────────────────────────────────────────────────────
# Os exit codes do sonar-scanner NÃO são documentados oficialmente pela
# SonarSource, e não distinguem de forma confiável "gate vermelho" de "erro de
# execução": um token inválido também sai com 1. Por isso o veredito vem da
# **API** (`/api/qualitygates/project_status`), que é contrato documentado —
# `projectStatus.status`: OK = passou, ERROR = vermelho. O exit code do scanner
# entra só como sinal secundário, para detectar o caso em que o scan nem chegou
# a publicar (aí a API responderia sobre uma análise antiga).
#
# Observado nesta implementação (não confiar como contrato): 0 = gate OK,
# 3 = gate vermelho, 1 = erro de execução/autenticação.
#
# A leitura acontece ANTES de parar o container — o servidor precisa estar de pé
# para responder.
# O `|| true` é necessário: sob `set -e`, uma substituição de comando que falha
# dentro de uma atribuição aborta o script com o código do curl (22 num HTTP 401)
# — antes dos aborts abaixo, que dão o diagnóstico e o exit 2 correto.
GATE_STATUS=$(curl -sf -u "${SONAR_TOKEN}:" \
  "${SONAR_HOST}/api/qualitygates/project_status?projectKey=${PROJECT_KEY}" 2>/dev/null \
  | sed -n -E 's/.*"projectStatus"[[:space:]]*:[[:space:]]*\{[[:space:]]*"status"[[:space:]]*:[[:space:]]*"([A-Z_]+)".*/\1/p') || true

if [[ ${KEEP_CONTAINER} -eq 0 ]]; then
  docker stop "${SONAR_CONTAINER}" >/dev/null 2>&1 || true
  ok "Container '${SONAR_CONTAINER}' parado (use --keep para mantê-lo de pé)"
fi

# O scanner falhou de um jeito que não é veredito de gate (rede, token, projeto
# inválido): rc != 0 e != 3. Aí a API não é fonte confiável sobre ESTE scan.
if [[ ${SCANNER_RC} -ne 0 && ${SCANNER_RC} -ne 3 ]]; then
  abort "sonar-scanner falhou na execução (código ${SCANNER_RC}) — não é um veredito
do quality gate. Verifique a rede, o token e a saída acima."
fi

if [[ -z "${GATE_STATUS}" ]]; then
  abort "Não foi possível ler o quality gate em ${SONAR_HOST}
(/api/qualitygates/project_status?projectKey=${PROJECT_KEY} não respondeu como esperado).

O gate não pôde ser avaliado — o \`finish request\` não arma o auto-merge e
registra o motivo no PR. O merge manual segue livre."
fi

case "${GATE_STATUS}" in
  OK)
    ok "Quality gate do SonarQube passou — nenhum problema bloqueante em api/src."
    ok "Auto-merge liberado."
    exit 0
    ;;
  ERROR)
    fail "Quality gate do SonarQube falhou — problemas encontrados em api/src."
    echo ""
    warn "AUTO-MERGE BLOQUEADO."
    echo ""
    echo "  Isto NÃO bloqueia o merge manual: o PR pode ser aberto normalmente e"
    echo "  mergeado por um humano após review. O que fica desarmado é apenas o"
    echo "  auto-merge (o \`gh pr merge --auto\` do step \`finish request\`)."
    echo ""
    echo "  Os achados estão em ${SONAR_HOST}/dashboard?id=${PROJECT_KEY}"
    echo "  (suba o container com --keep para inspecioná-los na UI)."
    echo ""
    echo "  A correção pertence ao ciclo TDD do Hack: retorne ao \`/hack tdd\`,"
    echo "  feche em verde e rode novamente:"
    echo "    ./scripts/check-code-analysis.sh"
    echo ""
    exit 1
    ;;
  *)
    abort "Quality gate retornou um status inesperado: '${GATE_STATUS}'.

Esperado OK ou ERROR em ${SONAR_HOST}/api/qualitygates/project_status.
O gate não pôde ser avaliado — o auto-merge fica desarmado e o merge manual
segue livre. Inspecione em ${SONAR_HOST}/dashboard?id=${PROJECT_KEY}"
    ;;
esac
