#!/usr/bin/env bash
# setup-wsl.sh — Bootstrap completo de ambiente de desenvolvimento ProdOps
# ProdOps Framework v1.14.0
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

PRODOPS_VERSION="v1.14.0"

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

# ── Report ─────────────────────────────────────────────────────────────────────
# Cada entrada: "NOME|DESCRIÇÃO|STATUS|DETALHE"
declare -a REPORT=()
report_ok()   { REPORT+=("$1|$2|OK|$3"); }
report_skip() { REPORT+=("$1|$2|JÁ INSTALADO|$3"); }
report_warn() { REPORT+=("$1|$2|ATENÇÃO|$3"); }
report_fail() { REPORT+=("$1|$2|FALHOU|$3"); }

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
  echo "  Versão   : ${PRODOPS_VERSION}"
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

  step "Verificando Docker Desktop"

  DOCKER_INSTALLED=false
  # Verifica se dockerd ou Docker Desktop já está acessível
  if wsl.exe -d "${FOUND_DISTRO}" -- bash -c "command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1" 2>/dev/null; then
    skip "Docker já acessível dentro do ${FOUND_DISTRO}"
    DOCKER_INSTALLED=true
  elif powershell.exe -Command "Get-Command docker -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "docker"; then
    ok "Docker Desktop detectado no Windows (integração WSL2 pode precisar ser habilitada)"
    DOCKER_INSTALLED=true
  fi

  if [[ "$DOCKER_INSTALLED" == false ]]; then
    note "Docker Desktop não encontrado — instalando via winget..."

    # Detecta arquitetura do Windows
    WIN_ARCH=$(powershell.exe -Command '$env:PROCESSOR_ARCHITECTURE' 2>/dev/null | tr -d '\r\n' || echo "AMD64")
    case "${WIN_ARCH}" in
      ARM64) DOCKER_ARCH="arm64" ;;
      *)     DOCKER_ARCH="amd64" ;;
    esac

    # Tenta winget (disponível no Windows 10 1709+ e Windows 11)
    if powershell.exe -Command "Get-Command winget -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "winget"; then
      note "Instalando Docker Desktop via winget (${DOCKER_ARCH})..."
      if powershell.exe -Command "winget install --id Docker.DockerDesktop --architecture ${WIN_ARCH} --silent --accept-package-agreements --accept-source-agreements" 2>/dev/null; then
        ok "Docker Desktop instalado via winget."
        DOCKER_INSTALLED=true   # marca explicitamente para bloquear o fallback
      else
        note "winget falhou — tentando download direto..."
        # DOCKER_INSTALLED permanece false → fallback ativo
      fi
    fi

    # Fallback: download direto do instalador (só executa se winget não instalou)
    if [[ "$DOCKER_INSTALLED" == false ]]; then
      DOCKER_URL="https://desktop.docker.com/win/main/${DOCKER_ARCH}/Docker%20Desktop%20Installer.exe"
      INSTALLER_PATH=$(powershell.exe -Command '$env:TEMP' 2>/dev/null | tr -d '\r\n' || echo "C:\\Windows\\Temp")
      INSTALLER_PATH="${INSTALLER_PATH}\\DockerDesktopInstaller.exe"
      note "Baixando Docker Desktop (${DOCKER_ARCH}) — pode demorar alguns minutos..."
      if powershell.exe -Command "Invoke-WebRequest -Uri '${DOCKER_URL}' -OutFile '${INSTALLER_PATH}' -UseBasicParsing" 2>/dev/null && \
         powershell.exe -Command "Start-Process '${INSTALLER_PATH}' -Wait -ArgumentList 'install','--quiet','--accept-license'" 2>/dev/null; then
        ok "Docker Desktop instalado via download direto."
      else
        err "Não foi possível instalar o Docker Desktop automaticamente."
        note "Instale manualmente: https://docs.docker.com/desktop/install/windows-install/"
        note "Depois habilite: Settings → Resources → WSL Integration → ${FOUND_DISTRO}"
      fi
    fi

    note "Reinicie o Docker Desktop antes de continuar."
    note "Habilite a integração WSL2: Settings → Resources → WSL Integration → ${FOUND_DISTRO}"
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
echo "  Versão   : ${PRODOPS_VERSION}"
echo "  Sistema  : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 'Ubuntu/Debian')"
echo "  WSL      : $(is_wsl && echo 'sim' || echo 'não (ambiente nativo)')"
echo "  Modo     : $([ "$OPTIONAL" = true ] && echo 'completo (--optional)' || echo 'essencial')"
echo "  Repo     : ${CLONE_DIR}"

# ── 1. apt update + dependências base ─────────────────────────────────────────

step "Atualizando lista de pacotes"
sudo apt-get update -qq
ok "apt update concluído"

