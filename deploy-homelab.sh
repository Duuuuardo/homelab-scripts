#!/usr/bin/env bash
# =============================================================================
# deploy-homelab.sh - Eduardo (Duuuuardo)
# =============================================================================
# Usage:
#   ./deploy-homelab.sh              # interativo
#   ./deploy-homelab.sh all          # todos
#   ./deploy-homelab.sh infra dns    # especificos
#   ./deploy-homelab.sh --yes all    # sem confirmacoes (gera tudo automaticamente)
#   ./deploy-homelab.sh --skip-tailscale infra

set -euo pipefail

# =============================================================================
# Config de rede
# =============================================================================

BRIDGE="${BRIDGE:-vmbr0}"
GATEWAY="${GATEWAY:-192.168.0.1}"
CIDR="${CIDR:-24}"
DNS_SERVER="${DNS_SERVER:-1.1.1.1}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
CONTAINER_STORAGE="${CONTAINER_STORAGE:-local-lvm}"
TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
DEBIAN_VERSION="${DEBIAN_VERSION:-12}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"

# CTID:hostname:IP:cpu:ram_mb:disk_gb
declare -A CT=(
  [infra]="100:infra:192.168.0.20:2:2048:16"
  [media]="101:media:192.168.0.21:4:8192:120"
  [dns]="102:dns:192.168.0.22:1:1024:8"
  [cloud]="103:cloud:192.168.0.23:4:4096:64"
  [knowledge]="104:knowledge:192.168.0.24:2:2048:16"
  [games]="105:games:192.168.0.25:4:8192:64"
  [utilities]="107:utilities:192.168.0.27:2:4096:32"
)

ALL_STACKS=(infra media dns cloud knowledge games utilities)

AUTO_YES=0
SKIP_TAILSCALE=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)         AUTO_YES=1 ;;
    --skip-tailscale) SKIP_TAILSCALE=1 ;;
  esac
done

# Senhas: DEFAULT_PASSWORD e associative array por CT
DEFAULT_PASSWORD=""            # "" = sem senha definida globalmente
TAILSCALE_AUTHKEY=""
declare -A CT_PASSWORD=()      # senha individual por stack, ex: CT_PASSWORD[media]="xxx"
CREDENTIALS_FILE="/root/homelab-credentials.txt"

# =============================================================================
# Helpers
# =============================================================================

RD='\033[01;31m'; GN='\033[1;92m'; YW='\033[33m'; CL='\033[m'; BL='\033[36m'
BOLD='\033[1m'

msg()     { echo -e "${GN}✔${CL} $*"; }
info()    { echo -e "${BL}→${CL} $*"; }
warn()    { echo -e "${YW}⚠${CL}  $*"; }
die()     { echo -e "${RD}✖${CL}  $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}${BL}── $* ${CL}"; }
hr()      { echo -e "${BL}$(printf '─%.0s' {1..48})${CL}"; }

confirm() {
  [[ "$AUTO_YES" == "1" ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy] ]]
}

gen_password() {
  openssl rand -base64 18 | tr -d '/+='
}

# Lê senha do usuario com confirmação. Seta VAR.
read_password() {
  local var="$1"
  while true; do
    read -r -s -p "  Senha: " v1; echo
    read -r -s -p "  Confirme: " v2; echo
    [[ -z "$v1" ]] && echo "  Nao pode ser vazia." && continue
    [[ "$v1" != "$v2" ]] && echo "  Nao confere, tente novamente." && continue
    printf -v "$var" '%s' "$v1"
    break
  done
}

# Salva linha no arquivo de credenciais
save_cred() {
  echo "$*" >> "$CREDENTIALS_FILE"
}

require_root() { [[ "${EUID}" -eq 0 ]] || die "Run as root no Proxmox host."; }
check_proxmox() {
  command -v pct   >/dev/null 2>&1 || die "pct not found."
  command -v pveam >/dev/null 2>&1 || die "pveam not found."
}

