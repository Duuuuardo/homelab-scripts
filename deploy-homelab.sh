#!/usr/bin/env bash
# =============================================================================
# deploy-homelab.sh - Eduardo (Duuuuardo)
# =============================================================================
# Cria LXCs via pct, instala Tailscale no PVE host, e roda os install
# scripts dentro de cada LXC (Docker + compose stacks + Caddy + Homepage).
#
# Usage:
#   ./deploy-homelab.sh              # interativo
#   ./deploy-homelab.sh all          # todos os stacks
#   ./deploy-homelab.sh infra dns    # específicos
#   ./deploy-homelab.sh --yes all    # sem confirmações
#   ./deploy-homelab.sh --skip-tailscale all

set -euo pipefail

# =============================================================================
# Config — ajuste conforme sua rede
# =============================================================================

BRIDGE="${BRIDGE:-vmbr0}"
GATEWAY="${GATEWAY:-192.168.0.1}"
CIDR="${CIDR:-24}"
DNS_SERVER="${DNS_SERVER:-1.1.1.1}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
CONTAINER_STORAGE="${CONTAINER_STORAGE:-local-lvm}"
TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
DEBIAN_VERSION="${DEBIAN_VERSION:-12}"
REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

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
    --yes|-y)           AUTO_YES=1 ;;
    --skip-tailscale)   SKIP_TAILSCALE=1 ;;
  esac
done

# =============================================================================
# Helpers
# =============================================================================

RD='\033[01;31m'; GN='\033[1;92m'; YW='\033[33m'; CL='\033[m'; BL='\033[36m'
msg()  { echo -e "${GN}✔${CL} $*"; }
info() { echo -e "${BL}→${CL} $*"; }
warn() { echo -e "${YW}⚠${CL}  $*"; }
die()  { echo -e "${RD}✖${CL}  $*" >&2; exit 1; }

confirm() {
  [[ "$AUTO_YES" == "1" ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy] ]]
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Run as root no Proxmox host."
}

check_proxmox() {
  command -v pct   >/dev/null 2>&1 || die "pct not found."
  command -v pveam >/dev/null 2>&1 || die "pveam not found."
}

# =============================================================================
# Tailscale no PVE host
# =============================================================================

install_tailscale_on_pve() {
  echo
  echo -e "${BL}══════════════════════════════════════${CL}"
  echo -e "${BL} Tailscale no Proxmox host            ${CL}"
  echo -e "${BL}══════════════════════════════════════${CL}"

  if command -v tailscale >/dev/null 2>&1; then
    info "Tailscale já instalado ($(tailscale version | head -1))."
    local ts_ip
    ts_ip="$(tailscale ip -4 2>/dev/null || echo '')"
    if [[ -n "$ts_ip" ]]; then
      msg "Tailscale IP: ${ts_ip}"
    else
      warn "Tailscale instalado mas não autenticado. Execute:"
      echo "    tailscale up --advertise-routes=192.168.0.0/24 --accept-dns=false"
    fi
    return
  fi

  info "Instalando Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1
  msg "Tailscale instalado."
  echo
  echo -e "${YW}  ► Autentique agora:${CL}"
  echo -e "    ${GN}tailscale up --advertise-routes=192.168.0.0/24 --accept-dns=false${CL}"
  echo
  echo -e "${YW}  Depois habilite subnet routes no painel Tailscale:${CL}"
  echo -e "    https://login.tailscale.com/admin/machines"
}

# =============================================================================
# Template LXC
# =============================================================================

find_or_download_template() {
  local dir
  dir="$(pvesm path "${TEMPLATE_STORAGE}:vztmpl" 2>/dev/null || echo "/var/lib/vz/template/cache")"
  mkdir -p "$dir"

  local existing
  existing="$(find "$dir" -maxdepth 1 -name "debian-${DEBIAN_VERSION}-standard_*.tar.zst" | sort -V | tail -n1 || true)"
  if [[ -n "$existing" ]]; then
    echo "${TEMPLATE_STORAGE}:vztmpl/$(basename "$existing")"
    return
  fi

  info "Baixando template Debian ${DEBIAN_VERSION}..."
  pveam update >/dev/null
  local tmpl
  tmpl="$(pveam available --section system | awk '{print $2}' | grep "debian-${DEBIAN_VERSION}-standard" | sort -V | tail -n1)"
  [[ -n "$tmpl" ]] || die "Template Debian ${DEBIAN_VERSION} não encontrado."
  pveam download "$TEMPLATE_STORAGE" "$tmpl" >/dev/null
  echo "${TEMPLATE_STORAGE}:vztmpl/$(basename "$tmpl")"
}

# =============================================================================
# LXC
# =============================================================================