step "Instalando dependências base"
# uuid-runtime é excluído: o daemon uuidd requer systemd, indisponível no WSL2.
# O check-env.sh usa python3 uuid como fallback automaticamente.
PKGS=(git curl jq gawk diffutils sed python3 python3-pip unzip ca-certificates gnupg lsb-release)
MISSING=()
for pkg in "${PKGS[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  sudo apt-get install -y -qq "${MISSING[@]}"
  ok "Instalados: ${MISSING[*]}"
  report_ok "Pacotes base" "git, curl, jq, awk, diff, sed, python3, pip, unzip" "Instalados: ${MISSING[*]}"
else
  skip "Pacotes base"
  report_skip "Pacotes base" "git, curl, jq, awk, diff, sed, python3, pip, unzip" "Todos já presentes"
fi

if python3 -c "import yaml" 2>/dev/null; then
  skip "PyYAML"
  report_skip "PyYAML" "Parsing de YAML em scripts ProdOps" "Já disponível"
else
  pip3 install --quiet pyyaml
  ok "PyYAML"
  report_ok "PyYAML" "Parsing de YAML em scripts ProdOps" "Instalado via pip3"
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

# ── 3. GitHub CLI ─────────────────────────────────────────────────────────────

step "Instalando GitHub CLI"
if already gh; then
  GH_V=$(gh --version | head -1 | awk '{print $3}')
  skip "gh ${GH_V}"
  report_skip "gh (GitHub CLI)" "PRs, issues, clone e autenticação GitHub" "${GH_V} já instalado"
else
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh
  GH_V=$(gh --version | head -1 | awk '{print $3}')
  ok "gh ${GH_V}"
  report_ok "gh (GitHub CLI)" "PRs, issues, clone e autenticação GitHub" "${GH_V} instalado via apt"
fi

# ── 4. Docker ─────────────────────────────────────────────────────────────────

step "Verificando Docker"
if already docker && docker info >/dev/null 2>&1; then
  DOCK_V=$(docker --version | awk '{print $3}' | tr -d ',')
  skip "Docker ${DOCK_V} — daemon acessível"
  report_skip "Docker" "Containers para LocalStack (DynamoDB local)" "${DOCK_V} — daemon ativo"
