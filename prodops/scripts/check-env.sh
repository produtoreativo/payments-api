#!/usr/bin/env bash
# check-env.sh — Verifica se todas as ferramentas necessárias para desenvolver
#                neste repositório estão instaladas e configuradas.
#
# Uso:
#   bash prodops/scripts/check-env.sh
#   bash prodops/scripts/check-env.sh --fix-hints   (exibe comandos de instalação)
#
# Saída:
#   ✅  ferramenta OK
#   ⚠️  ferramenta presente mas com aviso (versão abaixo do mínimo, etc.)
#   ❌  ferramenta ausente ou inacessível
#
# Exit code:
#   0  tudo OK (nenhum ❌)
#   1  pelo menos um ❌

set -euo pipefail

# ── Cores ─────────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

# ── Modo --fix-hints ───────────────────────────────────────────────────────────
FIX_HINTS=false
for arg in "$@"; do
  [[ "$arg" == "--fix-hints" ]] && FIX_HINTS=true
done

# ── Contadores ────────────────────────────────────────────────────────────────
PASS=0
WARN=0
FAIL=0

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✅  $*${RESET}";  (( PASS++ )) || true; }
warn() { echo -e "  ${YELLOW}⚠️   $*${RESET}"; (( WARN++ )) || true; }
fail() { echo -e "  ${RED}❌  $*${RESET}";   (( FAIL++ )) || true; }
hint() { $FIX_HINTS && echo -e "       ${YELLOW}→ $*${RESET}" || true; }
section() { echo -e "\n${BOLD}$*${RESET}"; }

# Compara versões no formato X.Y.Z — retorna 0 se $1 >= $2
version_gte() {
  python3 -c "
import sys
a = tuple(int(x) for x in '$1'.split('.')[:3])
b = tuple(int(x) for x in '$2'.split('.')[:3])
sys.exit(0 if a >= b else 1)
" 2>/dev/null
}

# ── Cabeçalho ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   clawfight — verificação de ambiente    ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"

# ══════════════════════════════════════════════════════════════════════════════
section "1. Runtime — Node.js e npm"
# ══════════════════════════════════════════════════════════════════════════════

if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version | sed 's/v//')
  if version_gte "$NODE_VER" "20.0.0"; then
    ok "node v${NODE_VER} (≥ 20 exigido)"
  else
    warn "node v${NODE_VER} — versão mínima é 20. Testes e build podem falhar."
    hint "Use nvm: nvm install 20 && nvm use 20"
  fi
else
  fail "node não encontrado"
  hint "Instale via https://nodejs.org ou: brew install node@20"
fi

if command -v npm >/dev/null 2>&1; then
  NPM_VER=$(npm --version)
  ok "npm v${NPM_VER}"
else
  fail "npm não encontrado (normalmente vem com Node)"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "2. Dependências do workspace"
# ══════════════════════════════════════════════════════════════════════════════

if [[ -d node_modules ]]; then
  ok "node_modules presente (npm install já executado)"
else
  warn "node_modules ausente — execute: npm install"
  hint "npm install"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "3. Git e GitHub CLI"
# ══════════════════════════════════════════════════════════════════════════════

if command -v git >/dev/null 2>&1; then
  GIT_VER=$(git --version | awk '{print $3}')
  ok "git v${GIT_VER}"
else
  fail "git não encontrado"
  hint "brew install git  (macOS)"
fi

if command -v gh >/dev/null 2>&1; then
  GH_VER=$(gh --version | head -1 | awk '{print $3}')
  if gh auth status >/dev/null 2>&1; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
    ok "gh v${GH_VER} — autenticado como @${GH_USER}"
  else
    warn "gh v${GH_VER} presente mas NÃO autenticado (necessário para ProdOps)"
    hint "gh auth login"
  fi
else
  fail "gh (GitHub CLI) não encontrado — necessário para ProdOps e criação de PRs/issues"
  hint "brew install gh  |  https://cli.github.com"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "4. AWS CLI e CDK"
