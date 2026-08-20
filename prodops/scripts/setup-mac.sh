#!/usr/bin/env bash
# setup-mac.sh — Bootstrap completo de ambiente de desenvolvimento ProdOps para macOS
# ProdOps Framework v1.14.1
#
# Instala todas as ferramentas necessárias via Homebrew, clona o repositório
# payments-api e prepara o projeto para desenvolvimento local.
#
# Uso:
#   bash prodops/scripts/setup-mac.sh
#   bash prodops/scripts/setup-mac.sh --optional   (aws-cli, aws-cdk, cdklocal, awslocal, ripgrep)
#
# Autenticação GitHub sem browser:
#   export GITHUB_TOKEN=ghp_seu_token
#   bash prodops/scripts/setup-mac.sh
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/setup-mac.sh | bash
#
# Exit codes:
#   0  sucesso
#   1  macOS não detectado ou erro fatal

PRODOPS_VERSION="v1.14.1"

set -euo pipefail

# ── Detecção de SO ─────────────────────────────────────────────────────────────

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERRO: setup-mac.sh é exclusivo para macOS." >&2
  echo "      Para Linux/WSL use: prodops/scripts/setup-wsl.sh" >&2
  exit 1
fi

# ── Flags ──────────────────────────────────────────────────────────────────────

OPTIONAL=false
for arg in "$@"; do [[ "$arg" == "--optional" ]] && OPTIONAL=true; done

# ── Cores e helpers ────────────────────────────────────────────────────────────

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