elif is_wsl; then
  # Dentro do WSL2: powershell.exe e winget.exe são acessíveis via interop do Windows
  note "Docker não acessível — tentando instalar Docker Desktop via Windows..."

  WIN_ARCH=$(powershell.exe -Command '$env:PROCESSOR_ARCHITECTURE' 2>/dev/null | tr -d '\r\n' || echo "AMD64")
  case "${WIN_ARCH}" in
    ARM64) DOCKER_ARCH="arm64" ;;
    *)     DOCKER_ARCH="amd64" ;;
  esac

  DOCKER_WIN_OK=false

  if powershell.exe -Command "Get-Command winget -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "winget"; then
    note "Instalando Docker Desktop via winget (${DOCKER_ARCH})..."
    if powershell.exe -Command "winget install --id Docker.DockerDesktop --architecture ${WIN_ARCH} --silent --accept-package-agreements --accept-source-agreements" 2>/dev/null; then
      ok "Docker Desktop instalado via winget."
      DOCKER_WIN_OK=true
    else
      note "winget falhou — tentando download direto..."
    fi
  fi

  if [[ "$DOCKER_WIN_OK" == false ]]; then
    DOCKER_URL="https://desktop.docker.com/win/main/${DOCKER_ARCH}/Docker%20Desktop%20Installer.exe"
    INSTALLER_PATH=$(powershell.exe -Command '$env:TEMP' 2>/dev/null | tr -d '\r\n' || echo 'C:\Windows\Temp')
    INSTALLER_PATH="${INSTALLER_PATH}\\DockerDesktopInstaller.exe"
    note "Baixando Docker Desktop (${DOCKER_ARCH}) — pode demorar alguns minutos..."
    if powershell.exe -Command "Invoke-WebRequest -Uri '${DOCKER_URL}' -OutFile '${INSTALLER_PATH}' -UseBasicParsing" 2>/dev/null && \
       powershell.exe -Command "Start-Process '${INSTALLER_PATH}' -Wait -ArgumentList 'install','--quiet','--accept-license'" 2>/dev/null; then
      ok "Docker Desktop instalado via download direto."
      DOCKER_WIN_OK=true
    else
      err "Não foi possível instalar o Docker Desktop automaticamente."
      note "Instale manualmente: https://docs.docker.com/desktop/install/windows-install/"
    fi
  fi

  if [[ "$DOCKER_WIN_OK" == true ]]; then
    # Habilita integração WSL2 automaticamente via settings do Docker Desktop
    _DISTRO="${WSL_DISTRO_NAME:-Ubuntu-24.04}"
    _WIN_USER=$(powershell.exe -Command '$env:USERNAME' 2>/dev/null | tr -d '\r\n' || echo "")
    _DOCKER_SETTINGS=""

    if [[ -n "$_WIN_USER" ]]; then
      _DOCKER_BASE="/mnt/c/Users/${_WIN_USER}/AppData/Roaming/Docker"
      # Inicia Docker Desktop para que ele crie o arquivo de settings (primeira execução)
      note "Iniciando Docker Desktop para criar as configurações iniciais..."
      powershell.exe -Command \
        "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ErrorAction SilentlyContinue" \
        2>/dev/null || true
      # Aguarda até 30 s pelo arquivo de settings
      for _i in $(seq 1 15); do
        for _sf in "settings-store.json" "settings.json"; do
          if [[ -f "${_DOCKER_BASE}/${_sf}" ]]; then
            _DOCKER_SETTINGS="${_DOCKER_BASE}/${_sf}"
            break 2
          fi
        done
        sleep 2
      done
    fi

    if [[ -n "$_DOCKER_SETTINGS" ]]; then
      cp "$_DOCKER_SETTINGS" "${_DOCKER_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
      _TMP=$(mktemp)
      if jq --arg d "$_DISTRO" '
        .wslEngineEnabled = true |
        .enableIntegrationWithDefaultWslDistro = true |
        if .integratedWslDistros == null then .integratedWslDistros = [$d]
        elif (.integratedWslDistros | index($d)) == null then .integratedWslDistros += [$d]
        else . end
      ' "$_DOCKER_SETTINGS" > "$_TMP" 2>/dev/null && mv "$_TMP" "$_DOCKER_SETTINGS"; then
        ok "Integração WSL2 habilitada para ${_DISTRO} em $(basename "$_DOCKER_SETTINGS")."
        note "Reiniciando Docker Desktop para aplicar as configurações..."
        powershell.exe -Command \
          "Stop-Process -Name 'Docker Desktop' -Force -ErrorAction SilentlyContinue" \
          2>/dev/null || true
        sleep 3
        powershell.exe -Command \
          "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" \
          2>/dev/null || true
        # Aguarda daemon ficar acessível (até 60 s)
        _retries=30
        while [[ $_retries -gt 0 ]]; do
          docker info >/dev/null 2>&1 && break
          sleep 2
          _retries=$((_retries - 1))
        done
        if docker info >/dev/null 2>&1; then
          DOCK_V=$(docker --version | awk '{print $3}' | tr -d ',')
          ok "Docker daemon acessível — ${DOCK_V}"
          report_ok "Docker Desktop" "Containers para LocalStack (DynamoDB local)" "${DOCK_V} — integração WSL2 habilitada"
        else
          report_warn "Docker Desktop" "Containers para LocalStack (DynamoDB local)" \
            "Instalado e integração WSL2 configurada — daemon ainda não acessível (aguarde e tente novamente)"
        fi
      else
        note "Falha ao atualizar $(basename "$_DOCKER_SETTINGS") — habilite manualmente:"
        note "  Docker Desktop → Settings → Resources → WSL Integration → ${_DISTRO}"
        report_warn "Docker Desktop" "Containers para LocalStack (DynamoDB local)" \
          "Instalado — habilite integração WSL2 manualmente para ${_DISTRO}"
      fi
    else
      note "Arquivo de settings do Docker Desktop não encontrado — pode ser necessário abri-lo uma vez."
      note "Após abrir, habilite: Settings → Resources → WSL Integration → ${_DISTRO}"
      report_warn "Docker Desktop" "Containers para LocalStack (DynamoDB local)" \
        "Instalado — settings não encontrado; habilite integração WSL2 manualmente"
    fi
  else
    note "Alternativa: instalar Docker Engine direto no WSL:"
    note "  curl -fsSL https://get.docker.com | sh"
    note "  sudo usermod -aG docker \$USER && newgrp docker"
    report_warn "Docker Desktop" "Containers para LocalStack (DynamoDB local)" "Instalação automática falhou — siga as instruções acima"
  fi
else
  note "Docker não encontrado. Instale via: curl -fsSL https://get.docker.com | sh"
  report_warn "Docker" "Containers para LocalStack (DynamoDB local)" "Não encontrado — instale manualmente"
fi

# ── 5. Ferramentas opcionais ───────────────────────────────────────────────────

