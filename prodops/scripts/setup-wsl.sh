#!/usr/bin/env bash
# setup-wsl.sh — Instala todas as ferramentas necessárias para desenvolver
#                neste repositório em ambientes WSL2 (Ubuntu/Debian).
#
# Uso:
#   bash prodops/scripts/setup-wsl.sh
#   bash prodops/scripts/setup-wsl.sh --optional   (inclui aws-cli, cdk, cdklocal, awslocal, rg)
#
# Pré-requisitos:
#   - WSL2 com Ubuntu 20.04+ ou Debian 11+
#   - Docker Desktop instalado no Windows com integração WSL2 habilitada
#     (Settings → Resources → WSL Integration → Enable for your distro)
#
# Após a instalação, reabra o terminal e execute:
#   bash prodops/scripts/check-env.sh --fix-hints
#
# Exit code:
#   0  instalação concluída sem erros fatais
#   1  pré-requisito de SO não atendido ou erro inesperado

set -euo pipefail

# ── Detecção de SO ─────────────────────────────────────────────────────────────

if [[ ! -f /etc/debian_version ]]; then
  echo "ERRO: este script suporta apenas distribuições baseadas em Debian/Ubuntu." >&2
  echo "      Para outros sistemas, instale as ferramentas manualmente e rode:" >&2
  echo "      bash prodops/scripts/check-env.sh --fix-hints" >&2
  exit 1
fi

if ! grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
  echo "AVISO: ambiente não parece ser WSL. O script continuará, mas Docker deve" >&2
  echo "       ser gerenciado separadamente (este script não instala o daemon)." >&2
fi

# ── Flags ──────────────────────────────────────────────────────────────────────

OPTIONAL=false
for arg in "$@"; do
  [[ "$arg" == "--optional" ]] && OPTIONAL=true
done

# ── Helpers ────────────────────────────────────────────────────────────────────

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

step()  { echo -e "\n${BOLD}▶ $*${RESET}"; }
ok()    { echo -e "  ${GREEN}✔${RESET} $*"; }
skip()  { echo -e "  ${YELLOW}–${RESET} $* (já instalado)"; }
note()  { echo -e "  ${YELLOW}!${RESET} $*"; }

already() { command -v "$1" >/dev/null 2>&1; }

# ── Cabeçalho ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║          ProdOps — setup-wsl.sh                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Ambiente : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Debian/Ubuntu")"
echo "  Modo     : $([ "$OPTIONAL" = true ] && echo "completo (--optional)" || echo "essencial (sem --optional)")"

# ── 1. apt update ──────────────────────────────────────────────────────────────

step "Atualizando lista de pacotes apt"
sudo apt-get update -qq
ok "apt update concluído"

# ── 2. Dependências base ───────────────────────────────────────────────────────

step "Instalando dependências base (git, curl, jq, awk, diff, sed, uuid-runtime, python3, pip)"

PKGS=(git curl jq gawk diffutils sed uuid-runtime python3 python3-pip unzip)
MISSING_PKGS=()
for pkg in "${PKGS[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING_PKGS+=("$pkg")
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
  sudo apt-get install -y -qq "${MISSING_PKGS[@]}"
  ok "Instalados: ${MISSING_PKGS[*]}"
else
  skip "Todos os pacotes base já presentes"
fi

# PyYAML
if python3 -c "import yaml" 2>/dev/null; then
  skip "PyYAML"
else
  pip3 install --quiet pyyaml
  ok "PyYAML instalado"
fi

# ── 3. Node.js via nvm ────────────────────────────────────────────────────────

step "Instalando nvm + Node.js 20"

NVM_DIR="${HOME}/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
  NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "v0.40.1")
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
  ok "nvm ${NVM_LATEST} instalado"
else
  skip "nvm (${NVM_DIR} já existe)"
fi

# Carrega nvm sem reiniciar o shell
export NVM_DIR="${HOME}/.nvm"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

