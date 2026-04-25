#!/usr/bin/env bash
# Stack: AdGuard Home
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== DNS (AdGuard Home) ===${CL}\n"

base_setup
install_docker

STACK_DIR="/opt/stacks/lxc-dns"
mkdir -p "$STACK_DIR"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << 'COMPOSE'
services:

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    network_mode: host
    volumes:
      - adguard_work:/opt/adguardhome/work
      - adguard_conf:/opt/adguardhome/conf

volumes:
  adguard_work:
  adguard_conf:
COMPOSE
msg_ok "docker-compose.yml criado"

msg_info "Baixando imagem"
cd "$STACK_DIR"
docker compose pull >/dev/null 2>&1 && msg_ok "Imagem baixada" || msg_warn "Pull teve avisos"

msg_info "Iniciando container"
docker compose up -d >/dev/null 2>&1 && msg_ok "Container iniciado" || msg_warn "Verifique: docker compose logs"

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-dns
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}DNS instalado!${CL}"
echo "  AdGuard Home (setup): http://${IP}:3000"
echo "  AdGuard Home (admin): http://${IP}:80   (apos setup inicial)"
echo "  DNS:                  ${IP}:53"
echo ""
echo "  Configure os LXCs pra usar ${IP} como DNS depois do setup."
