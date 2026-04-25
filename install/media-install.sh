#!/usr/bin/env bash
# Stack: Jellyfin + Sonarr + Radarr + Prowlarr + qBittorrent + Seerr
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== Media (Jellyfin + Arr stack) ===${CL}\n"

base_setup

# VA-API
if [[ -d /dev/dri ]]; then
  msg_info "Instalando drivers VA-API"
  apt-get install -y -qq vainfo intel-media-va-driver-non-free 2>/dev/null \
    || apt-get install -y -qq vainfo intel-media-va-driver 2>/dev/null || true
  msg_ok "VA-API instalado"
else
  msg_warn "Sem /dev/dri — GPU passthrough nao configurado"
fi

msg_info "Criando diretorios de midia"
mkdir -p /data/{downloads,torrents,movies,tv,music}
chown -R 1000:1000 /data
msg_ok "Diretorios criados em /data"

install_docker

STACK_DIR="/opt/stacks/lxc-media"
mkdir -p "$STACK_DIR"

# PUID/PGID do usuario que roda os containers
PUID=1000
PGID=1000
TZ="America/Sao_Paulo"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << COMPOSE
services:

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    network_mode: host
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - jellyfin_config:/config
      - jellyfin_cache:/cache
      - /data/movies:/data/movies:ro
      - /data/tv:/data/tv:ro
    devices:
      - /dev/dri:/dev/dri

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - sonarr_config:/config
      - /data:/data
    ports:
      - "8989:8989"

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - radarr_config:/config
      - /data:/data
    ports:
      - "7878:7878"

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - prowlarr_config:/config
    ports:
      - "9696:9696"

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=8080
    volumes:
      - qbittorrent_config:/config
      - /data/downloads:/data/downloads
      - /data/torrents:/data/torrents
    ports:
      - "8080:8080"
      - "6881:6881"
      - "6881:6881/udp"

  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    container_name: seerr
    init: true
    restart: unless-stopped
    environment:
      - LOG_LEVEL=debug
      - TZ=${TZ}
      - PORT=5055
    volumes:
      - seerr_config:/app/config
    ports:
      - "5055:5055"
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1
      start_period: 20s
      timeout: 3s
      interval: 15s
      retries: 3

volumes:
  jellyfin_config:
  jellyfin_cache:
  sonarr_config:
  radarr_config:
  prowlarr_config:
  qbittorrent_config:
  seerr_config:
COMPOSE
msg_ok "docker-compose.yml criado"

msg_info "Baixando imagens"
cd "$STACK_DIR"
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-media
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Media instalado!${CL}"
echo "  Jellyfin:    http://${IP}:8096"
echo "  Seerr:       http://${IP}:5055"
echo "  qBittorrent: http://${IP}:8080  (user: admin / pass: adminadmin)"
echo "  Sonarr:      http://${IP}:8989"
echo "  Radarr:      http://${IP}:7878"
echo "  Prowlarr:    http://${IP}:9696"
