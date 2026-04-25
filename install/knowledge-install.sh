#!/usr/bin/env bash
# Author: Eduardo (Duuuuardo)
# Roda DENTRO do LXC knowledge.
# Stack: BookStack + MariaDB + Memos + Linkding

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Configuring apt"
echo 'Acquire::ForceIPv4 "true";' >/etc/apt/apt.conf.d/99force-ipv4
msg_ok "Configured apt"

msg_info "Setting up Docker repository"
setup_deb822_repo \
  "docker" \
  "https://download.docker.com/linux/$(get_os_info id)/gpg" \
  "https://download.docker.com/linux/$(get_os_info id)" \
  "$(get_os_info codename)" \
  "stable" \
  "$(dpkg --print-architecture)"
msg_ok "Docker repository configured"

msg_info "Installing Docker"
$STD apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
$STD systemctl enable --now docker
msg_ok "Installed Docker $(docker --version | awk '{print $3}' | tr -d ',')"

msg_info "Cloning homelab repo"
$STD apt-get install -y git
$STD git clone --depth 1 https://github.com/Duuuuardo/homelab-scripts.git /opt/homelab-scripts
msg_ok "Cloned homelab repo"

msg_info "Deploying knowledge stack"
STACK_DIR="/opt/stacks/lxc-knowledge"
mkdir -p "$STACK_DIR"
cp -r /opt/homelab-scripts/lxc-knowledge/. "$STACK_DIR/"
cd "$STACK_DIR"
[[ ! -f .env ]] && cp .env.example .env

BS_ROOT_PW="$(openssl rand -base64 24 | tr -d '/+=')"
BS_PW="$(openssl rand -base64 24 | tr -d '/+=')"
LD_PW="$(openssl rand -base64 16 | tr -d '/+=')"

sed -i "s|^BOOKSTACK_DB_ROOT_PASSWORD=.*|BOOKSTACK_DB_ROOT_PASSWORD=${BS_ROOT_PW}|" .env
sed -i "s|^BOOKSTACK_DB_PASSWORD=.*|BOOKSTACK_DB_PASSWORD=${BS_PW}|" .env
sed -i "s|^LINKDING_SUPERUSER_PASSWORD=.*|LINKDING_SUPERUSER_PASSWORD=${LD_PW}|" .env

cat >/root/knowledge-credentials.txt <<EOF
Knowledge Stack Credentials
Generated: $(date -Is)

BookStack:  http://$(hostname -I | awk '{print $1}'):6875
Memos:      http://$(hostname -I | awk '{print $1}'):5230
Linkding:   http://$(hostname -I | awk '{print $1}'):9090

BookStack DB root: ${BS_ROOT_PW}
BookStack DB pw:   ${BS_PW}
Linkding admin:    admin / ${LD_PW}
EOF
chmod 600 /root/knowledge-credentials.txt

$STD docker compose pull
$STD docker compose up -d
msg_ok "Deployed knowledge stack"

echo -e "${INFO}${YW} Credentials saved to /root/knowledge-credentials.txt${CL}"

cat >/usr/bin/update <<'EOF'
#!/usr/bin/env bash
set -e
cd /opt/stacks/lxc-knowledge
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null || true
cp -r /opt/homelab-scripts/lxc-knowledge/compose.yml .
docker compose pull
docker compose up -d
echo "Knowledge stack updated."
EOF
chmod +x /usr/bin/update

msg_ok "Install complete"