# ══════════════════════════════════════════════════════════════════════════════

if command -v aws >/dev/null 2>&1; then
  AWS_VER=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
  ok "aws-cli v${AWS_VER}"
else
  warn "aws CLI não encontrado — necessário para deploy em produção (opcional em dev local)"
  hint "brew install awscli  |  https://aws.amazon.com/cli/"
fi

if command -v cdk >/dev/null 2>&1; then
  CDK_VER=$(cdk --version 2>/dev/null | awk '{print $1}')
  ok "aws-cdk v${CDK_VER}"
else
  warn "cdk não encontrado — necessário apenas para deploy de infra (opcional em dev local)"
  hint "npm install -g aws-cdk"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "5. Docker e LocalStack (emulação local de AWS)"
# ══════════════════════════════════════════════════════════════════════════════

if command -v docker >/dev/null 2>&1; then
  DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
  if docker info >/dev/null 2>&1; then
    ok "docker v${DOCKER_VER} — daemon em execução"
  else
    warn "docker v${DOCKER_VER} instalado mas daemon não está rodando"
    hint "Inicie o Docker Desktop ou: sudo systemctl start docker"
  fi
else
  fail "docker não encontrado — necessário para LocalStack (DynamoDB local)"
  hint "https://docs.docker.com/get-docker/  |  brew install --cask docker"
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE_VER=$(docker compose version --short 2>/dev/null || echo "?")
  ok "docker compose v${COMPOSE_VER}"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_VER=$(docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "?")
  ok "docker-compose v${COMPOSE_VER} (standalone)"
else
  fail "docker compose não encontrado — necessário para subir LocalStack"
  hint "Instale Docker Desktop (inclui compose) ou: brew install docker-compose"
fi

# Verifica se o LocalStack está acessível (opcional — pode não estar rodando)
if curl -sf http://localhost:4566/_localstack/health >/dev/null 2>&1; then
  ok "LocalStack respondendo em localhost:4566"
else
  warn "LocalStack não está em execução (normal — sobe apenas quando necessário)"
  hint "Para subir: npm run local:start  (ou: docker compose up -d)"
fi

# cdklocal (opcional)
if command -v cdklocal >/dev/null 2>&1; then
  CDKLOCAL_VER=$(cdklocal --version 2>/dev/null | awk '{print $1}' || echo "?")
  ok "cdklocal v${CDKLOCAL_VER} (deploy de infra local via LocalStack)"
else
  warn "cdklocal não encontrado — necessário apenas para o fluxo de deploy completo local"
  hint "npm install -g aws-cdk-local"
fi

# awslocal (opcional)
if command -v awslocal >/dev/null 2>&1; then
  ok "awslocal presente (wrapper para AWS CLI contra LocalStack)"
else
  warn "awslocal não encontrado — opcional; facilita comandos manuais contra LocalStack"
  hint "pip3 install awscli-local"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "6. Python e dependências de script"
# ══════════════════════════════════════════════════════════════════════════════

if command -v python3 >/dev/null 2>&1; then
  PY_VER=$(python3 --version | awk '{print $2}')
  ok "python3 v${PY_VER}"
  if python3 -c "import yaml" 2>/dev/null; then
    ok "PyYAML disponível (python3 -c 'import yaml')"
  else
    warn "PyYAML não instalado — alguns scripts ProdOps podem falhar"
    hint "pip3 install pyyaml"
  fi
else
  warn "python3 não encontrado — necessário por scripts ProdOps (yaml parsing)"
  hint "brew install python3"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "7. Shell e ferramentas auxiliares"
# ══════════════════════════════════════════════════════════════════════════════

