#!/usr/bin/env bash
# Stack: Jellyfin + Sonarr + Radarr + Prowlarr + qBittorrent + Overseerr
source "$(dirname "$0")/_lib.sh"

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-media"

echo -e "\n${BL}══ Media (Jellyfin + Arr stack) ══${CL}\n"

base_setup

# VA-API para HW transcoding do Jellyfin
if [[ -d /dev/dri ]]; then
  msg_info "Instalando drivers VA-API (GPU detectada)"
  apt-get install -y vainfo intel-media-va-driver-non-free 2>/dev/null \
    || apt-get install -y vainfo intel-media-va-driver 2>/dev/null || true
  msg_ok "Drivers VA-API instalados"
else
  msg_warn "Sem /dev/dri — configure GPU passthrough no Proxmox se quiser HW transcoding"
fi

msg_info "Criando diretórios de mídia"
mkdir -p /data/{downloads,torrents,movies,tv,music}
chown -R 1000:1000 /data
msg_ok "Diretórios criados em /data"

install_docker
clone_repo "$REPO_URL"
deploy_stack "$STACK"
make_update_helper "/opt/stacks/${STACK}"

echo -e "\n${CM} ${GN}Media instalado!${CL}"
IP="$(hostname -I | awk '{print $1}')"
echo "  Jellyfin:    http://${IP}:8096"
echo "  Overseerr:   http://${IP}:5055"
echo "  qBittorrent: http://${IP}:8080"
echo "  Sonarr:      http://${IP}:8989"
echo "  Radarr:      http://${IP}:7878"
echo "  Prowlarr:    http://${IP}:9696"
