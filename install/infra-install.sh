#!/usr/bin/env bash
# Stack: Caddy + Homepage + Uptime Kuma
source /tmp/homelab-install/_lib.sh

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"

echo -e "\n${BL}=== Infra (Caddy + Homepage + Uptime Kuma) ===${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"

# Remove containers antigos na porta 80 (NPM, etc)
msg_info "Verificando conflitos na porta 80"
CONFLICTING=$(docker ps -q --filter "publish=80" 2>/dev/null || true)
if [[ -n "$CONFLICTING" ]]; then
  docker stop $CONFLICTING >/dev/null 2>&1 || true
  docker rm   $CONFLICTING >/dev/null 2>&1 || true
fi
stop_old_containers "nginx-proxy-manager" "npm" "app" "nginxproxymanager"
msg_ok "Porta 80 liberada"

# Gera Caddyfile
msg_info "Gerando Caddyfile"
mkdir -p /opt/stacks/lxc-infra/caddy

cat > /opt/stacks/lxc-infra/caddy/Caddyfile << 'CADDYFILE'
{
    auto_https off
    admin off
}

# Homepage -- raiz porta 80
:80 {
    reverse_proxy homepage:3000
}

# Uptime Kuma
:3001 {
    reverse_proxy uptime-kuma:3001
}

# Jellyfin
:8096 {
    reverse_proxy 192.168.0.21:8096
}

# Overseerr
:5055 {
    reverse_proxy 192.168.0.21:5055
}

# Sonarr
:8989 {
    reverse_proxy 192.168.0.21:8989
}

# Radarr
:7878 {
    reverse_proxy 192.168.0.21:7878
}

# Prowlarr
:9696 {
    reverse_proxy 192.168.0.21:9696
}

# qBittorrent
:8080 {
    reverse_proxy 192.168.0.21:8080
}

# Nextcloud
:8081 {
    reverse_proxy 192.168.0.23:8081
}

# BookStack
:6875 {
    reverse_proxy 192.168.0.24:6875
}

# Memos
:5230 {
    reverse_proxy 192.168.0.24:5230
}

# Linkding
:9090 {
    reverse_proxy 192.168.0.24:9090
}

# AdGuard Home
:3000 {
    reverse_proxy 192.168.0.22:3000
}
CADDYFILE
msg_ok "Caddyfile gerado"

# Gera config da Homepage
msg_info "Gerando config da Homepage"
mkdir -p /opt/stacks/lxc-infra/homepage/config

cat > /opt/stacks/lxc-infra/homepage/config/settings.yaml << 'SETTINGS'
title: Homelab
favicon: https://cdn.jsdelivr.net/gh/selfhst/icons/svg/proxmox.svg
theme: dark
color: slate
headerStyle: clean
statusStyle: dot
language: pt
layout:
  Infra:
    style: row
    columns: 4
  Media:
    style: row
    columns: 4
  Cloud & Knowledge:
    style: row
    columns: 4
  DNS & Network:
    style: row
    columns: 4
SETTINGS

cat > /opt/stacks/lxc-infra/homepage/config/bookmarks.yaml << 'BOOKMARKS'
- Dev:
  - GitHub:
    - abbr: GH
      href: https://github.com/Duuuuardo
  - Proxmox:
    - abbr: PVE
      href: https://192.168.0.1:8006
BOOKMARKS

cat > /opt/stacks/lxc-infra/homepage/config/services.yaml << 'SERVICES'
- Infra:
  - Uptime Kuma:
      icon: uptime-kuma.svg
      href: http://192.168.0.20:3001
      description: Monitoramento de servicos
      widget:
        type: uptimekuma
        url: http://uptime-kuma:3001
        slug: homelab

- Media:
  - Jellyfin:
      icon: jellyfin.svg
      href: http://192.168.0.21:8096
      description: Servidor de midia
      widget:
        type: jellyfin
        url: http://192.168.0.21:8096
        key: ""
  - Overseerr:
      icon: overseerr.svg
      href: http://192.168.0.21:5055
      description: Requests de filmes e series
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

- Cloud & Knowledge:
  - Nextcloud:
      icon: nextcloud.svg
      href: http://192.168.0.23:8081
      description: Cloud pessoal
  - BookStack:
      icon: bookstack.svg
      href: http://192.168.0.24:6875
      description: Wiki e documentacao
  - Memos:
      icon: memos.svg
      href: http://192.168.0.24:5230
      description: Notas rapidas
  - Linkding:
      icon: linkding.svg
      href: http://192.168.0.24:9090
      description: Bookmarks

- DNS & Network:
  - AdGuard Home:
      icon: adguard-home.svg
      href: http://192.168.0.22:3000
      description: DNS e bloqueio de ads
      widget:
        type: adguard
        url: http://192.168.0.22:3000
        username: admin
        password: ""
SERVICES

cat > /opt/stacks/lxc-infra/homepage/config/widgets.yaml << 'WIDGETS'
- resources:
    label: Sistema
    cpu: true
    memory: true
    disk: /
    cputemp: true
    uptime: true
    units: metric
    refresh: 5000

- datetime:
    text_size: l
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

# docker-compose.yml
msg_info "Escrevendo docker-compose.yml"
cat > /opt/stacks/lxc-infra/docker-compose.yml << 'COMPOSE'
services:

  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./homepage/config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      HOMEPAGE_ALLOWED_HOSTS: "*"

  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - uptime_kuma_data:/app/data

volumes:
  caddy_data:
  caddy_config:
  uptime_kuma_data:
COMPOSE
msg_ok "docker-compose.yml criado"

# Sobe os containers
msg_info "Baixando imagens"
cd /opt/stacks/lxc-infra
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

# Update helper
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
echo ""
echo "  Para editar servicos: /opt/stacks/lxc-infra/homepage/config/services.yaml"
echo "  Para recarregar Caddy: docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