# bash ≥ 4 — materialize-skills.sh e materialize-agents.sh usam mapfile (bash 4+)
# macOS entrega bash 3.2 por padrão via /bin/bash
BASH_VER="${BASH_VERSION%%(*}"
BASH_MAJOR="${BASH_VER%%.*}"
if [[ "${BASH_MAJOR}" -ge 4 ]]; then
  ok "bash v${BASH_VER} (≥ 4 exigido para mapfile — materialize-skills/agents)"
else
  fail "bash v${BASH_VER} — versão mínima é 4. materialize-skills.sh e materialize-agents.sh falharão."
  hint "brew install bash && sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'"
fi

# awk — parsing de manifest e JSON fallback em vários scripts
if command -v awk >/dev/null 2>&1; then
  ok "awk presente (parsing de manifest, export-framework.sh, runtime-doctor.sh)"
else
  fail "awk não encontrado — validate-manifest.sh, export-framework.sh e local/sync.sh falharão"
  hint "brew install gawk"
fi

# diff — sync-from-framework.sh (--check mode) e install-prodops.sh (AGENTS.md comparison)
if command -v diff >/dev/null 2>&1; then
  ok "diff presente (sync-from-framework.sh --check, comparação de AGENTS.md)"
else
  fail "diff não encontrado — sync-from-framework.sh produzirá resultado incorreto silenciosamente"
  hint "brew install diffutils"
fi

# sed — verifica variante; macOS usa BSD sed, scripts usam 'sed -i \"\"' (BSD) vs 'sed -i' (GNU)
if command -v sed >/dev/null 2>&1; then
  if sed --version >/dev/null 2>&1; then
    ok "sed GNU presente (prepare-release.sh, sync-from-framework.sh)"
  else
    warn "sed BSD (macOS) — scripts usam 'sed -i \"\"'; em CI Linux com GNU sed pode diferir"
    hint "Para GNU sed: brew install gnu-sed  (disponível como gsed)"
  fi
else
  fail "sed não encontrado"
fi

if command -v jq >/dev/null 2>&1; then
  JQ_VER=$(jq --version | sed 's/jq-//')
  ok "jq v${JQ_VER} (parsing JSON em scripts de runtime ProdOps)"
else
  fail "jq não encontrado — usado em prodops/runtime/github/sync.sh, project-cleanup.sh e emit.sh"
  hint "brew install jq"
fi

if command -v curl >/dev/null 2>&1; then
  CURL_VER=$(curl --version | head -1 | awk '{print $2}')
  ok "curl v${CURL_VER} (healthcheck LocalStack, Datadog send.sh)"
else
  fail "curl não encontrado"
  hint "brew install curl"
fi

# uuidgen — geração de correlation-id e execution-id nos eventos ProdOps
if command -v uuidgen >/dev/null 2>&1; then
  ok "uuidgen presente (geração de correlation-id / execution-id nos eventos ProdOps)"
else
  if python3 -c "import uuid; print(uuid.uuid4())" >/dev/null 2>&1; then
    warn "uuidgen não encontrado — python3 uuid será usado como fallback (compatível)"
    hint "Em macOS/Linux uuidgen costuma vir pré-instalado; verifique o PATH"
  else
    fail "uuidgen não encontrado e python3 uuid indisponível — geração de IDs de evento falhará"
    hint "macOS: uuidgen vem do sistema. Linux: apt install uuid-runtime"
  fi
fi

# ripgrep — usado em prodops/scripts/doctor.sh (fallback para grep disponível)
if command -v rg >/dev/null 2>&1; then
  RG_VER=$(rg --version | head -1 | awk '{print $2}')
  ok "rg (ripgrep) v${RG_VER} — doctor.sh usa rg para busca de stale-refs"
else
  warn "rg (ripgrep) não encontrado — doctor.sh usará grep como fallback (funcional, mais lento)"
  hint "brew install ripgrep"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "8. Variáveis de ambiente"
# ══════════════════════════════════════════════════════════════════════════════

# .env na raiz (dev local)
if [[ -f .env ]]; then
  ok ".env presente na raiz do repositório"
