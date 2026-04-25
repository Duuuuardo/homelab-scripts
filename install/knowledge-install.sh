#!/usr/bin/env bash
# Stack: BookStack + Memos + Linkding
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== Knowledge (BookStack + Memos + Linkding) ===${CL}\n"

base_setup
install_docker

STACK_DIR="/opt/stacks/lxc-knowledge"
mkdir -p "$STACK_DIR"

# Senhas
BS_DB_ROOT_PW="$(rnd_pw)"
BS_DB_PW="$(rnd_pw)"
BS_DB_USER="bookstack"
BS_DB_NAME="bookstack"
BS_URL="http://192.168.0.24:6875"
LD_PW="$(rnd_pw)"
LD_USER="admin"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << COMPOSE
services:

  bookstack-db:
    image: mariadb:11
    container_name: bookstack-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${BS_DB_ROOT_PW}
      MYSQL_DATABASE: ${BS_DB_NAME}
      MYSQL_USER: ${BS_DB_USER}
      MYSQL_PASSWORD: ${BS_DB_PW}
    volumes:
      - bookstack_db:/var/lib/mysql

  bookstack:
    image: lscr.io/linuxserver/bookstack:latest
    container_name: bookstack
    restart: unless-stopped
    depends_on:
      - bookstack-db
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Sao_Paulo
      APP_URL: ${BS_URL}
      DB_HOST: bookstack-db
      DB_PORT: 3306
      DB_DATABASE: ${BS_DB_NAME}
      DB_USERNAME: ${BS_DB_USER}
      DB_PASSWORD: ${BS_DB_PW}
    volumes:
      - bookstack_data:/config
    ports:
      - "6875:80"

  memos:
    image: neosmemo/memos:stable
    container_name: memos
    restart: unless-stopped
    volumes:
      - memos_data:/var/opt/memos
    ports:
      - "5230:5230"

  linkding:
    image: sissbruecker/linkding:latest
    container_name: linkding
    restart: unless-stopped
    environment:
      LD_SUPERUSER_NAME: ${LD_USER}
      LD_SUPERUSER_PASSWORD: ${LD_PW}
    volumes:
      - linkding_data:/etc/linkding/data
    ports:
      - "9090:9090"

volumes:
  bookstack_db:
  bookstack_data:
  memos_data:
  linkding_data:
COMPOSE
msg_ok "docker-compose.yml criado"

msg_info "Baixando imagens"
cd "$STACK_DIR"
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

cat > /root/knowledge-credentials.txt << EOF
Knowledge Stack Credentials
Gerado: $(date -Is)

BookStack URL:       ${BS_URL}
BookStack login:     admin@admin.com / password  (trocar no primeiro login)
BookStack DB root:   ${BS_DB_ROOT_PW}
BookStack DB pw:     ${BS_DB_PW}

Linkding URL:        http://192.168.0.24:9090
Linkding user:       ${LD_USER}
Linkding password:   ${LD_PW}

Memos URL:           http://192.168.0.24:5230
Memos login:         configurar no primeiro acesso
EOF
chmod 600 /root/knowledge-credentials.txt

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-knowledge
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Knowledge instalado!${CL}"
echo "  BookStack: http://${IP}:6875  (admin@admin.com / password)"
echo "  Memos:     http://${IP}:5230"
echo "  Linkding:  http://${IP}:9090  (${LD_USER} / ${LD_PW})"
echo "  Credenciais: /root/knowledge-credentials.txt"
