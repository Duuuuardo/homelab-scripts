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
# Roteamento por hostname (dominios .lab resolvidos pelo AdGuard no CT dns)
# HTTPS local com CA interna do Caddy para a rede .lab
msg_info "Gerando Caddyfile"
mkdir -p /opt/stacks/lxc-infra/caddy

cat > /opt/stacks/lxc-infra/caddy/Caddyfile << 'CADDYFILE'
{
    admin off
    local_certs
}

# Homepage -- acessivel por IP direto ou pelo dominio
192.168.0.20, home.lab {
    reverse_proxy homepage:3000
}

# Infra
status.lab    { reverse_proxy uptime-kuma:3001 }
dns.lab       { reverse_proxy 192.168.0.22:3000 }

# Media
jellyfin.lab  { reverse_proxy 192.168.0.21:8096 }
requests.lab  { reverse_proxy 192.168.0.21:5055 }
sonarr.lab    { reverse_proxy 192.168.0.21:8989 }
radarr.lab    { reverse_proxy 192.168.0.21:7878 }
prowlarr.lab  { reverse_proxy 192.168.0.21:9696 }
qbitt.lab     { reverse_proxy 192.168.0.21:8080 }

# Cloud
cloud.lab     { reverse_proxy 192.168.0.23:8081 }

# Knowledge
bookstack.lab { reverse_proxy 192.168.0.24:6875 }
memos.lab     { reverse_proxy 192.168.0.24:5230 }
links.lab     { reverse_proxy 192.168.0.24:9090 }

# Utilities
search.lab    { reverse_proxy 192.168.0.27:5000 }
budget.lab    { reverse_proxy 192.168.0.27:5006 }
neko.lab      { reverse_proxy 192.168.0.27:8080 }
CADDYFILE
msg_ok "Caddyfile gerado"

# ── Homepage config (do repo) ─────────────────────────────────────────────────
msg_info "Configurando Homepage"
mkdir -p /opt/stacks/lxc-infra/homepage/config
if [[ -d /opt/homelab-scripts/lxc-infra/data/homepage ]]; then
  cp -r /opt/homelab-scripts/lxc-infra/data/homepage/. \
        /opt/stacks/lxc-infra/homepage/config/
  msg_ok "Config da Homepage copiada do repo"
else
  msg_warn "Pasta data/homepage nao encontrada no repo — homepage sem config pre-definida"
fi

# ── docker-compose.yml ───────────────────────────────────────────────────────
# Caddy escuta 80/443 e emite certificados locais via CA interna.
# Homepage e Uptime Kuma tem portas diretas como fallback caso o DNS .lab
# ainda nao esteja configurado (acesso por IP:porta funciona sem DNS).
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
    networks:
      - homelab-net
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

# ── Sobe containers ──────────────────────────────────────────────────────────
msg_info "Baixando imagens"
cd /opt/stacks/lxc-infra
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

# ── Update helper ────────────────────────────────────────────────────────────
cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
set -euo pipefail
# Atualiza imagens e recarrega Caddyfile
cd /opt/stacks/lxc-infra
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null && \
  cp -r /opt/homelab-scripts/lxc-infra/data/homepage/. ./homepage/config/ && \
  echo "Config da homepage atualizada do repo" || true
docker compose pull
docker compose up -d
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
echo "Done."
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Infra instalado!${CL}"
echo "  Homepage:    https://${IP}  ou  https://home.lab"
echo "  Uptime Kuma: http://${IP}:3001  ou  https://status.lab"
echo ""
echo "  Os dominios .lab so funcionam apos configurar o DNS:"
echo "  → Deploy o CT dns (AdGuard) e aponte seu DNS para 192.168.0.22"
echo "  → No Tailscale: Settings > DNS > Add nameserver > 192.168.0.22 (split DNS: lab)"
echo "  → Para evitar aviso de certificado, confie a CA local do Caddy nos seus dispositivos"
echo ""
echo "  Editar Caddyfile:  /opt/stacks/lxc-infra/caddy/Caddyfile"
echo "  Editar homepage:   /opt/stacks/lxc-infra/homepage/config/"
echo "  Reload Caddy:      docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
