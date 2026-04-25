#!/usr/bin/env bash
# Stack: Nextcloud + MariaDB
source "$(dirname "$0")/_lib.sh"

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-cloud"

echo -e "\n${BL}══ Cloud (Nextcloud) ══${CL}\n"

base_setup

msg_info "Criando diretório de dados"
mkdir -p /data/cloud
chown -R 33:33 /data/cloud
msg_ok "Diretório /data/cloud criado"

install_docker
clone_repo "$REPO_URL"

# Copia stack e gera senhas antes de subir
msg_info "Preparando stack Nextcloud"
mkdir -p "/opt/stacks/${STACK}"
cp -r "/opt/homelab-scripts/${STACK}/." "/opt/stacks/${STACK}/"
cd "/opt/stacks/${STACK}"
[[ ! -f .env && -f .env.example ]] && cp .env.example .env

DB_ROOT_PW="$(rnd_pw)"
DB_PW="$(rnd_pw)"
ADMIN_PW="$(rnd_pw)"

sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=${DB_ROOT_PW}|" .env
sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=${DB_PW}|" .env
sed -i "s|^NEXTCLOUD_ADMIN_PASSWORD=.*|NEXTCLOUD_ADMIN_PASSWORD=${ADMIN_PW}|" .env
msg_ok "Senhas geradas"

msg_info "Baixando imagens Docker"
docker compose pull >/dev/null 2>&1
msg_ok "Imagens baixadas"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1
msg_ok "Containers iniciados"

make_update_helper "/opt/stacks/${STACK}"

cat > /root/nextcloud-credentials.txt << EOF
Nextcloud Credentials
Gerado: $(date -Is)

Admin user:       admin
Admin password:   ${ADMIN_PW}

DB root password: ${DB_ROOT_PW}
DB password:      ${DB_PW}
EOF
chmod 600 /root/nextcloud-credentials.txt

echo -e "\n${CM} ${GN}Cloud instalado!${CL}"
echo "  Nextcloud: http://$(hostname -I | awk '{print $1}'):8081"
echo "  Credenciais salvas em: /root/nextcloud-credentials.txt"
