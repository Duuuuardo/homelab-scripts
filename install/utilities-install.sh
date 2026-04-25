#!/usr/bin/env bash
# Stack: Neko (remote browser)
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== Utilities (Neko) ===${CL}\n"

base_setup
install_docker

STACK_DIR="/opt/stacks/lxc-utilities"
mkdir -p "$STACK_DIR"

NEKO_PW="$(rnd_pw)"
NEKO_ADMIN_PW="$(rnd_pw)"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << COMPOSE
services:

  neko:
    image: ghcr.io/m1k1o/neko/firefox:latest
    container_name: neko
    restart: unless-stopped
    shm_size: 2gb
    environment:
      NEKO_SCREEN: 1920x1080@30
      NEKO_PASSWORD: ${NEKO_PW}
      NEKO_PASSWORD_ADMIN: ${NEKO_ADMIN_PW}
      NEKO_EPR: 52000-52100
      NEKO_ICELITE: 1
    ports:
      - "8080:8080"
      - "52000-52100:52000-52100/udp"
    cap_add:
      - SYS_ADMIN
COMPOSE
msg_ok "docker-compose.yml criado"

msg_info "Baixando imagem"
cd "$STACK_DIR"
docker compose pull >/dev/null 2>&1 && msg_ok "Imagem baixada" || msg_warn "Pull teve avisos"

msg_info "Iniciando container"
docker compose up -d >/dev/null 2>&1 && msg_ok "Container iniciado" || msg_warn "Verifique: docker compose logs"

cat > /root/utilities-credentials.txt << EOF
Utilities Stack Credentials
Gerado: $(date -Is)

Neko URL:            http://192.168.0.27:8080
Neko user password:  ${NEKO_PW}
Neko admin password: ${NEKO_ADMIN_PW}
EOF
chmod 600 /root/utilities-credentials.txt

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-utilities
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Utilities instalado!${CL}"
echo "  Neko: http://${IP}:8080"
echo "  Credenciais: /root/utilities-credentials.txt"