if [[ "$OPTIONAL" == true ]]; then
  step "AWS CLI v2"
  if already aws; then
    AWS_V=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
    skip "aws-cli ${AWS_V}"
    report_skip "aws-cli v2" "Interface de linha de comando para AWS" "${AWS_V} já instalado"
  else
    TMP=$(mktemp -d)
    ARCH=$(uname -m)
    AWS_ARCH=$([[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && echo "aarch64" || echo "x86_64")
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "${TMP}/awscliv2.zip"
    unzip -q "${TMP}/awscliv2.zip" -d "${TMP}"
    sudo "${TMP}/aws/install"
    rm -rf "${TMP}"
    AWS_V=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
    ok "aws-cli ${AWS_V}"
    report_ok "aws-cli v2" "Interface de linha de comando para AWS" "${AWS_V} instalado (${AWS_ARCH})"
  fi

  step "aws-cdk e cdklocal"
  if already cdk; then
    CDK_V=$(cdk --version 2>/dev/null | awk '{print $1}')
    skip "cdk ${CDK_V}"
    report_skip "aws-cdk" "Infraestrutura como código para AWS" "${CDK_V} já instalado"
  else
    npm install -g aws-cdk --silent
    CDK_V=$(cdk --version 2>/dev/null | awk '{print $1}')
    ok "aws-cdk ${CDK_V}"
    report_ok "aws-cdk" "Infraestrutura como código para AWS" "${CDK_V} instalado via npm"
  fi
  if already cdklocal; then
    skip "cdklocal"
    report_skip "cdklocal" "Wrapper do CDK para LocalStack" "Já instalado"
  else
    npm install -g aws-cdk-local --silent
    ok "cdklocal"
    report_ok "cdklocal" "Wrapper do CDK para LocalStack" "Instalado via npm"
  fi

  step "awslocal"
  if already awslocal; then
    skip "awslocal"
    report_skip "awslocal" "Wrapper do aws-cli para LocalStack" "Já instalado"
  else
    pip3 install --quiet awscli-local
    ok "awslocal"
    report_ok "awslocal" "Wrapper do aws-cli para LocalStack" "Instalado via pip3"
  fi

  step "ripgrep"
  if already rg; then
    RG_V=$(rg --version | head -1 | awk '{print $2}')
    skip "rg ${RG_V}"
    report_skip "ripgrep" "Busca de texto rápida (doctor.sh)" "${RG_V} já instalado"
  else
    sudo apt-get install -y -qq ripgrep
    RG_V=$(rg --version | head -1 | awk '{print $2}')
    ok "rg ${RG_V}"
    report_ok "ripgrep" "Busca de texto rápida (doctor.sh)" "${RG_V} instalado via apt"
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
  report_skip "GitHub Auth" "Autenticação para clone e operações de repo" "@${GH_USER} já autenticado"
elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
  gh auth login --with-token <<< "${GITHUB_TOKEN}"
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  ok "gh autenticado via GITHUB_TOKEN como @${GH_USER}"
  report_ok "GitHub Auth" "Autenticação para clone e operações de repo" "Via GITHUB_TOKEN como @${GH_USER}"
else
  note "Nenhuma autenticação encontrada."
  note "Para evitar o fluxo interativo de browser, defina GITHUB_TOKEN antes de rodar:"
  note "  export GITHUB_TOKEN=ghp_seu_token"
  note "  wget -qO- <url> | bash"
  note ""
  note "Gere um token em: github.com → Settings → Developer settings → Personal access tokens"
  note "Escopo necessário: repo"
  note ""
  gh auth login
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "desconhecido")
  report_ok "GitHub Auth" "Autenticação para clone e operações de repo" "Via device flow como @${GH_USER}"
fi

# ── 8. Clone do repositório ───────────────────────────────────────────────────

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

# ── 9. Dependências do projeto ────────────────────────────────────────────────

step "Instalando dependências do projeto (npm install)"
if [[ -d "${CLONE_DIR}/node_modules" ]]; then
  skip "node_modules já presente"
  report_skip "npm install" "Dependências do projeto (node_modules)" "Já presentes"
else
  npm --prefix "${CLONE_DIR}" install --silent
  ok "node_modules instalado"
  report_ok "npm install" "Dependências do projeto (node_modules)" "Instaladas em ${CLONE_DIR}/node_modules"
fi

# ── 10. Validação final ───────────────────────────────────────────────────────

step "Validando ambiente com check-env.sh"
echo ""
bash "${CLONE_DIR}/prodops/scripts/check-env.sh" || true

# ── Report final ───────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  RELATÓRIO DE INSTALAÇÃO — ProdOps Setup${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo ""

# Cabeçalho da tabela
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
  echo "    # Configure Docker Desktop com integração WSL2 antes de rodar:"
  echo "    #   Settings → Resources → WSL Integration → Enable for this distro"
fi
echo "    npm run local:start   # sobe LocalStack"
echo "    npm test              # roda os testes"
echo ""
echo "  Para rediagnosticar:"
echo "    bash prodops/scripts/check-env.sh --fix-hints"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
