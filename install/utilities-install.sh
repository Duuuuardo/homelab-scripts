#!/usr/bin/env bash
# Stack: Neko + utils
source "$(dirname "$0")/_lib.sh"

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-utilities"

echo -e "\n${BL}══ Utilities (Neko + utils) ══${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"

msg_info "Preparando stack Utilities"
mkdir -p "/opt/stacks/${STACK}"
cp -r "/opt/homelab-scripts/${STACK}/." "/opt/stacks/${STACK}/"
cd "/opt/stacks/${STACK}"
[[ ! -f .env && -f .env.example ]] && cp .env.example .env

NEKO_PW="$(rnd_pw)"
NEKO_ADMIN_PW="$(rnd_pw)"

sed -i "s|^NEKO_PASSWORD=.*|NEKO_PASSWORD=${NEKO_PW}|" .env
sed -i "s|^NEKO_ADMIN_PASSWORD=.*|NEKO_ADMIN_PASSWORD=${NEKO_ADMIN_PW}|" .env
msg_ok "Senhas geradas"

msg_info "Baixando imagens Docker"
docker compose pull >/dev/null 2>&1
msg_ok "Imagens baixadas"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1
msg_ok "Containers iniciados"

make_update_helper "/opt/stacks/${STACK}"

cat > /root/utilities-credentials.txt << EOF
Utilities Stack Credentials
Gerado: $(date -Is)

Neko user password:  ${NEKO_PW}
Neko admin password: ${NEKO_ADMIN_PW}
EOF
chmod 600 /root/utilities-credentials.txt

echo -e "\n${CM} ${GN}Utilities instalado!${CL}"
echo "  Neko: http://$(hostname -I | awk '{print $1}'):8080"
echo "  Credenciais salvas em: /root/utilities-credentials.txt"
