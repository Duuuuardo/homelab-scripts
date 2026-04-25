#!/usr/bin/env bash
# =============================================================================
# lib.sh — funções compartilhadas entre todos os install scripts
# Rodado dentro do LXC. Source este arquivo no início de cada install script.
# =============================================================================

set -euo pipefail

RD='\033[01;31m'; GN='\033[1;92m'; YW='\033[33m'; CL='\033[m'; BL='\033[36m'
BFR="\\r\\033[K"
CM="${GN}✔${CL}"
CROSS="${RD}✖${CL}"

msg_info()  { echo -ne "  ${YW}${1}...${CL}"; }
msg_ok()    { echo -e "${BFR}  ${CM} ${GN}${1}${CL}"; }
msg_error() { echo -e "${BFR}  ${CROSS} ${RD}${1}${CL}"; exit 1; }
msg_warn()  { echo -e "  ${YW}⚠  ${1}${CL}"; }

rnd_pw() { openssl rand -base64 24 | tr -d '/+=\n'; }

install_docker() {
  msg_info "Configurando repositório Docker"
  apt-get install -y ca-certificates curl gnupg lsb-release >/dev/null 2>&1
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc 2>/dev/null
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update >/dev/null 2>&1
  msg_ok "Repositório Docker configurado"

  msg_info "Instalando Docker"
  apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
  systemctl enable --now docker >/dev/null 2>&1
  msg_ok "Docker $(docker --version | awk '{print $3}' | tr -d ',') instalado"
}

clone_repo() {
  local repo_url="$1"
  local branch="${2:-main}"
  msg_info "Clonando repositório homelab"
  apt-get install -y git >/dev/null 2>&1
  if [[ -d /opt/homelab-scripts/.git ]]; then
    git -C /opt/homelab-scripts fetch origin "$branch" >/dev/null 2>&1
    git -C /opt/homelab-scripts reset --hard "origin/$branch" >/dev/null 2>&1
  else
    git clone --depth 1 --branch "$branch" "$repo_url" /opt/homelab-scripts >/dev/null 2>&1
  fi
  msg_ok "Repositório clonado em /opt/homelab-scripts"
}

deploy_stack() {
  local stack_folder="$1"
  local stack_dir="/opt/stacks/${stack_folder}"

  msg_info "Copiando stack ${stack_folder}"
  mkdir -p "$stack_dir"
  cp -r "/opt/homelab-scripts/${stack_folder}/." "$stack_dir/"
  cd "$stack_dir"
  [[ ! -f .env && -f .env.example ]] && cp .env.example .env
  msg_ok "Stack copiado para ${stack_dir}"

  msg_info "Baixando imagens Docker"
  docker compose pull >/dev/null 2>&1
  msg_ok "Imagens baixadas"

  msg_info "Iniciando containers"
  docker compose up -d >/dev/null 2>&1
  msg_ok "Containers iniciados"
}

make_update_helper() {
  local stack_dir="$1"
  cat > /usr/bin/update << EOF
#!/usr/bin/env bash
cd ${stack_dir}
docker compose pull
docker compose up -d
EOF
  chmod +x /usr/bin/update
}

# Forçar apt IPv4 — resolve bug de IPv6 sem rota em home labs
force_apt_ipv4() {
  echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
}

base_setup() {
  force_apt_ipv4
  msg_info "Atualizando sistema"
  apt-get update >/dev/null 2>&1
  apt-get upgrade -y >/dev/null 2>&1
  msg_ok "Sistema atualizado"
}