else
  warn ".env não encontrado — crie a partir de .env.example (se existir) antes de rodar o backend"
  [[ -f .env.example ]] && hint "cp .env.example .env  e preencha os valores"
fi

# Variáveis críticas em ambiente
check_env_var() {
  local var="$1" desc="$2" required="${3:-optional}"
  if [[ -n "${!var:-}" ]]; then
    ok "${var} definida"
  elif [[ "$required" == "required" ]]; then
    fail "${var} não definida — ${desc}"
  else
    warn "${var} não definida (${desc})"
  fi
}

check_env_var "JWT_SECRET"         "necessária para assinar tokens JWT"                            "optional"
check_env_var "USER_REPO"          "repositório de usuários: 'inmemory' (dev) | 'dynamo' (prod)"  "optional"
check_env_var "EMAIL_PROVIDER"     "provider de email: 'console' (dev) | 'onesignal' (prod)"      "optional"
check_env_var "AWS_REGION"         "região AWS para deploy e LocalStack"                           "optional"
check_env_var "NEWSLETTER_REPO"    "repositório de newsletter: 'inmemory' | 'dynamo'"             "optional"
check_env_var "CHAMPIONSHIPS_REPO" "repositório de campeonatos: 'inmemory' | 'dynamo'"            "optional"

# Datadog
check_env_var "DD_API_KEY" "chave de API Datadog — prodops/runtime/datadog/send.sh (métricas de delivery)" "optional"
check_env_var "DD_APP_KEY" "chave de aplicação Datadog — runtime-doctor.sh lê dashboards via API (opcional em dev)" "optional"
check_env_var "DD_SITE"    "endpoint Datadog: 'datadoghq.com' (US, default) | 'datadoghq.eu' (EU) — send.sh usa esta variável" "optional"

# GitHub Project — provisionamento do board de diligência
check_env_var "GITHUB_ORG"      "organização GitHub alvo de provision.sh e scripts de diligência (default: produtoreativo)" "optional"
check_env_var "GITHUB_REPO"     "repositório GitHub alvo de ensure-issues.sh e ensure-labels.sh (default: payments-api)" "optional"
check_env_var "PROJECT_NUMBER"  "número do GitHub Project para provisioning e runtime/github/sync.sh — padrão incorreto pode operar no projeto errado" "optional"

# ══════════════════════════════════════════════════════════════════════════════
section "9. ProdOps"
# ══════════════════════════════════════════════════════════════════════════════

if [[ -f prodops/exec/framework-lock.yaml ]]; then
  FRAMEWORK_VER=$(grep -m1 '^\s*version:' prodops/exec/framework-lock.yaml | awk '{print $2}' | tr -d '"' || echo "unknown")
  DRIFT=$(grep -m1 '^\s*status:' prodops/exec/framework-lock.yaml | awk '{print $2}' | tr -d '"' || echo "unknown")
  if [[ "$DRIFT" == "ok" ]]; then
    ok "ProdOps framework ${FRAMEWORK_VER} instalado — drift: ok"
  else
    warn "ProdOps framework ${FRAMEWORK_VER} — drift: ${DRIFT}"
    hint "Sincronize: bash prodops/scripts/sync-from-framework.sh"
  fi
else
  warn "prodops/exec/framework-lock.yaml não encontrado — ProdOps pode não estar instalado"
  hint "Execute: bash prodops/scripts/install-prodops.sh"
fi

if [[ -f prodops/runtime/runtime.yaml ]]; then
  ok "prodops/runtime/runtime.yaml presente"
else
  warn "prodops/runtime/runtime.yaml ausente — runtime ProdOps não configurado"
  hint "Copie o exemplo: cp prodops/runtime/runtime.yaml.example prodops/runtime/runtime.yaml e preencha os valores"
fi

