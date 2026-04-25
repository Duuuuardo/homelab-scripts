#!/usr/bin/env bash
# Stack: Caddy + Homepage + Uptime Kuma
source /tmp/homelab-install/_lib.sh

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"

echo -e "\n${BL}=== Infra (Caddy + Homepage + Uptime Kuma) ===${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"

# Para containers antigos conflitantes
msg_info "Limpando containers antigos"
CONFLICTING=$(docker ps -q --filter "publish=80" 2>/dev/null || true)
if [[ -n "$CONFLICTING" ]]; then
  docker stop $CONFLICTING >/dev/null 2>&1 || true
  docker rm   $CONFLICTING >/dev/null 2>&1 || true
fi
stop_old_containers "nginx-proxy-manager" "npm" "app" "nginxproxymanager" \
                    "caddy" "homepage" "uptime-kuma"
msg_ok "Containers antigos removidos"

# ── Caddyfile ────────────────────────────────────────────────────────────────
msg_info "Gerando Caddyfile"
mkdir -p /opt/stacks/lxc-infra/caddy

cat > /opt/stacks/lxc-infra/caddy/Caddyfile << 'CADDYFILE'
{
    auto_https off
    admin off
}

# Homepage na raiz porta 80
# Caddy e Homepage estao na mesma rede Docker (homelab-net)
# entao resolve pelo nome do container
:80 {
    reverse_proxy homepage:3000
}

# Uptime Kuma -- mesmo container, mesma rede
:3001 {
    reverse_proxy uptime-kuma:3001
}

# Servicos nos outros LXCs -- acesso por IP direto
:8096 { reverse_proxy 192.168.0.21:8096 }
:5055 { reverse_proxy 192.168.0.21:5055 }
:8989 { reverse_proxy 192.168.0.21:8989 }
:7878 { reverse_proxy 192.168.0.21:7878 }
:9696 { reverse_proxy 192.168.0.21:9696 }
:8080 { reverse_proxy 192.168.0.21:8080 }
:8081 { reverse_proxy 192.168.0.23:8081 }
:6875 { reverse_proxy 192.168.0.24:6875 }
:5230 { reverse_proxy 192.168.0.24:5230 }
:9090 { reverse_proxy 192.168.0.24:9090 }
:3000 { reverse_proxy 192.168.0.22:3000 }
CADDYFILE
msg_ok "Caddyfile gerado"

# ── Homepage config ──────────────────────────────────────────────────────────
msg_info "Gerando config da Homepage"
mkdir -p /opt/stacks/lxc-infra/homepage/config

cat > /opt/stacks/lxc-infra/homepage/config/settings.yaml << 'SETTINGS'
title: Homelab
favicon: https://cdn.jsdelivr.net/gh/selfhst/icons/svg/proxmox.svg
theme: dark
color: stone
headerStyle: clean
statusStyle: dot
language: pt
useEqualHeights: true
layout:
  Media:
    style: row
    columns: 3
  Infra:
    style: row
    columns: 4
  Cloud & Knowledge:
    style: row
    columns: 4
  DNS & Network:
    style: row
    columns: 2
SETTINGS

cat > /opt/stacks/lxc-infra/homepage/config/bookmarks.yaml << 'BOOKMARKS'
- Quick:
  - Proxmox:
    - abbr: PVE
      icon: proxmox.svg
      href: https://192.168.0.1:8006
  - GitHub:
    - abbr: GH
      icon: github.svg
      href: https://github.com/Duuuuardo
  - Tailscale:
    - abbr: TS
      icon: tailscale.svg
      href: https://login.tailscale.com/admin/machines
BOOKMARKS

cat > /opt/stacks/lxc-infra/homepage/config/services.yaml << 'SERVICES'
- Media:
  - Jellyfin:
      icon: jellyfin.svg
      href: http://192.168.0.21:8096
      description: Servidor de midia
      widget:
        type: jellyfin
        url: http://192.168.0.21:8096
        key: ""
        enableBlocks: true
        enableNowPlaying: true
  - Overseerr:
      icon: overseerr.svg
      href: http://192.168.0.21:5055
      description: Requests
      widget:
        type: overseerr
        url: http://192.168.0.21:5055
        key: ""
  - Sonarr:
      icon: sonarr.svg
      href: http://192.168.0.21:8989
      description: Series
      widget:
        type: sonarr
        url: http://192.168.0.21:8989
        key: ""
  - Radarr:
      icon: radarr.svg
      href: http://192.168.0.21:7878
      description: Filmes
      widget:
        type: radarr
        url: http://192.168.0.21:7878
        key: ""
  - Prowlarr:
      icon: prowlarr.svg
      href: http://192.168.0.21:9696
      description: Indexers
  - qBittorrent:
      icon: qbittorrent.svg
      href: http://192.168.0.21:8080
      description: Torrents
      widget:
        type: qbittorrent
        url: http://192.168.0.21:8080
        username: admin
        password: adminadmin