# =============================================================================
# Prompt global de configuracao
# =============================================================================

prompt_global_config() {
  echo
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${CL}"
  echo -e "${BOLD}║     Homelab Deploy — Configuracao inicial    ║${CL}"
  echo -e "${BOLD}╚══════════════════════════════════════════════╝${CL}"

  # ── Senha padrao ────────────────────────────────────────────────────────
  section "Senha root dos LXCs"
  echo
  echo "  Escolha como definir a senha root de todos os LXCs:"
  echo "    1) Uma senha igual para todos (voce digita)"
  echo "    2) Gerar uma senha aleatoria para todos"
  echo "    3) Sem senha padrao — definir individualmente por LXC"
  echo

  local opt="2"
  if [[ "$AUTO_YES" == "0" ]]; then
    read -r -p "  Opcao [2]: " opt
    opt="${opt:-2}"
  fi

  case "$opt" in
    1)
      read_password DEFAULT_PASSWORD
      msg "Senha padrao definida."
      ;;
    3)
      DEFAULT_PASSWORD=""
      msg "Sem padrao — voce definirah a senha de cada LXC individualmente."
      ;;
    *)
      DEFAULT_PASSWORD="$(gen_password)"
      msg "Senha padrao gerada automaticamente."
      echo -e "  ${YW}Senha: ${DEFAULT_PASSWORD}${CL}"
      ;;
  esac

  # ── Tailscale ────────────────────────────────────────────────────────────
  if [[ "$SKIP_TAILSCALE" == "0" ]]; then
    section "Tailscale"
    echo
    echo "  Auth key para autenticar automaticamente (Enter para pular)."
    echo "  Gere em: https://login.tailscale.com/admin/settings/keys"
    echo
    if [[ "$AUTO_YES" == "0" ]]; then
      read -r -p "  Auth key: " TAILSCALE_AUTHKEY
    fi
  fi

  # Inicia arquivo de credenciais
  {
    echo "================================================"
    echo " Homelab Credentials"
    echo " Gerado: $(date)"
    echo "================================================"
    echo
    if [[ -n "$DEFAULT_PASSWORD" ]]; then
      echo "Senha root padrao dos LXCs: ${DEFAULT_PASSWORD}"
    else
      echo "Senha root: definida individualmente por LXC"
    fi
    echo
    echo "Senhas individuais:"
  } > "$CREDENTIALS_FILE"
  chmod 600 "$CREDENTIALS_FILE"
}

# =============================================================================
# Prompt por LXC — chamado antes de cada deploy
# =============================================================================

prompt_lxc_password() {
  local stack="$1" ctid="$2" hostname="$3"

  # --yes: usa o padrão sem perguntar
  if [[ "$AUTO_YES" == "1" ]]; then
    CT_PASSWORD[$stack]="${DEFAULT_PASSWORD:-$(gen_password)}"
    return
  fi

  echo
  hr
  echo -e "  ${BOLD}LXC: ${hostname} (CT ${ctid})${CL}"
  hr
  echo
  echo "  Senha root para este LXC:"

  if [[ -n "$DEFAULT_PASSWORD" ]]; then
    echo "    1) Usar senha padrao  (${DEFAULT_PASSWORD:0:4}****)"
    echo "    2) Digitar uma senha diferente"
    echo "    3) Gerar uma senha unica para este LXC"
    echo "    4) Sem senha (acesso so via pct exec)"
    echo
    read -r -p "  Opcao [1]: " opt
    opt="${opt:-1}"
  else
    echo "    1) Digitar uma senha"
    echo "    2) Gerar senha aleatoria"
    echo "    3) Sem senha (acesso so via pct exec)"
    echo
    read -r -p "  Opcao [2]: " opt
    opt="${opt:-2}"
  fi

  local pw=""

  if [[ -n "$DEFAULT_PASSWORD" ]]; then
    case "$opt" in
      2) read_password pw ;;
      3) pw="$(gen_password)"; echo -e "  ${YW}Senha gerada: ${pw}${CL}" ;;
      4) pw="" ;;
      *) pw="$DEFAULT_PASSWORD" ;;
    esac
  else
    case "$opt" in
      1) read_password pw ;;
      3) pw="" ;;
      *) pw="$(gen_password)"; echo -e "  ${YW}Senha gerada: ${pw}${CL}" ;;
    esac
  fi

  CT_PASSWORD[$stack]="$pw"

  # Salva no arquivo de credenciais
  if [[ -n "$pw" ]]; then
    save_cred "  ${hostname} (CT ${ctid}): ${pw}"
  else
    save_cred "  ${hostname} (CT ${ctid}): (sem senha)"
  fi
}

