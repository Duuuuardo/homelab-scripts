#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Homelab Deploy — Eduardo (Duuuuardo)
# Proxmox host only. Chama cada ct/XXX.sh no estilo community-scripts.
#
# Usage:
#   bash deploy-homelab.sh              # menu interativo
#   bash deploy-homelab.sh all          # todos os stacks
#   bash deploy-homelab.sh infra dns    # stacks específicos
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ordem recomendada de deploy
ALL_STACKS=(infra dns media cloud knowledge games utilities)

# IPs fixos por stack — ajuste se sua rede for diferente
declare -A CT_IP=(
  [infra]=192.168.0.20
  [dns]=192.168.0.22
  [media]=192.168.0.21
  [cloud]=192.168.0.23
  [knowledge]=192.168.0.24
  [games]=192.168.0.25
  [utilities]=192.168.0.27
)

declare -A CT_ID=(
  [infra]=100
  [dns]=102
  [media]=101
  [cloud]=103
  [knowledge]=104
  [games]=105
  [utilities]=107
)

# ── Cores ────────────────────────────────────────────────────────────────────
RD='\033[01;31m'
GN='\033[1;92m'
YW='\033[33m'
BL='\033[36m'
CL='\033[m'
BOLD='\033[1m'

msg()  { echo -e "${GN}✔${CL} $*"; }
info() { echo -e "${BL}➜${CL} $*"; }
warn() { echo -e "${YW}⚠${CL}  $*"; }
die()  { echo -e "${RD}✘${CL}  $*" >&2; exit 1; }

header() {
  clear
  cat <<'EOF'

  _    _                      _       _     
 | |  | |                    | |     | |    
 | |__| | ___  _ __ ___   ___| | __ _| |__  
 |  __  |/ _ \| '_ ` _ \ / _ \ |/ _` | '_ \ 
 | |  | | (_) | | | | | |  __/ | (_| | |_) |
 |_|  |_|\___/|_| |_| |_|\___|_|\__,_|_.__/ 

EOF
  echo -e "  ${BOLD}Homelab Deploy — Eduardo (Duuuuardo)${CL}"
  echo -e "  Proxmox host: $(hostname) | $(date '+%Y-%m-%d %H:%M')\n"
}

# ── Pré-checks ───────────────────────────────────────────────────────────────
require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Execute como root no host Proxmox."
}

check_proxmox() {
  command -v pct   >/dev/null 2>&1 || die "pct não encontrado. Execute no host Proxmox."
  command -v pveam >/dev/null 2>&1 || die "pveam não encontrado. Execute no host Proxmox."
}

# ── Deploy de um stack ────────────────────────────────────────────────────────
deploy_stack() {
  local stack="$1"
  local ct_script="${SCRIPT_DIR}/ct/${stack}.sh"

  if [[ ! -f "$ct_script" ]]; then
    warn "ct/${stack}.sh não encontrado — pulando"
    return
  fi

  local ctid="${CT_ID[$stack]:-}"
  local ip="${CT_IP[$stack]:-}"

  echo
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  info "Stack: ${BOLD}${stack}${CL}  CT ${ctid} @ ${ip}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"

  # Passa IP/CTID fixos para o build.func usar quando possível
  # (build.func respeita CT_IP_ADDRESS e CTID se definidos)
  CTID="$ctid" \
  CT_IP_ADDRESS="$ip" \
    bash "$ct_script"
}

# ── Resumo final ──────────────────────────────────────────────────────────────
print_summary() {
  echo
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${GN}  Deploy finalizado!${CL}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo
  echo -e "  ${BOLD}URLs principais:${CL}"
  echo "    NPM:        http://192.168.0.20:81"
  echo "    Homepage:   http://192.168.0.20:3000"
  echo "    Uptime:     http://192.168.0.20:3001"
  echo "    AdGuard:    http://192.168.0.22:3000"
  echo "    Jellyfin:   http://192.168.0.21:8096"
  echo "    Seerr:      http://192.168.0.21:5055"
  echo "    Nextcloud:  http://192.168.0.23:8081"
  echo "    BookStack:  http://192.168.0.24:6875"
  echo "    Memos:      http://192.168.0.24:5230"
  echo "    Linkding:   http://192.168.0.24:9090"
  echo "    Whoogle:    http://192.168.0.27:5000"
  echo "    Actual:     http://192.168.0.27:5006"
  echo "    Neko:       http://192.168.0.27:8080"
  echo "    Pelican:    http://192.168.0.25:8084"
  echo
  echo -e "  ${YW}Credenciais geradas ficam dentro de cada LXC:${CL}"
  echo "    pct exec 103 -- cat /root/cloud-credentials.txt"
  echo "    pct exec 104 -- cat /root/knowledge-credentials.txt"
  echo "    pct exec 107 -- cat /root/utilities-credentials.txt"
  echo
  echo -e "  ${YW}Atualizar um stack:${CL}"
  echo "    pct exec <CTID> -- update"
  echo
  echo -e "  ${YW}Próximos passos manuais:${CL}"
  echo "    1. AdGuard DNS rewrites  → docs/adguard.md"
  echo "    2. NPM proxy hosts       → docs/nginx-proxy-manager.md"
  echo "    3. Media setup (Arr)     → docs/media-setup.md"
  echo "    4. Tailscale             → docs/tailscale-proxmox.md"
  echo "    5. CT 106 deploy (Dokploy) → docs/dokploy.md"
  echo
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  require_root
  check_proxmox
  header

  local targets=()

  if [[ $# -eq 0 ]]; then
    echo -e "  ${BOLD}Stacks disponíveis:${CL}"
    for s in "${ALL_STACKS[@]}"; do
      echo "    ${s}  (CT ${CT_ID[$s]:-?} @ ${CT_IP[$s]:-?})"
    done
    echo
    read -r -p "  Quais stacks deployar? (ex: infra dns | all): " input
    IFS=' ' read -r -a targets <<< "$input"
  else
    targets=("$@")
  fi

  if [[ "${targets[*]:-}" == "all" ]]; then
    targets=("${ALL_STACKS[@]}")
  fi

  for stack in "${targets[@]}"; do
    if [[ ! " ${ALL_STACKS[*]} " =~ " ${stack} " ]]; then
      warn "Stack desconhecido: '${stack}' — ignorando"
      continue
    fi
    deploy_stack "$stack"
  done

  print_summary
}

main "$@"