# Arquivos de runtime críticos — emit-event pipeline
check_runtime_file() {
  local path="$1" desc="$2" level="${3:-fail}"
  if [[ -f "${path}" ]]; then
    ok "${path} presente (${desc})"
  elif [[ "${level}" == "fail" ]]; then
    fail "${path} ausente — ${desc}"
  else
    warn "${path} ausente — ${desc}"
  fi
}

check_runtime_file \
  "prodops/runtime/catalog/events.yaml" \
  "catálogo de eventos — emit-event pipeline aborta sem este arquivo"

check_runtime_file \
  "prodops/runtime/producer/emit.sh" \
  "construção de CloudEvent — emit-event exits 3 se ausente"

check_runtime_file \
  "prodops/runtime/timeline/append.sh" \
  "persistência de timeline — emit-event exits 3 se ausente"

check_runtime_file \
  "prodops/runtime/consumer/derive-state.sh" \
  "derivação de estado OEM — emit-event exits 3 se ausente"

check_runtime_file \
  "prodops/runtime/subscriptions/delivery-diligence.yaml" \
  "tabela de subscribers — dispatch.sh ignora todos os eventos se ausente" \
  "warn"

# .prodopsignore — sync-from-framework.sh sobrescreve paths protegidos sem este arquivo
if [[ -f .prodopsignore ]]; then
  ok ".prodopsignore presente (sync-from-framework.sh respeita paths do consumer)"
else
  fail ".prodopsignore ausente — sync-from-framework.sh pode sobrescrever arquivos protegidos do consumer"
  hint "Execute: bash prodops/scripts/install-prodops.sh  (gera o arquivo automaticamente)"
fi

# Diretório de logs de runtime — sync.sh e send.sh gravam logs aqui
if [[ -d prodops/artifacts/runtime ]]; then
  ok "prodops/artifacts/runtime/ presente (diretório de logs de runtime)"
else
  warn "prodops/artifacts/runtime/ ausente — runtime/github/sync.sh e datadog/send.sh falharão ao gravar logs"
  hint "mkdir -p prodops/artifacts/runtime"
fi

# export-manifest.yaml — export-framework.sh e validate-export-manifest.sh requerem este arquivo
if [[ -f prodops/exec/export-manifest.yaml ]]; then
  ok "prodops/exec/export-manifest.yaml presente"
else
  warn "prodops/exec/export-manifest.yaml ausente — export-framework.sh e validate-export-manifest.sh não funcionarão"
  hint "Disponível apenas no upstream empírico (payments-api) — ignorar em repos consumer"
fi

# CHANGELOG.md — prepare-release.sh requer este arquivo na raiz
if [[ -f CHANGELOG.md ]]; then
  ok "CHANGELOG.md presente (prepare-release.sh)"
else
  warn "CHANGELOG.md ausente na raiz — prepare-release.sh falhará ao tentar adicionar entrada de release"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Sumário
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}✅  ${PASS} OK${RESET}   ${YELLOW}⚠️   ${WARN} avisos${RESET}   ${RED}❌  ${FAIL} erros${RESET}"
echo -e "${BOLD}────────────────────────────────────────────${RESET}"

if (( FAIL > 0 )); then
  echo -e "\n  ${RED}${BOLD}Ambiente incompleto.${RESET} Resolva os erros (❌) antes de iniciar o desenvolvimento."
  $FIX_HINTS || echo -e "  Execute com ${BOLD}--fix-hints${RESET} para ver os comandos de instalação."
  echo ""
  exit 1
elif (( WARN > 0 )); then
  echo -e "\n  ${YELLOW}Ambiente funcional para desenvolvimento local.${RESET} Itens com ⚠️ são necessários apenas para fluxos específicos (staging, produção, deploy de infra)."
  echo ""
  exit 0
else
  echo -e "\n  ${GREEN}${BOLD}Ambiente completamente configurado.${RESET} Bom desenvolvimento! 🤼"
  echo ""
  exit 0
fi