# =============================================================================
# Tailscale
# =============================================================================

install_tailscale_on_pve() {
  section "Tailscale no Proxmox host"

  if command -v tailscale >/dev/null 2>&1; then
    info "Tailscale ja instalado ($(tailscale version | head -1))."
    local ts_ip
    ts_ip="$(tailscale ip -4 2>/dev/null || echo '')"
    if [[ -n "$ts_ip" ]]; then
      msg "IP: ${ts_ip}"
      return
    fi
  else
    info "Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1
    msg "Tailscale instalado."
  fi

  if [[ -n "$TAILSCALE_AUTHKEY" ]]; then
    info "Autenticando..."
    tailscale up \
      --authkey="$TAILSCALE_AUTHKEY" \
      --advertise-routes=192.168.0.0/24 \
      --accept-dns=false \
      >/dev/null 2>&1 && msg "Autenticado!" || warn "Falha — verifique a key"
  else
    echo
    echo -e "${YW}  Execute para autenticar:${CL}"
    echo -e "    ${GN}tailscale up --advertise-routes=192.168.0.0/24 --accept-dns=false${CL}"
    echo -e "${YW}  Depois: https://login.tailscale.com/admin/machines${CL}"
  fi
}

# =============================================================================
# Template LXC
# =============================================================================

find_or_download_template() {
  local dir
  dir="$(pvesm path "${TEMPLATE_STORAGE}:vztmpl" 2>/dev/null || echo "/var/lib/vz/template/cache")"
  mkdir -p "$dir"

  local existing
  existing="$(find "$dir" -maxdepth 1 -name "debian-${DEBIAN_VERSION}-standard_*.tar.zst" \
    | sort -V | tail -n1 || true)"
  if [[ -n "$existing" ]]; then
    echo "${TEMPLATE_STORAGE}:vztmpl/$(basename "$existing")"
    return
  fi

  info "Baixando template Debian ${DEBIAN_VERSION}..."
  pveam update >/dev/null
  local tmpl
  tmpl="$(pveam available --section system | awk '{print $2}' \
    | grep "debian-${DEBIAN_VERSION}-standard" | sort -V | tail -n1)"
  [[ -n "$tmpl" ]] || die "Template Debian ${DEBIAN_VERSION} nao encontrado."
  pveam download "$TEMPLATE_STORAGE" "$tmpl" >/dev/null
  echo "${TEMPLATE_STORAGE}:vztmpl/$(basename "$tmpl")"
}

# =============================================================================
# LXC
# =============================================================================