if command -v node >/dev/null 2>&1; then
  NODE_MAJ=$(node --version | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_MAJ" -ge 20 ]]; then
    skip "Node.js $(node --version) (≥ 20)"
  else
    nvm install 20 --silent
    nvm use 20
    nvm alias default 20
    ok "Node.js atualizado para $(node --version)"
  fi
else
  nvm install 20 --silent
  nvm use 20
  nvm alias default 20
  ok "Node.js $(node --version) instalado"
fi

# ── 4. GitHub CLI ─────────────────────────────────────────────────────────────

step "Instalando GitHub CLI (gh)"

if already gh; then
  skip "gh $(gh --version | head -1 | awk '{print $3}')"
else
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh
  ok "gh $(gh --version | head -1 | awk '{print $3}') instalado"
fi

# ── 5. Docker (validação WSL) ─────────────────────────────────────────────────

step "Verificando Docker"

if already docker && docker info >/dev/null 2>&1; then
  skip "Docker $(docker --version | awk '{print $3}' | tr -d ',') com daemon acessível"
elif already docker; then
  note "Docker instalado mas daemon não está acessível."
  note "No Docker Desktop (Windows): Settings → Resources → WSL Integration"
  note "Habilite a integração para esta distro e reinicie o Docker Desktop."
else
  note "Docker não encontrado no WSL."
  note "Instale o Docker Desktop no Windows e habilite a integração WSL2:"
  note "  https://docs.docker.com/desktop/wsl/"
  note "Alternativa (Docker Engine direto no WSL):"
  note "  curl -fsSL https://get.docker.com | sh"
  note "  sudo usermod -aG docker \$USER && newgrp docker"
fi

# ── 6. Ferramentas opcionais ───────────────────────────────────────────────────

if [[ "$OPTIONAL" == true ]]; then

  step "AWS CLI v2"
  if already aws; then
    skip "aws-cli $(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)"
  else
    TMPDIR=$(mktemp -d)
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${TMPDIR}/awscliv2.zip"
    unzip -q "${TMPDIR}/awscliv2.zip" -d "${TMPDIR}"
    sudo "${TMPDIR}/aws/install"
    rm -rf "${TMPDIR}"
    ok "aws-cli $(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2) instalado"
  fi

  step "aws-cdk e cdklocal"
  if already cdk; then
    skip "cdk $(cdk --version 2>/dev/null | awk '{print $1}')"
  else
    npm install -g aws-cdk --silent
    ok "cdk $(cdk --version 2>/dev/null | awk '{print $1}') instalado"
  fi
  if already cdklocal; then
    skip "cdklocal"
  else
    npm install -g aws-cdk-local --silent
    ok "cdklocal instalado"
  fi

  step "awslocal"
  if already awslocal; then
    skip "awslocal"
  else
    pip3 install --quiet awscli-local
    ok "awslocal instalado"
  fi

  step "ripgrep"
  if already rg; then
    skip "rg $(rg --version | head -1 | awk '{print $2}')"
  else
    sudo apt-get install -y -qq ripgrep
    ok "rg $(rg --version | head -1 | awk '{print $2}') instalado"
  fi

fi

# ── 7. Configuração do shell ───────────────────────────────────────────────────

step "Configurando shell (~/.bashrc / ~/.zshrc)"

NVM_BLOCK='
# nvm — carregado por setup-wsl.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$RC" ]] && ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
    echo "$NVM_BLOCK" >> "$RC"
    ok "Bloco nvm adicionado em $RC"
  elif [[ -f "$RC" ]]; then
    skip "nvm já configurado em $RC"
  fi
done

# ── Resumo ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Instalação concluída.${RESET}"
echo ""
echo "  Próximos passos:"
echo "    1. Reabra o terminal (ou execute: source ~/.bashrc)"
echo "    2. Autentique o GitHub CLI:  gh auth login"
if ! already docker || ! docker info >/dev/null 2>&1; then
  echo "    3. Configure Docker Desktop com integração WSL2"
  echo "       https://docs.docker.com/desktop/wsl/"
fi
echo ""
echo "  Valide o ambiente:"
echo "    bash prodops/scripts/check-env.sh --fix-hints"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
