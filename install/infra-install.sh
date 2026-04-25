#!/usr/bin/env bash
# Stack: Nginx Proxy Manager + Homepage + Uptime Kuma
source /tmp/homelab-install/_lib.sh

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"

echo -e "\n${BL}=== Infra (Nginx Proxy Manager + Homepage + Uptime Kuma) ===${CL}\n"

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

# ── NPM data ────────────────────────────────────────────────────────────────
msg_info "Preparando dados do Nginx Proxy Manager"
mkdir -p /opt/stacks/lxc-infra/npm/data
mkdir -p /opt/stacks/lxc-infra/npm/letsencrypt
msg_ok "Pastas do Nginx Proxy Manager criadas"

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
# NPM escuta 80/81/443.
# Homepage e Uptime Kuma tem portas diretas como fallback caso o DNS .lab
# ainda nao esteja configurado (acesso por IP:porta funciona sem DNS).
msg_info "Escrevendo docker-compose.yml"
cat > /opt/stacks/lxc-infra/docker-compose.yml << 'COMPOSE'
networks:
  homelab-net:
    driver: bridge

services:

  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    networks:
      - homelab-net
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - ./npm/data:/data
      - ./npm/letsencrypt:/etc/letsencrypt

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
# Atualiza imagens e reaplica stack
cd /opt/stacks/lxc-infra
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null && \
  cp -r /opt/homelab-scripts/lxc-infra/data/homepage/. ./homepage/config/ && \
  echo "Config da homepage atualizada do repo" || true
docker compose pull
docker compose up -d
echo "Done."
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Infra instalado!${CL}"
echo "  NPM:         http://${IP}:81"
echo "  Homepage:    http://${IP}:3000"
echo "  Uptime Kuma: http://${IP}:3001"
echo ""
echo "  Os dominios .lab so funcionam apos configurar o DNS:"
echo "  → Deploy o CT dns (AdGuard) e aponte seu DNS para 192.168.0.22"
echo "  → No Tailscale: Settings > DNS > Add nameserver > 192.168.0.22 (split DNS: lab)"
echo "  → Configure os hosts no NPM conforme docs/nginx-proxy-manager.md"
echo ""
echo "  NPM login:         admin@example.com / changeme"
echo "  Editar homepage:   /opt/stacks/lxc-infra/homepage/config/"
echo "  Compose file:      /opt/stacks/lxc-infra/docker-compose.yml"