create_lxc() {
  local ctid="$1" hostname="$2" ip="$3" cpu="$4" ram="$5" disk="$6" \
        template="$7" password="$8"

  if pct status "$ctid" >/dev/null 2>&1; then
    info "CT ${ctid} (${hostname}) ja existe — pulando criacao."
    # Aplica senha mesmo assim se definida
    if [[ -n "$password" ]]; then
      pct exec "$ctid" -- bash -c "echo 'root:${password}' | chpasswd" 2>/dev/null || true
      info "Senha atualizada no CT ${ctid}."
    fi
    return
  fi

  info "Criando CT ${ctid} (${hostname}) @ ${ip}..."

  local password_args=()
  [[ -n "$password" ]] && password_args=(--password "$password")

  pct create "$ctid" "$template" \
    --hostname    "$hostname" \
    --cores       "$cpu" \
    --memory      "$ram" \
    --swap        512 \
    --rootfs      "${CONTAINER_STORAGE}:${disk}" \
    --net0        "name=eth0,bridge=${BRIDGE},ip=${ip}/${CIDR},gw=${GATEWAY}" \
    --nameserver  "$DNS_SERVER" \
    --ostype      debian \
    --unprivileged 0 \
    --features    "nesting=1,keyctl=1" \
    "${password_args[@]}" \
    --onboot      1 \
    --tags        "homelab;docker;${hostname}"

  msg "CT ${ctid} (${hostname}) criado."
}

start_lxc() {
  local ctid="$1"
  if ! pct status "$ctid" 2>/dev/null | grep -q "running"; then
    info "Iniciando CT ${ctid}..."
    pct start "$ctid"
    sleep 8
  fi
}

fix_apt_ipv4() {
  pct exec "$1" -- bash -c \
    'echo "Acquire::ForceIPv4 \"true\";" > /etc/apt/apt.conf.d/99force-ipv4'
}

set_timezone() {
  pct exec "$1" -- bash -c \
    "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime 2>/dev/null || true"
}

# =============================================================================
# Roda install script dentro do LXC
# =============================================================================

run_install_script() {
  local ctid="$1" stack="$2"
  local install_script="${INSTALL_DIR}/${stack}-install.sh"
  local lib_script="${INSTALL_DIR}/_lib.sh"

  [[ -f "$install_script" ]] || { warn "${stack}-install.sh nao encontrado."; return; }

  info "Rodando ${stack}-install.sh no CT ${ctid}..."
  pct exec "$ctid" -- mkdir -p /tmp/homelab-install
  pct push "$ctid" "$lib_script"     /tmp/homelab-install/_lib.sh
  pct push "$ctid" "$install_script" /tmp/homelab-install/install.sh
  pct exec "$ctid" -- bash /tmp/homelab-install/install.sh
  pct exec "$ctid" -- rm -rf /tmp/homelab-install
  msg "Stack '${stack}' instalado no CT ${ctid}."
}

# =============================================================================
# Deploy de um stack
# =============================================================================

