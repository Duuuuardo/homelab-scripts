#!/usr/bin/env bash
# Stack: Nextcloud + MariaDB + Redis
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== Cloud (Nextcloud) ===${CL}\n"

base_setup
install_docker

STACK_DIR="/opt/stacks/lxc-cloud"
mkdir -p "$STACK_DIR"
mkdir -p /data/cloud
chown -R 33:33 /data/cloud

# Gera senhas
DB_ROOT_PW="$(rnd_pw)"
DB_PW="$(rnd_pw)"
DB_USER="nextcloud"
DB_NAME="nextcloud"
ADMIN_USER="admin"
ADMIN_PW="$(rnd_pw)"
NC_DOMAIN="192.168.0.23"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << COMPOSE
services:

  db:
    image: mariadb:11
    container_name: nextcloud-db
    restart: unless-stopped
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PW}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PW}
    volumes:
      - nextcloud_db:/var/lib/mysql

  redis:
    image: redis:alpine
    container_name: nextcloud-redis
    restart: unless-stopped
    volumes:
      - nextcloud_redis:/data

  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    restart: unless-stopped
    depends_on:
      - db
      - redis
    ports:
      - "8081:80"
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PW}
      REDIS_HOST: redis
      NEXTCLOUD_ADMIN_USER: ${ADMIN_USER}
      NEXTCLOUD_ADMIN_PASSWORD: ${ADMIN_PW}
      NEXTCLOUD_TRUSTED_DOMAINS: ${NC_DOMAIN}
      OVERWRITEPROTOCOL: http
    volumes:
      - nextcloud_data:/var/www/html
      - /data/cloud:/var/www/html/data

volumes:
  nextcloud_db:
  nextcloud_redis:
  nextcloud_data:
COMPOSE
msg_ok "docker-compose.yml criado"

msg_info "Baixando imagens"
cd "$STACK_DIR"
docker compose pull >/dev/null 2>&1 && msg_ok "Imagens baixadas" || msg_warn "Pull teve avisos"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1 && msg_ok "Containers iniciados" || msg_warn "Verifique: docker compose logs"

cat > /root/nextcloud-credentials.txt << EOF
Nextcloud Credentials
Gerado: $(date -Is)

URL:            http://192.168.0.23:8081
Admin user:     ${ADMIN_USER}
Admin password: ${ADMIN_PW}

DB user:          ${DB_USER}
DB password:      ${DB_PW}
DB root password: ${DB_ROOT_PW}
EOF
chmod 600 /root/nextcloud-credentials.txt

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-cloud
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

IP="$(hostname -I | awk '{print $1}')"
echo -e "\n${CM} ${GN}Cloud instalado!${CL}"
echo "  Nextcloud: http://${IP}:8081"
echo "  Admin:     ${ADMIN_USER} / ${ADMIN_PW}"
echo "  Credenciais salvas em: /root/nextcloud-credentials.txt"
