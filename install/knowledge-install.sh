#!/usr/bin/env bash
# Stack: BookStack + Memos + Linkding
source /tmp/homelab-install/_lib.sh

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-knowledge"

echo -e "\n${BL}══ Knowledge (BookStack + Memos + Linkding) ══${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"

msg_info "Preparando stack Knowledge"
mkdir -p "/opt/stacks/${STACK}"
cp -r "/opt/homelab-scripts/${STACK}/." "/opt/stacks/${STACK}/"
cd "/opt/stacks/${STACK}"
[[ ! -f .env && -f .env.example ]] && cp .env.example .env

BS_ROOT_PW="$(rnd_pw)"
BS_PW="$(rnd_pw)"
LD_PW="$(rnd_pw)"

sed -i "s|^BOOKSTACK_DB_ROOT_PASSWORD=.*|BOOKSTACK_DB_ROOT_PASSWORD=${BS_ROOT_PW}|" .env
sed -i "s|^BOOKSTACK_DB_PASSWORD=.*|BOOKSTACK_DB_PASSWORD=${BS_PW}|" .env
sed -i "s|^LINKDING_SUPERUSER_PASSWORD=.*|LINKDING_SUPERUSER_PASSWORD=${LD_PW}|" .env
msg_ok "Senhas geradas"

msg_info "Baixando imagens Docker"
docker compose pull >/dev/null 2>&1
msg_ok "Imagens baixadas"

msg_info "Iniciando containers"
docker compose up -d >/dev/null 2>&1
msg_ok "Containers iniciados"

make_update_helper "/opt/stacks/${STACK}"

cat > /root/knowledge-credentials.txt << EOF
Knowledge Stack Credentials
Gerado: $(date -Is)

BookStack DB root: ${BS_ROOT_PW}
BookStack DB pw:   ${BS_PW}
Linkding admin pw: ${LD_PW}
EOF
chmod 600 /root/knowledge-credentials.txt

echo -e "\n${CM} ${GN}Knowledge instalado!${CL}"
IP="$(hostname -I | awk '{print $1}')"
echo "  BookStack: http://${IP}:6875"
echo "  Memos:     http://${IP}:5230"
echo "  Linkding:  http://${IP}:9090"
echo "  Credenciais salvas em: /root/knowledge-credentials.txt"