create_lxc() {
  local ctid="$1" hostname="$2" ip="$3" cpu="$4" ram="$5" disk="$6" template="$7"

  if pct status "$ctid" >/dev/null 2>&1; then
    info "CT ${ctid} (${hostname}) já existe — pulando criação."
    return
  fi

  info "Criando CT ${ctid} (${hostname}) @ ${ip}..."
  pct create "$ctid" "$template" \
    --hostname   "$hostname" \
    --cores      "$cpu" \
    --memory     "$ram" \
    --swap       512 \
    --rootfs     "${CONTAINER_STORAGE}:${disk}" \
    --net0       "name=eth0,bridge=${BRIDGE},ip=${ip}/${CIDR},gw=${GATEWAY}" \
    --nameserver "$DNS_SERVER" \
    --ostype     debian \
    --unprivileged 0 \
    --features   "nesting=1,keyctl=1" \
    --onboot     1 \
    --tags       "homelab;docker;${hostname}"
  msg "CT ${ctid} criado."
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
  local ctid="$1"
  pct exec "$ctid" -- bash -c 'echo "Acquire::ForceIPv4 \"true\";" > /etc/apt/apt.conf.d/99force-ipv4'
}

set_timezone() {
  local ctid="$1"
  pct exec "$ctid" -- bash -c "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime 2>/dev/null || true"
}

# =============================================================================
# Roda install script dentro do LXC
# =============================================================================

run_install_script() {
  local ctid="$1"
  local stack="$2"
  local install_script="${INSTALL_DIR}/${stack}-install.sh"
  local lib_script="${INSTALL_DIR}/_lib.sh"

  if [[ ! -f "$install_script" ]]; then
    warn "install/${stack}-install.sh não encontrado — pulando."
    return
  fi

  info "Rodando ${stack}-install.sh no CT ${ctid}..."
  pct exec "$ctid" -- mkdir -p /tmp/homelab-install
  pct push "$ctid" "$lib_script"     /tmp/homelab-install/_lib.sh
  pct push "$ctid" "$install_script" /tmp/homelab-install/install.sh
  REPO_URL="$REPO_URL" pct exec "$ctid" -- bash /tmp/homelab-install/install.sh
  pct exec "$ctid" -- rm -rf /tmp/homelab-install
  msg "Stack '${stack}' instalado no CT ${ctid}."
}

# =============================================================================
# Deploy de um stack
# =============================================================================

deploy_stack() {
  local name="$1"
  local spec="${CT[$name]}"
  IFS=":" read -r ctid hostname ip cpu ram disk <<< "$spec"

  echo
  echo -e "${BL}══════════════════════════════════════${CL}"
  echo -e "${BL} Stack: ${name} │ CT ${ctid} │ ${ip}  ${CL}"
  echo -e "${BL}══════════════════════════════════════${CL}"

  local template
  template="$(find_or_download_template)"

  create_lxc "$ctid" "$hostname" "$ip" "$cpu" "$ram" "$disk" "$template"
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
  msg "Deploy finalizado!"
  echo
  echo -e "${GN}Tailscale IP do PVE:${CL} ${ts_ip}"
  echo
  echo -e "${GN}Serviços (via Tailscale ou rede local):${CL}"
  printf "  %-14s http://%s\n"        "Homepage"   "192.168.0.20"
  printf "  %-14s http://%s\n"        "Uptime Kuma" "192.168.0.20:3001"
  printf "  %-14s http://%s\n"        "AdGuard"    "192.168.0.22:3000"
  printf "  %-14s http://%s\n"        "Jellyfin"   "192.168.0.21:8096"
  printf "  %-14s http://%s\n"        "Overseerr"  "192.168.0.21:5055"
  printf "  %-14s http://%s\n"        "Nextcloud"  "192.168.0.23:8081"
  printf "  %-14s http://%s\n"        "BookStack"  "192.168.0.24:6875"
  printf "  %-14s http://%s\n"        "Memos"      "192.168.0.24:5230"
  printf "  %-14s http://%s\n"        "Linkding"   "192.168.0.24:9090"
  echo
  echo -e "${YW}Credenciais: pct exec <CTID> -- cat /root/*-credentials.txt${CL}"
  echo -e "${YW}Atualizar:   pct exec <CTID> -- update${CL}"
  echo -e "${YW}Reload Caddy: pct exec 100 -- docker exec caddy caddy reload --config /etc/caddy/Caddyfile${CL}"
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
    echo "Stacks disponíveis:"
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
    if [[ -n "${CT[$t]:-}" ]]; then
      targets+=("$t")
    else
      warn "Stack desconhecido: '${t}' — ignorando."
    fi
  done

  [[ ${#targets[@]} -eq 0 ]] && die "Nenhum stack válido."

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