step()    { echo -e "\n${BOLD}▶ $*${RESET}"; }
ok()      { echo -e "  ${GREEN}✔${RESET}  $*"; }
skip()    { echo -e "  ${YELLOW}–${RESET}  $* (já instalado)"; }
note()    { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()     { echo -e "  ${RED}✘${RESET}  $*" >&2; }
already() { command -v "$1" >/dev/null 2>&1; }

# ── Report ─────────────────────────────────────────────────────────────────────

declare -a REPORT=()
report_ok()   { REPORT+=("$1|$2|OK|$3"); }
report_skip() { REPORT+=("$1|$2|JÁ INSTALADO|$3"); }
report_warn() { REPORT+=("$1|$2|ATENÇÃO|$3"); }
report_fail() { REPORT+=("$1|$2|FALHOU|$3"); }

# ── Constantes ────────────────────────────────────────────────────────────────

REPO_GH="produtoreativo/payments-api"
REPO_HTTPS="https://github.com/produtoreativo/payments-api.git"
CLONE_DIR="${HOME}/payments-api"
ARCH=$(uname -m)   # arm64 (Apple Silicon) ou x86_64 (Intel)

# ── Cabeçalho ─────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║         ProdOps — setup-mac.sh                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Versão   : ${PRODOPS_VERSION}"
echo "  Sistema  : $(sw_vers -productName) $(sw_vers -productVersion)"
echo "  Arch     : ${ARCH}"
echo "  Modo     : $([ "$OPTIONAL" = true ] && echo 'completo (--optional)' || echo 'essencial')"
echo "  Repo     : ${CLONE_DIR}"

# ── 1. Homebrew ───────────────────────────────────────────────────────────────

step "Homebrew"
if already brew; then
  BREW_V=$(brew --version | head -1 | awk '{print $2}')
  skip "Homebrew ${BREW_V}"
  report_skip "Homebrew" "Gerenciador de pacotes macOS" "${BREW_V} já presente"
else
  note "Instalando Homebrew (requer senha de administrador)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Adiciona brew ao PATH para Apple Silicon
  if [[ "$ARCH" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  BREW_V=$(brew --version | head -1 | awk '{print $2}')
  ok "Homebrew ${BREW_V} instalado"
  report_ok "Homebrew" "Gerenciador de pacotes macOS" "${BREW_V} instalado"
fi

# ── 2. bash ≥ 4 ───────────────────────────────────────────────────────────────
# macOS entrega bash 3.2 por padrão — mapfile (bash 4+) é usado em materialize-skills/agents

step "bash ≥ 4"
BASH_MAJ="${BASH_VERSION%%.*}"
if [[ "$BASH_MAJ" -ge 4 ]]; then
  skip "bash ${BASH_VERSION%%(*} (≥ 4)"
  report_skip "bash" "Shell com suporte a mapfile (materialize-skills/agents)" "${BASH_VERSION%%(*} já instalado"
else
  brew install bash --quiet
  ok "bash $(brew list --versions bash | awk '{print $2}') instalado"
  note "Adicione ao /etc/shells e defina como padrão:"
  note "  sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'"
  note "  chsh -s /opt/homebrew/bin/bash"
  report_ok "bash" "Shell com suporte a mapfile (materialize-skills/agents)" "$(brew list --versions bash | awk '{print $2}') instalado via brew"
fi

# ── 3. Dependências base ───────────────────────────────────────────────────────

step "Dependências base (git, curl, jq, gawk, diffutils, gnu-sed, python3)"

# Array simples — compatível com bash 3.2 (padrão do macOS antes do brew)
BREW_PKGS=(git curl jq gawk diffutils gnu-sed python3)

INSTALLED_PKGS=()
for pkg in "${BREW_PKGS[@]}"; do
  if brew list "$pkg" >/dev/null 2>&1; then
    : # já instalado, segue
  else
    brew install "$pkg" --quiet
    INSTALLED_PKGS+=("$pkg")
  fi
done

if [[ ${#INSTALLED_PKGS[@]} -gt 0 ]]; then
  ok "Instalados: ${INSTALLED_PKGS[*]}"
  report_ok "Pacotes base" "git, curl, jq, gawk, diffutils, gnu-sed, python3" "Instalados: ${INSTALLED_PKGS[*]}"
else
  skip "Pacotes base"
  report_skip "Pacotes base" "git, curl, jq, gawk, diffutils, gnu-sed, python3" "Todos já presentes"
fi

# PyYAML
if python3 -c "import yaml" 2>/dev/null; then
  skip "PyYAML"
  report_skip "PyYAML" "Parsing de YAML em scripts ProdOps" "Já disponível"
else
  pip3 install --quiet pyyaml
  ok "PyYAML instalado"
  report_ok "PyYAML" "Parsing de YAML em scripts ProdOps" "Instalado via pip3"
fi

# uuidgen — pré-instalado no macOS, mas verificamos
if already uuidgen; then
  skip "uuidgen"
  report_skip "uuidgen" "Geração de correlation-id / execution-id nos eventos ProdOps" "Pré-instalado no macOS"
else
  report_warn "uuidgen" "Geração de correlation-id / execution-id nos eventos ProdOps" "Não encontrado — python3 uuid usado como fallback"
fi

# ── 4. Node.js 20 via nvm ─────────────────────────────────────────────────────

step "nvm + Node.js 20"
export NVM_DIR="${HOME}/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
  NVM_VER=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null \
    || echo "v0.40.1")
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh" | bash
  ok "nvm ${NVM_VER} instalado"
  report_ok "nvm" "Gerenciador de versões do Node.js" "${NVM_VER} instalado"
else
  skip "nvm"
  report_skip "nvm" "Gerenciador de versões do Node.js" "Já presente em ${NVM_DIR}"
fi

# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

NODE_OK=false
if already node; then
  MAJ=$(node --version | sed 's/v//' | cut -d. -f1)
  if [[ "$MAJ" -ge 20 ]]; then
    skip "Node.js $(node --version)"
    report_skip "Node.js" "Runtime JavaScript do projeto (mín. v20)" "$(node --version) já instalado"
    NODE_OK=true
  fi
fi
if [[ "$NODE_OK" == false ]]; then
  nvm install 20 --silent
  nvm use 20; nvm alias default 20
  ok "Node.js $(node --version)"
  report_ok "Node.js" "Runtime JavaScript do projeto (mín. v20)" "$(node --version) instalado via nvm"
fi

# ── 5. GitHub CLI ─────────────────────────────────────────────────────────────

step "GitHub CLI"
if already gh; then
  GH_V=$(gh --version | head -1 | awk '{print $3}')
  skip "gh ${GH_V}"
  report_skip "gh (GitHub CLI)" "PRs, issues, clone e autenticação GitHub" "${GH_V} já instalado"
else
  brew install gh --quiet
  GH_V=$(gh --version | head -1 | awk '{print $3}')
  ok "gh ${GH_V}"
  report_ok "gh (GitHub CLI)" "PRs, issues, clone e autenticação GitHub" "${GH_V} instalado via brew"
fi

# ── 6. Docker Desktop ─────────────────────────────────────────────────────────

step "Docker Desktop"
if already docker && docker info >/dev/null 2>&1; then
  DOCK_V=$(docker --version | awk '{print $3}' | tr -d ',')
  skip "Docker ${DOCK_V} — daemon ativo"
  report_skip "Docker Desktop" "Containers para LocalStack (DynamoDB local)" "${DOCK_V} — daemon ativo"
elif already docker; then
  note "Docker instalado mas daemon não está rodando — inicie o Docker Desktop."
  report_warn "Docker Desktop" "Containers para LocalStack (DynamoDB local)" "Instalado mas daemon inativo — abra o Docker Desktop"
else
  brew install --cask docker --quiet
  ok "Docker Desktop instalado"
  note "Abra o Docker Desktop para iniciar o daemon antes de rodar o projeto."
  report_ok "Docker Desktop" "Containers para LocalStack (DynamoDB local)" "Instalado via brew cask — inicie o app"
fi

# ── 7. Ferramentas opcionais ───────────────────────────────────────────────────

if [[ "$OPTIONAL" == true ]]; then
  step "AWS CLI v2"
  if already aws; then
    AWS_V=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
    skip "aws-cli ${AWS_V}"
    report_skip "aws-cli v2" "Interface de linha de comando para AWS" "${AWS_V} já instalado"
  else
    brew install awscli --quiet
    AWS_V=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
    ok "aws-cli ${AWS_V}"
    report_ok "aws-cli v2" "Interface de linha de comando para AWS" "${AWS_V} instalado via brew"
  fi

  step "aws-cdk"
  if already cdk; then
    CDK_V=$(cdk --version 2>/dev/null | awk '{print $1}')
    skip "aws-cdk ${CDK_V}"
    report_skip "aws-cdk" "Infraestrutura como código para AWS" "${CDK_V} já instalado"
  else
    npm install -g aws-cdk --silent
    CDK_V=$(cdk --version 2>/dev/null | awk '{print $1}')
    ok "aws-cdk ${CDK_V}"
    report_ok "aws-cdk" "Infraestrutura como código para AWS" "${CDK_V} instalado via npm"
  fi

  step "cdklocal"
  if already cdklocal; then
    skip "cdklocal"
    report_skip "cdklocal" "Wrapper do CDK para LocalStack" "Já instalado"
  else
    npm install -g aws-cdk-local --silent
    ok "cdklocal instalado"
    report_ok "cdklocal" "Wrapper do CDK para LocalStack" "Instalado via npm"
  fi

  step "awslocal"
  if already awslocal; then
    skip "awslocal"
    report_skip "awslocal" "Wrapper do aws-cli para LocalStack" "Já instalado"
  else
    pip3 install --quiet awscli-local
    ok "awslocal instalado"
    report_ok "awslocal" "Wrapper do aws-cli para LocalStack" "Instalado via pip3"
  fi

  step "ripgrep"
  if already rg; then
    RG_V=$(rg --version | head -1 | awk '{print $2}')
    skip "rg ${RG_V}"
    report_skip "ripgrep" "Busca de texto rápida (doctor.sh)" "${RG_V} já instalado"
  else
    brew install ripgrep --quiet
    RG_V=$(rg --version | head -1 | awk '{print $2}')
    ok "rg ${RG_V}"
    report_ok "ripgrep" "Busca de texto rápida (doctor.sh)" "${RG_V} instalado via brew"
  fi
fi

# ── 8. Configuração do shell ───────────────────────────────────────────────────

step "Configurando shell"

NVM_BLOCK='
# nvm — adicionado por setup-mac.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

BREW_BLOCK='
# Homebrew (Apple Silicon) — adicionado por setup-mac.sh
eval "$(/opt/homebrew/bin/brew shellenv)"'

for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  [[ -f "$RC" ]] || continue
  if ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
    echo "$NVM_BLOCK" >> "$RC"
    ok "nvm configurado em $RC"
  else
    skip "nvm em $RC"
  fi
  if [[ "$ARCH" == "arm64" ]] && ! grep -q "brew shellenv" "$RC" 2>/dev/null; then
    echo "$BREW_BLOCK" >> "$RC"
    ok "brew shellenv configurado em $RC"
  fi
done

# ── 9. Autenticação GitHub ────────────────────────────────────────────────────

step "Autenticação GitHub CLI"
if gh auth status >/dev/null 2>&1; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  skip "gh autenticado como @${GH_USER}"
  report_skip "GitHub Auth" "Autenticação para clone e operações de repo" "@${GH_USER} já autenticado"
elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
  gh auth login --with-token <<< "${GITHUB_TOKEN}"
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  ok "gh autenticado via GITHUB_TOKEN como @${GH_USER}"
  report_ok "GitHub Auth" "Autenticação para clone e operações de repo" "Via GITHUB_TOKEN como @${GH_USER}"
else
  note "Nenhuma autenticação encontrada."
  note "Para autenticar sem interação, defina GITHUB_TOKEN antes de rodar:"
  note "  export GITHUB_TOKEN=ghp_seu_token"
  note "Gere em: github.com → Settings → Developer settings → Personal access tokens"
  note "Escopos: repo, read:org"
  note ""
  gh auth login
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  report_ok "GitHub Auth" "Autenticação para clone e operações de repo" "Via browser como @${GH_USER}"
fi

# ── 10. Clone do repositório ──────────────────────────────────────────────────

step "Clonando repositório payments-api"
if [[ -d "${CLONE_DIR}/.git" ]]; then
  skip "Repositório já existe em ${CLONE_DIR}"
  git -C "${CLONE_DIR}" pull --ff-only 2>/dev/null && ok "git pull executado" || true
  report_skip "payments-api" "Repositório do projeto" "Já clonado em ${CLONE_DIR}"
else
  gh repo clone "${REPO_GH}" "${CLONE_DIR}" -- --quiet \
    || git clone "${REPO_HTTPS}" "${CLONE_DIR}" --quiet
  ok "Repositório clonado em ${CLONE_DIR}"
  report_ok "payments-api" "Repositório do projeto" "Clonado em ${CLONE_DIR}"
fi

# ── 11. Dependências do projeto ───────────────────────────────────────────────

step "Instalando dependências do projeto (npm install)"
if [[ -d "${CLONE_DIR}/node_modules" ]]; then
  skip "node_modules já presente"
  report_skip "npm install" "Dependências do projeto (node_modules)" "Já presentes"
else
  npm --prefix "${CLONE_DIR}" install --silent
  ok "node_modules instalado"
  report_ok "npm install" "Dependências do projeto (node_modules)" "Instaladas em ${CLONE_DIR}/node_modules"
fi

# ── 12. Validação com check-env.sh ────────────────────────────────────────────

step "Validando ambiente com check-env.sh"
echo ""
bash "${CLONE_DIR}/prodops/scripts/check-env.sh" || true

# ── Relatório final ───────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  RELATÓRIO DE INSTALAÇÃO — ProdOps Setup (macOS)${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo ""

printf "  %-18s %-36s %-14s %s\n" "TECNOLOGIA" "DESCRIÇÃO" "STATUS" "DETALHE"
printf "  %-18s %-36s %-14s %s\n" "------------------" "------------------------------------" "--------------" "-------"

OK_COUNT=0; WARN_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0

for entry in "${REPORT[@]}"; do
  IFS='|' read -r name desc status detail <<< "$entry"
  case "$status" in
    OK)
      printf "  ${GREEN}%-18s${RESET} %-36s ${GREEN}%-14s${RESET} %s\n" "$name" "$desc" "✔ $status" "$detail"
      OK_COUNT=$((OK_COUNT+1))
      ;;
    "JÁ INSTALADO")
      printf "  ${YELLOW}%-18s${RESET} %-36s ${YELLOW}%-14s${RESET} %s\n" "$name" "$desc" "– $status" "$detail"
      SKIP_COUNT=$((SKIP_COUNT+1))
      ;;
    ATENÇÃO)
      printf "  ${YELLOW}%-18s${RESET} %-36s ${YELLOW}%-14s${RESET} %s\n" "$name" "$desc" "! $status" "$detail"
      WARN_COUNT=$((WARN_COUNT+1))
      ;;
    FALHOU)
      printf "  ${RED}%-18s${RESET} %-36s ${RED}%-14s${RESET} %s\n" "$name" "$desc" "✘ $status" "$detail"
      FAIL_COUNT=$((FAIL_COUNT+1))
      ;;
  esac
done

echo ""
echo -e "  Instalados: ${GREEN}${OK_COUNT}${RESET}  |  Já presentes: ${YELLOW}${SKIP_COUNT}${RESET}  |  Atenção: ${YELLOW}${WARN_COUNT}${RESET}  |  Falhas: ${RED}${FAIL_COUNT}${RESET}"
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  Repositório : ${CLONE_DIR}"
echo ""
echo "  Próximos passos:"
echo "    cd ${CLONE_DIR}"
if ! already docker || ! docker info >/dev/null 2>&1; then
  echo "    # Abra o Docker Desktop antes de rodar o projeto"
fi
echo "    npm run local:start   # sobe LocalStack"
echo "    npm test              # roda os testes"
echo ""
echo "  Para rediagnosticar:"
echo "    bash prodops/scripts/check-env.sh --fix-hints"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
