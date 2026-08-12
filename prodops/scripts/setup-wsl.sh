#!/usr/bin/env bash
# setup-wsl.sh — Bootstrap completo de ambiente de desenvolvimento ProdOps
#
# Contextos de execução detectados automaticamente:
#
#   [A] Windows (Git Bash / MSYS2)
#       → Verifica/instala Ubuntu no WSL2 e reinvoca este script dentro dele
#
#   [B] Ubuntu / Debian (WSL2 ou nativo)
#       → Instala todas as dependências, clona o repositório e prepara o projeto
#
# Uso:
#   Windows (Git Bash):   bash prodops/scripts/setup-wsl.sh [--optional]
#   Ubuntu/WSL2:          bash prodops/scripts/setup-wsl.sh [--optional]
#   One-liner (Ubuntu):   curl -fsSL https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/setup-wsl.sh | bash
#
# Flag:
#   --optional   Inclui aws-cli v2, aws-cdk, cdklocal, awslocal e ripgrep
#
# Exit codes:
#   0  sucesso (ou Ubuntu instalado e aguardando re-execução)
#   1  erro fatal ou SO não suportado

# ── Cores e helpers ────────────────────────────────────────────────────────────

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

step()  { echo -e "\n${BOLD}▶ $*${RESET}"; }
ok()    { echo -e "  ${GREEN}✔${RESET}  $*"; }
skip()  { echo -e "  ${YELLOW}–${RESET}  $* (já instalado)"; }
note()  { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()   { echo -e "  ${RED}✘${RESET}  $*" >&2; }
already() { command -v "$1" >/dev/null 2>&1; }

header() {
  echo -e "${BOLD}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         ProdOps — setup-wsl.sh  [$1]          ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

# ── Flags ──────────────────────────────────────────────────────────────────────

OPTIONAL=false
for arg in "$@"; do [[ "$arg" == "--optional" ]] && OPTIONAL=true; done
PASS_FLAGS="$([[ "$OPTIONAL" == true ]] && echo '--optional' || true)"

# ── Constantes ────────────────────────────────────────────────────────────────

REPO_HTTPS="https://github.com/produtoreativo/payments-api.git"
REPO_GH="produtoreativo/payments-api"
CLONE_DIR="${HOME}/payments-api"
UBUNTU_DISTRO="Ubuntu-24.04"
SCRIPT_URL="https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/setup-wsl.sh"

# ══════════════════════════════════════════════════════════════════════════════
# DETECÇÃO DE CONTEXTO
# ══════════════════════════════════════════════════════════════════════════════

is_windows() {
  [[ "${OS:-}" == "Windows_NT" ]] \
    || [[ "$(uname -s 2>/dev/null)" == MINGW* ]] \
    || [[ "$(uname -s 2>/dev/null)" == MSYS* ]] \
    || [[ "$(uname -s 2>/dev/null)" == CYGWIN* ]]
}

is_ubuntu() {
  [[ -f /etc/debian_version ]]
}

is_wsl() {
  grep -qi "microsoft\|wsl" /proc/version 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# [A] CONTEXTO WINDOWS — instala Ubuntu WSL2 e re-invoca dentro dele
# ══════════════════════════════════════════════════════════════════════════════

if is_windows; then
  header "A: Windows"
  echo "  Objetivo : detectar/instalar Ubuntu WSL2 e preparar o ambiente dentro dele"
  echo ""

  # Verifica wsl.exe
  if ! command -v wsl.exe >/dev/null 2>&1; then
    err "wsl.exe não encontrado."
    note "Habilite o WSL no Windows: abra PowerShell como Administrador e execute:"
    note "  wsl --install"
    note "Reinicie o computador e execute este script novamente."
    exit 1
  fi

  step "Verificando distribuições Ubuntu instaladas no WSL"

  # wsl --list --quiet emite UTF-16LE; convertemos para UTF-8
  WSL_LIST=$(wsl.exe --list --quiet 2>/dev/null \
    | iconv -f UTF-16LE -t UTF-8 2>/dev/null \
    | tr -d '\r\000' \
    || wsl.exe --list --quiet 2>/dev/null | tr -d '\r\000' || true)

  FOUND_DISTRO=""
  while IFS= read -r line; do
    clean=$(echo "$line" | sed 's/ (Default)//' | xargs)
    if echo "$clean" | grep -qi "^ubuntu"; then
      FOUND_DISTRO="$clean"
      break
    fi
  done <<< "$WSL_LIST"

  if [[ -n "$FOUND_DISTRO" ]]; then
    ok "Ubuntu encontrado: ${FOUND_DISTRO}"
  else
    step "Ubuntu não encontrado — instalando ${UBUNTU_DISTRO}"
    note "O Windows abrirá o terminal do Ubuntu para criação de usuário."
    note "Crie o usuário e senha quando solicitado, depois aguarde o script continuar."
    echo ""

    if ! wsl.exe --install -d "${UBUNTU_DISTRO}"; then
      err "Falha ao instalar ${UBUNTU_DISTRO}."
      note "Tente manualmente: abra PowerShell como Administrador e execute:"
      note "  wsl --install -d Ubuntu-24.04"
      note "Reinicie se necessário, depois execute este script novamente."
      exit 1
    fi
    FOUND_DISTRO="${UBUNTU_DISTRO}"
    ok "${UBUNTU_DISTRO} instalado."
  fi

  step "Reinvocando setup-wsl.sh dentro de ${FOUND_DISTRO}"
  note "Qualquer prompt sudo pedirá a senha do usuário Ubuntu, não do Windows."
  echo ""

  # Tenta invocar via script remoto (idempotente) ou arquivo local se existir
  INNER_CMD="curl -fsSL '${SCRIPT_URL}' | bash -s -- ${PASS_FLAGS}"
  if ! wsl.exe -d "${FOUND_DISTRO}" -- bash -c "${INNER_CMD}"; then
    err "Falha ao executar o setup dentro do Ubuntu."
    note "Entre no Ubuntu manualmente e execute:"
    note "  ${INNER_CMD}"
    exit 1
  fi

  echo ""
  echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Ambiente pronto. Abra o terminal do ${FOUND_DISTRO}.${RESET}"
  echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# [B] CONTEXTO UBUNTU / DEBIAN — instalação completa
# ══════════════════════════════════════════════════════════════════════════════

if ! is_ubuntu; then
  err "Sistema operacional não suportado: $(uname -s 2>/dev/null || echo 'desconhecido')"
  note "Este script suporta Windows (Git Bash) e Ubuntu/Debian."
  note "Para outros sistemas, instale as ferramentas manualmente:"
  note "  bash prodops/scripts/check-env.sh --fix-hints"
  exit 1
fi

set -euo pipefail

header "B: Ubuntu$(is_wsl && echo '/WSL2' || true)"
echo "  Sistema  : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 'Ubuntu/Debian')"
echo "  WSL      : $(is_wsl && echo 'sim' || echo 'não (ambiente nativo)')"
echo "  Modo     : $([ "$OPTIONAL" = true ] && echo 'completo (--optional)' || echo 'essencial')"
echo "  Repo     : ${CLONE_DIR}"

# ── 1. apt update + dependências base ─────────────────────────────────────────

step "Atualizando lista de pacotes"
sudo apt-get update -qq
ok "apt update concluído"

step "Instalando dependências base"
PKGS=(git curl jq gawk diffutils sed uuid-runtime python3 python3-pip unzip ca-certificates gnupg lsb-release)
MISSING=()
for pkg in "${PKGS[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  sudo apt-get install -y -qq "${MISSING[@]}"
  ok "Instalados: ${MISSING[*]}"
else
  skip "Pacotes base"
fi

if python3 -c "import yaml" 2>/dev/null; then
  skip "PyYAML"
else
  pip3 install --quiet pyyaml
  ok "PyYAML"
fi

# ── 2. Node.js 20 via nvm ─────────────────────────────────────────────────────

step "Instalando nvm + Node.js 20"
export NVM_DIR="${HOME}/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
  NVM_VER=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null \
    || echo "v0.40.1")
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh" | bash
  ok "nvm ${NVM_VER} instalado"
else
  skip "nvm"
fi

# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

NODE_OK=false
if already node; then
  MAJ=$(node --version | sed 's/v//' | cut -d. -f1)
  if [[ "$MAJ" -ge 20 ]]; then skip "Node.js $(node --version)"; NODE_OK=true; fi
fi
if [[ "$NODE_OK" == false ]]; then
  nvm install 20 --silent
  nvm use 20; nvm alias default 20
  ok "Node.js $(node --version)"
fi

# ── 3. GitHub CLI ─────────────────────────────────────────────────────────────

step "Instalando GitHub CLI"
if already gh; then
  skip "gh $(gh --version | head -1 | awk '{print $3}')"
else
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh
  ok "gh $(gh --version | head -1 | awk '{print $3}')"
fi

# ── 4. Docker ─────────────────────────────────────────────────────────────────

step "Verificando Docker"
if already docker && docker info >/dev/null 2>&1; then
  skip "Docker $(docker --version | awk '{print $3}' | tr -d ',') — daemon acessível"
elif is_wsl; then
  note "Docker não acessível via WSL."
  note "Instale Docker Desktop no Windows e habilite a integração WSL2:"
  note "  Settings → Resources → WSL Integration → Enable for this distro"
  note "Alternativa (Docker Engine direto no WSL):"
  note "  curl -fsSL https://get.docker.com | sh"
  note "  sudo usermod -aG docker \$USER && newgrp docker"
else
  note "Docker não encontrado. Instale via: curl -fsSL https://get.docker.com | sh"
fi

# ── 5. Ferramentas opcionais ───────────────────────────────────────────────────

if [[ "$OPTIONAL" == true ]]; then
  step "AWS CLI v2"
  if already aws; then
    skip "aws-cli $(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)"
  else
    TMP=$(mktemp -d)
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${TMP}/awscliv2.zip"
    unzip -q "${TMP}/awscliv2.zip" -d "${TMP}"
    sudo "${TMP}/aws/install"
    rm -rf "${TMP}"
    ok "aws-cli $(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)"
  fi

  step "aws-cdk e cdklocal"
  already cdk      && skip "cdk $(cdk --version 2>/dev/null | awk '{print $1}')" \
                   || { npm install -g aws-cdk --silent; ok "aws-cdk $(cdk --version 2>/dev/null | awk '{print $1}')"; }
  already cdklocal && skip "cdklocal" \
                   || { npm install -g aws-cdk-local --silent; ok "cdklocal"; }

  step "awslocal"
  already awslocal && skip "awslocal" \
                   || { pip3 install --quiet awscli-local; ok "awslocal"; }

  step "ripgrep"
  if already rg; then
    skip "rg $(rg --version | head -1 | awk '{print $2}')"
  else
    sudo apt-get install -y -qq ripgrep
    ok "rg $(rg --version | head -1 | awk '{print $2}')"
  fi
fi

# ── 6. Configuração do shell ───────────────────────────────────────────────────

step "Configurando shell"
NVM_BLOCK='
# nvm — adicionado por setup-wsl.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$RC" ]] || continue
  grep -q "NVM_DIR" "$RC" 2>/dev/null && { skip "nvm em $RC"; continue; }
  echo "$NVM_BLOCK" >> "$RC"
  ok "nvm configurado em $RC"
done

# ── 7. Autenticação GitHub ────────────────────────────────────────────────────

step "Autenticação GitHub CLI"
if gh auth status >/dev/null 2>&1; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  skip "gh autenticado como @${GH_USER}"
else
  note "É necessário autenticar o GitHub CLI para clonar e operar com o repositório."
  echo ""
  gh auth login
fi

# ── 8. Clone do repositório ───────────────────────────────────────────────────

step "Clonando repositório payments-api"
if [[ -d "${CLONE_DIR}/.git" ]]; then
  skip "Repositório já existe em ${CLONE_DIR}"
  git -C "${CLONE_DIR}" pull --ff-only 2>/dev/null && ok "git pull executado" || true
else
  gh repo clone "${REPO_GH}" "${CLONE_DIR}" -- --quiet \
    || git clone "${REPO_HTTPS}" "${CLONE_DIR}" --quiet
  ok "Repositório clonado em ${CLONE_DIR}"
fi

# ── 9. Dependências do projeto ────────────────────────────────────────────────

step "Instalando dependências do projeto (npm install)"
if [[ -d "${CLONE_DIR}/node_modules" ]]; then
  skip "node_modules já presente"
else
  npm --prefix "${CLONE_DIR}" install --silent
  ok "node_modules instalado"
fi

# ── 10. Validação final ───────────────────────────────────────────────────────

step "Validando ambiente com check-env.sh"
echo ""
bash "${CLONE_DIR}/prodops/scripts/check-env.sh" || true

# ── Resumo ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Ambiente ProdOps pronto.${RESET}"
echo ""
echo "  Repositório : ${CLONE_DIR}"
echo ""
echo "  Próximos passos:"
echo "    cd ${CLONE_DIR}"
if ! already docker || ! docker info >/dev/null 2>&1; then
  echo "    # Configure Docker Desktop com integração WSL2 antes de rodar:"
fi
echo "    npm run local:start   # sobe LocalStack"
echo "    npm test              # roda os testes"
echo ""
echo "  Para rediagnosticar o ambiente:"
echo "    bash prodops/scripts/check-env.sh --fix-hints"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
