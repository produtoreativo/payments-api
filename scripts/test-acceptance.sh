#!/usr/bin/env bash
# test-acceptance.sh — Garante que o LocalStack está rodando e executa os testes de aceitação
#
# Uso:
#   ./scripts/test-acceptance.sh          # roda todos os specs
#   ./scripts/test-acceptance.sh criar    # roda apenas criar-invoice
#   ./scripts/test-acceptance.sh boleto   # roda apenas criar-invoice-boleto
#   ./scripts/test-acceptance.sh cancelar
#   ./scripts/test-acceptance.sh confirmar
#   ./scripts/test-acceptance.sh token

set -euo pipefail

# ── Cores ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${BOLD}${BLUE}[$(date +%H:%M:%S)]${RESET} $*"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
abort() { echo -e "\n${RED}${BOLD}ERRO: $*${RESET}\n" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
API_DIR="${REPO_ROOT}/api"

LOCALSTACK_CONTAINER="localstack"
LOCALSTACK_PORT="4566"
LOCALSTACK_ENDPOINT="http://localhost:${LOCALSTACK_PORT}"
LOCALSTACK_HEALTH="${LOCALSTACK_ENDPOINT}/_localstack/health"
LOCALSTACK_IMAGE="localstack/localstack:4"

# ── 1. Docker ──────────────────────────────────────────────────────────────────
step "Verificando Docker..."

if ! command -v docker &>/dev/null; then
  abort "Docker não encontrado. Instale em https://docs.docker.com/get-docker/"
fi

if ! docker info &>/dev/null; then
  abort "Docker daemon não está rodando. Inicie o Docker Desktop e tente novamente."
fi

ok "Docker disponível"

# ── 2. LocalStack ──────────────────────────────────────────────────────────────
step "Verificando LocalStack..."

CONTAINER_STATUS=$(docker inspect "${LOCALSTACK_CONTAINER}" --format '{{.State.Status}}' 2>/dev/null | tr -d '[:space:]' || true)
[[ -z "${CONTAINER_STATUS}" ]] && CONTAINER_STATUS="missing"

case "${CONTAINER_STATUS}" in
  running)
    ok "Container '${LOCALSTACK_CONTAINER}' já está rodando"
    ;;
  exited|created|paused)
    warn "Container '${LOCALSTACK_CONTAINER}' existe mas está '${CONTAINER_STATUS}' — reiniciando..."
    docker start "${LOCALSTACK_CONTAINER}" >/dev/null \
      || abort "Falha ao reiniciar o container '${LOCALSTACK_CONTAINER}'."
    ok "Container reiniciado"
    ;;
  missing)
    warn "Container '${LOCALSTACK_CONTAINER}' não existe — criando com docker run..."
    docker run -d \
      --name "${LOCALSTACK_CONTAINER}" \
      -p "127.0.0.1:${LOCALSTACK_PORT}:4566" \
      -e SERVICES=dynamodb,sqs \
      -e DEBUG=0 \
      "${LOCALSTACK_IMAGE}" >/dev/null \
      || abort "Falha ao criar o container LocalStack. Verifique permissões do Docker."
    ok "Container criado (${LOCALSTACK_IMAGE})"
    ;;
  *)
    abort "Estado inesperado do container '${LOCALSTACK_CONTAINER}': ${CONTAINER_STATUS}"
    ;;
esac

# ── 3. Aguardar LocalStack ficar saudável ──────────────────────────────────────
step "Aguardando LocalStack ficar saudável (máx 60s)..."

MAX_WAIT=60
WAITED=0
until curl -sf "${LOCALSTACK_HEALTH}" >/dev/null 2>&1; do
  if [[ ${WAITED} -ge ${MAX_WAIT} ]]; then
    abort "LocalStack não ficou saudável em ${MAX_WAIT}s.

Verifique os logs com:
  docker logs ${LOCALSTACK_CONTAINER}

E o endpoint:
  curl ${LOCALSTACK_HEALTH}"
  fi
  sleep 2
  WAITED=$((WAITED + 2))
  echo -n "."
done
echo ""
ok "LocalStack saudável (${LOCALSTACK_ENDPOINT})"

# ── 4. Node / npm ─────────────────────────────────────────────────────────────
step "Verificando Node.js..."

# nvm e outros version managers só ativam o node em shells interativos.
# Procuramos o node/npm no PATH e nas localizações comuns do nvm/fnm/volta.
NODE_BIN=""
for candidate in \
    "$(command -v node 2>/dev/null)" \
    "${NVM_BIN:-}/node" \
    "${HOME}/.nvm/versions/node/$(ls "${HOME}/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1)/bin/node" \
    "${HOME}/.volta/bin/node" \
    "/opt/homebrew/bin/node" \
    "/usr/local/bin/node"; do
  if [[ -x "${candidate}" ]]; then
    NODE_BIN="${candidate}"
    break
  fi
done

[[ -z "${NODE_BIN}" ]] && abort "Node.js não encontrado.
Instale via https://nodejs.org ou via nvm/volta, e garanta que está no PATH."

NODE_DIR="$(dirname "${NODE_BIN}")"
export PATH="${NODE_DIR}:${PATH}"

ok "Node.js: $(node --version)  →  ${NODE_BIN}"

step "Verificando dependências Node..."

if [[ ! -d "${API_DIR}/node_modules" ]]; then
  warn "node_modules ausente — executando npm ci..."
  (cd "${API_DIR}" && npm ci) \
    || abort "Falha no npm ci. Verifique package-lock.json e conexão com a internet."
  ok "Dependências instaladas"
else
  ok "node_modules presente"
fi

# ── 5. Selecionar specs ────────────────────────────────────────────────────────
FILTER="${1:-}"
case "${FILTER}" in
  criar)     SPECS="test/criar-invoice.e2e-spec.ts" ;;
  boleto)    SPECS="test/criar-invoice-boleto.e2e-spec.ts" ;;
  cancelar)  SPECS="test/cancelar-invoice.e2e-spec.ts" ;;
  confirmar) SPECS="test/confirmar-pagamento.e2e-spec.ts" ;;
  token)     SPECS="test/api-token.acceptance.e2e-spec.ts" ;;
  webhook)   SPECS="test/webhook-configuration.e2e-spec.ts" ;;
  "")
    SPECS="test/criar-invoice.e2e-spec.ts \
           test/criar-invoice-boleto.e2e-spec.ts \
           test/cancelar-invoice.e2e-spec.ts \
           test/confirmar-pagamento.e2e-spec.ts \
           test/api-token.acceptance.e2e-spec.ts \
           test/webhook-configuration.e2e-spec.ts"
    ;;
  *)
    abort "Filtro inválido: '${FILTER}'. Use: criar | boleto | cancelar | confirmar | token | webhook"
    ;;
esac

# ── 6. Rodar testes ────────────────────────────────────────────────────────────
step "Executando testes de aceitação${FILTER:+ [${FILTER}]}..."
echo ""

cd "${API_DIR}"

export AWS_DYNAMODB_ENDPOINT="${LOCALSTACK_ENDPOINT}"
export AWS_SQS_ENDPOINT="${LOCALSTACK_ENDPOINT}"
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export NODE_ENV="test"

# shellcheck disable=SC2086
npx jest \
  --config ./test/jest-e2e.json \
  ${SPECS} \
  --maxWorkers=1 \
  --forceExit \
  --verbose