- Infra:
  - Uptime Kuma:
      icon: uptime-kuma.svg
      href: http://192.168.0.20:3001
      description: Monitoramento
      widget:
        type: uptimekuma
        url: http://uptime-kuma:3001
        slug: homelab
  - Proxmox:
      icon: proxmox.svg
      href: https://192.168.0.1:8006
      description: Hypervisor
      widget:
        type: proxmox
        url: https://192.168.0.1:8006
        username: root@pam
        password: ""
        node: pve

- Cloud & Knowledge:
  - Nextcloud:
      icon: nextcloud.svg
      href: http://192.168.0.23:8081
      description: Cloud pessoal
  - BookStack:
      icon: bookstack.svg
      href: http://192.168.0.24:6875
      description: Wiki
  - Memos:
      icon: memos.svg
      href: http://192.168.0.24:5230
      description: Notas
  - Linkding:
      icon: linkding.svg
      href: http://192.168.0.24:9090
      description: Bookmarks

- DNS & Network:
  - AdGuard Home:
      icon: adguard-home.svg
      href: http://192.168.0.22:3000
      description: DNS + bloqueio de ads
      widget:
        type: adguard
        url: http://192.168.0.22:3000
        username: admin
        password: ""
  - Tailscale:
      icon: tailscale.svg
      href: https://login.tailscale.com/admin/machines
      description: VPN
SERVICES

cat > /opt/stacks/lxc-infra/homepage/config/widgets.yaml << 'WIDGETS'
- resources:
    label: infra (CT 100)
    cpu: true
    memory: true
    disk: /
    uptime: true
    units: metric
    refresh: 5000

- datetime:
    text_size: xl
    format:
      timeStyle: short
      dateStyle: short
      hour12: false

- search:
    provider: duckduckgo
    target: _blank
    focus: false
WIDGETS

cat > /opt/stacks/lxc-infra/homepage/config/docker.yaml << 'DOCKERYAML'
my-docker:
  socket: /var/run/docker.sock
DOCKERYAML
msg_ok "Config da Homepage gerada"

# ── docker-compose.yml ───────────────────────────────────────────────────────
# CORRECAO: Caddy e Homepage na mesma rede Docker (homelab-net)
# Sem network_mode: host no Caddy -- assim ele resolve "homepage:3000"
# O Caddy expoe as portas diretamente no host via ports:
msg_info "Escrevendo docker-compose.yml"
cat > /opt/stacks/lxc-infra/docker-compose.yml << 'COMPOSE'
networks:
  homelab-net:
    driver: bridge

services:

  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    networks:
      - homelab-net
    ports:
      - "80:80"
      - "443:443"
      - "3001:3001"
      - "5055:5055"
      - "6875:6875"
      - "7878:7878"
      - "8080:8080"
      - "8081:8081"
      - "8096:8096"
      - "8989:8989"
      - "9090:9090"
      - "9696:9696"
      - "5230:5230"
      - "3000:3000"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    networks:
      - homelab-net
    expose:
      - "3000"
    volumes:
      - ./homepage/config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      HOMEPAGE_ALLOWED_HOSTS: "*"

  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    networks:
      - homelab-net
    expose:
      - "3001"
    volumes:
      - uptime_kuma_data:/app/data

volumes:
  caddy_data:
  caddy_config:
  uptime_kuma_data:
COMPOSE
msg_ok "docker-compose.yml criado"

# ── Sobe containers ──────────────────────────────────────────────────────────
msg_info "Baixando imagens"
cd /opt/stacks/lxc-infra
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

# ── Update helper ────────────────────────────────────────────────────────────
cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-infra
docker compose pull
docker compose up -d
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
echo "Done."
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Infra instalado!${CL}"
echo "  Homepage:    http://${IP}"
echo "  Uptime Kuma: http://${IP}:3001"
echo "  AdGuard:     http://${IP}:3000  (proxy pro CT dns)"
echo ""
echo "  Editar servicos: /opt/stacks/lxc-infra/homepage/config/services.yaml"
echo "  Reload Caddy:    docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