deploy_stack() {
  local name="$1"
  IFS=":" read -r ctid hostname ip cpu ram disk <<< "${CT[$name]}"

  echo
  echo -e "${BOLD}${BL}╔══════════════════════════════════════════════╗${CL}"
  printf "${BOLD}${BL}║  %-44s║${CL}\n" "Stack: ${name}  |  CT ${ctid}  |  ${ip}"
  echo -e "${BOLD}${BL}╚══════════════════════════════════════════════╝${CL}"

  # Prompt de senha por LXC
  prompt_lxc_password "$name" "$ctid" "$hostname"
  local pw="${CT_PASSWORD[$name]:-}"

  local template
  template="$(find_or_download_template)"

  create_lxc "$ctid" "$hostname" "$ip" "$cpu" "$ram" "$disk" "$template" "$pw"
  start_lxc "$ctid"
  fix_apt_ipv4 "$ctid"
  set_timezone "$ctid"
  run_install_script "$ctid" "$name"
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
  local ts_ip
  ts_ip="$(tailscale ip -4 2>/dev/null || echo '<tailscale-ip>')"

  echo
  echo -e "${BOLD}${GN}╔══════════════════════════════════════════════╗${CL}"
  echo -e "${BOLD}${GN}║              Deploy finalizado!              ║${CL}"
  echo -e "${BOLD}${GN}╚══════════════════════════════════════════════╝${CL}"
  echo
  echo -e "${BOLD}Tailscale IP do PVE:${CL} ${ts_ip}"
  echo
  echo -e "${BOLD}Servicos:${CL}"
  printf "  %-14s http://%s\n" "Homepage"    "192.168.0.20  (ou :3000)"
  printf "  %-14s http://%s\n" "Uptime Kuma" "192.168.0.20:3001"
  printf "  %-14s http://%s\n" "AdGuard"     "192.168.0.22:3000"
  printf "  %-14s http://%s\n" "Jellyfin"    "192.168.0.21:8096"
  printf "  %-14s http://%s\n" "Seerr"       "192.168.0.21:5055"
  printf "  %-14s http://%s\n" "Nextcloud"   "192.168.0.23:8081"
  printf "  %-14s http://%s\n" "BookStack"   "192.168.0.24:6875"
  printf "  %-14s http://%s\n" "Memos"       "192.168.0.24:5230"
  printf "  %-14s http://%s\n" "Linkding"    "192.168.0.24:9090"
  printf "  %-14s http://%s\n" "Neko"        "192.168.0.27:8080"
  echo
  echo -e "${YW}Todas as credenciais salvas em:${CL}"
  echo "  ${CREDENTIALS_FILE}"
  echo
  echo -e "${YW}Credenciais de apps dentro dos LXCs:${CL}"
  echo "  pct exec 103 -- cat /root/nextcloud-credentials.txt"
  echo "  pct exec 104 -- cat /root/knowledge-credentials.txt"
  echo "  pct exec 107 -- cat /root/utilities-credentials.txt"
  echo
  echo -e "${YW}Atualizar stack:  pct exec <CTID> -- update${CL}"
  echo -e "${YW}Painel NPM:       pct exec 100 -- docker ps --filter name=nginx-proxy-manager${CL}"

  # Mostra o arquivo de credenciais no final
  echo
  echo -e "${BOLD}Resumo de senhas dos LXCs:${CL}"
  grep -A 999 "Senhas individuais:" "$CREDENTIALS_FILE" | tail -n +2 | \
    while IFS= read -r line; do echo "  $line"; done
}

# =============================================================================
# Main
# =============================================================================

main() {
  require_root
  check_proxmox

  local raw_targets=()
  for arg in "$@"; do
    case "$arg" in --yes|-y|--skip-tailscale) continue ;; esac
    raw_targets+=("$arg")
  done

  local targets=()

  if [[ ${#raw_targets[@]} -eq 0 ]]; then
    echo
    echo "Stacks disponiveis:"
    for s in "${ALL_STACKS[@]}"; do
      IFS=":" read -r ctid _ ip _ <<< "${CT[$s]}"
      printf "  %-12s CT %s @ %s\n" "$s" "$ctid" "$ip"
    done
    echo
    read -r -p "Quais stacks? (ex: infra media, ou 'all'): " input
    IFS=' ' read -r -a raw_targets <<< "$input"
  fi

  [[ "${raw_targets[*]:-}" == "all" ]] && raw_targets=("${ALL_STACKS[@]}")

  for t in "${raw_targets[@]}"; do
    [[ -n "${CT[$t]:-}" ]] && targets+=("$t") || warn "Stack desconhecido: '${t}'"
  done

  [[ ${#targets[@]} -eq 0 ]] && die "Nenhum stack valido."

  # Config global primeiro (senha padrao + tailscale)
  prompt_global_config

  echo
  echo "Stacks a deployar:"
  for t in "${targets[@]}"; do
    IFS=":" read -r ctid _ ip _ <<< "${CT[$t]}"
    printf "  %-12s CT %s @ %s\n" "$t" "$ctid" "$ip"
  done
  echo

  confirm "Continuar?" || { echo "Cancelado."; exit 0; }

  apt-get install -y git curl openssl >/dev/null 2>&1 || true

  [[ "$SKIP_TAILSCALE" == "0" ]] && install_tailscale_on_pve

  for stack in "${targets[@]}"; do
    deploy_stack "$stack"
  done

  print_summary
}

main "$@"
