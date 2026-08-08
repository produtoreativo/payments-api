#!/usr/bin/env bash
# setup-dev.sh
#
# Prepara o ambiente local para começar o Hack.
#
# O que faz:
#   1. Verifica pré-requisitos (Git, Node, Docker, AWS CLI, gh)
#   2. Instala dependências npm (api/)
#   3. Configura Git hooks (Commit Workflow)
#   4. Verifica LocalStack (avisa, não bloqueia)
#   5. Resume o estado do ambiente
#
# Uso:
#   ./scripts/setup-dev.sh
#
# Idempotente — pode ser rodado a qualquer momento sem efeitos colaterais.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

step()  { echo -e "\n${CYAN}▶${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()  { echo -e "  ${YELLOW}!${RESET} $*"; }
fail()  { echo -e "  ${RED}✗${RESET} $*"; }
dim()   { echo -e "  ${DIM}$*${RESET}"; }

ERRORS=()
WARNINGS=()

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  setup-dev — payments-api"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

cd "$REPO_ROOT"

# ── 1. Pré-requisitos ─────────────────────────────────────────────────────────
step "Verificando pré-requisitos..."

check_required() {
  local cmd="$1" label="$2"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" --version 2>&1 | head -1)
    ok "$label — $ver"
  else
    fail "$label não encontrado"
    ERRORS+=("$label não está instalado. Instale e rode setup-dev.sh novamente.")
  fi
}

check_optional() {
  local cmd="$1" label="$2" hint="$3"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" --version 2>&1 | head -1)
    ok "$label — $ver"
  else
    warn "$label não encontrado (opcional)"
    WARNINGS+=("$label não encontrado. $hint")
  fi
}

check_required "git"    "Git"
check_required "node"   "Node.js"
check_required "npm"    "npm"
check_optional "docker" "Docker"       "Necessário para LocalStack. Instale em https://docker.com"
check_optional "aws"    "AWS CLI"      "Necessário para deploy. Instale em https://aws.amazon.com/cli"
check_optional "gh"     "GitHub CLI"   "Necessário para criar PRs. Instale em https://cli.github.com"

# ── 2. Dependências npm ───────────────────────────────────────────────────────
step "Verificando dependências npm (api/)..."

if [[ -d "$REPO_ROOT/api/node_modules" ]]; then
  ok "node_modules presente"
else
  warn "node_modules ausente — instalando..."
  (cd "$REPO_ROOT/api" && npm ci) && ok "npm ci concluído" \
    || { fail "npm ci falhou"; ERRORS+=("Falha ao instalar dependências npm. Verifique api/package.json."); }
fi

# ── 3. Git hooks ──────────────────────────────────────────────────────────────
step "Configurando Git hooks (Commit Workflow)..."

HOOKS_DIR="$REPO_ROOT/prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks"
SCRIPTS_DIR="$REPO_ROOT/prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts"
HOOKS_PATH="prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  fail "commit-workflow/hooks não encontrado em $HOOKS_PATH"
  ERRORS+=("Git hooks não configurados. Execute: git config core.hooksPath $HOOKS_PATH")
else
  # Garantir permissões de execução
  chmod +x "$HOOKS_DIR"/* 2>/dev/null || true
  chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
  ok "Permissões de execução garantidas"

  # Configurar hooksPath
  CURRENT_HOOKS=$(git config core.hooksPath 2>/dev/null || echo "")
  if [[ "$CURRENT_HOOKS" == "$HOOKS_PATH" ]]; then
    ok "core.hooksPath já configurado"
  else
    git config core.hooksPath "$HOOKS_PATH"
    ok "core.hooksPath configurado → $HOOKS_PATH"
  fi

  # Verificar hooks presentes
  for hook in pre-commit prepare-commit-msg commit-msg pre-push; do
    if [[ -x "$HOOKS_DIR/$hook" ]]; then
      dim "  hook/$hook ✓"
    else
      warn "hook/$hook ausente ou sem permissão de execução"
    fi
  done
fi

# ── 4. LocalStack ─────────────────────────────────────────────────────────────
step "Verificando LocalStack..."

if ! command -v docker &>/dev/null; then
  warn "Docker não disponível — LocalStack não pode ser verificado"
  WARNINGS+=("LocalStack requer Docker. Testes de aceitação não estarão disponíveis até instalar Docker.")
elif ! docker info &>/dev/null 2>&1; then
  warn "Docker instalado mas daemon não está rodando"
  WARNINGS+=("Inicie o Docker para rodar testes de aceitação.")
else
  LOCALSTACK_STATUS=$(docker ps --filter "name=localstack" --format "{{.Status}}" 2>/dev/null | head -1)
  if [[ "$LOCALSTACK_STATUS" == Up* ]]; then
    ok "LocalStack rodando — $LOCALSTACK_STATUS"
  elif docker ps -a --filter "name=localstack" --format "{{.Status}}" 2>/dev/null | grep -q .; then
    warn "LocalStack existe mas está parado"
    WARNINGS+=("LocalStack está parado. Para iniciar: docker start localstack  ou  ./scripts/test-acceptance.sh (inicia automaticamente)")
  else
    warn "LocalStack não encontrado"
    WARNINGS+=("LocalStack não encontrado. ./scripts/test-acceptance.sh cria e inicia automaticamente quando necessário.")
  fi
fi

# ── 5. Variáveis de ambiente ──────────────────────────────────────────────────
step "Verificando .env..."

if [[ -f "$REPO_ROOT/api/.env" ]]; then
  ok "api/.env presente"
  # Verificar vars mínimas para desenvolvimento local
  for var in AWS_DYNAMODB_ENDPOINT ASAAS_MOCK; do
    if grep -q "^${var}=" "$REPO_ROOT/api/.env" 2>/dev/null; then
      dim "  $var ✓"
    else
      warn "$var não encontrado em api/.env"
    fi
  done
else
  warn "api/.env não encontrado"
  WARNINGS+=("Crie api/.env com as variáveis locais. Veja api/.env.example se existir, ou a documentação em prodops/.")
fi

# ── 6. Resumo ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}Setup incompleto — corrija os erros abaixo:${RESET}"
  echo ""
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}✗${RESET} $err"
  done
  echo ""
  exit 1
fi

echo -e "  ${GREEN}${BOLD}Ambiente pronto para Hack${RESET}"
echo ""

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo -e "  ${YELLOW}Avisos (não bloqueiam o Hack):${RESET}"
  for w in "${WARNINGS[@]}"; do
    echo -e "  ${YELLOW}!${RESET} $w"
  done
  echo ""
fi

echo -e "  ${BOLD}Próximos passos:${RESET}"
dim "  Ler contexto       prodops/current-state/  +  AGENTS.md"
dim "  Rodar testes       ./scripts/test-acceptance.sh"
dim "  Commitar           git commit  (hooks ativos: Conventional Commits + lint)"
dim "  Gerar PR           gh pr create --body-file prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md"
echo ""
echo -e "  ${DIM}Git hooks: $(git config core.hooksPath 2>/dev/null || echo 'não configurado')${RESET}"
echo ""
