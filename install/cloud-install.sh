#!/usr/bin/env bash
# Author: Eduardo (Duuuuardo)
# Roda DENTRO do LXC cloud.
# Stack: Nextcloud + MariaDB + Redis

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

msg_info "Creating /data/cloud"
mkdir -p /data/cloud
chown -R 33:33 /data/cloud
msg_ok "Created /data/cloud"

msg_info "Cloning homelab repo"
$STD apt-get install -y git
$STD git clone --depth 1 https://github.com/Duuuuardo/homelab-scripts.git /opt/homelab-scripts
msg_ok "Cloned homelab repo"

msg_info "Deploying cloud stack"
STACK_DIR="/opt/stacks/lxc-cloud"
mkdir -p "$STACK_DIR"
cp -r /opt/homelab-scripts/lxc-cloud/. "$STACK_DIR/"
cd "$STACK_DIR"
[[ ! -f .env ]] && cp .env.example .env

# Gera senhas seguras e substitui no .env
DB_ROOT_PW="$(openssl rand -base64 24 | tr -d '/+=')"
DB_PW="$(openssl rand -base64 24 | tr -d '/+=')"
ADMIN_PW="$(openssl rand -base64 16 | tr -d '/+=')"

sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=${DB_ROOT_PW}|" .env
sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=${DB_PW}|" .env
sed -i "s|^NEXTCLOUD_ADMIN_PASSWORD=.*|NEXTCLOUD_ADMIN_PASSWORD=${ADMIN_PW}|" .env

cat >/root/cloud-credentials.txt <<EOF
Nextcloud Credentials
Generated: $(date -Is)

URL:            http://$(hostname -I | awk '{print $1}'):8081
Admin user:     admin
Admin password: ${ADMIN_PW}

DB root:    ${DB_ROOT_PW}
DB user pw: ${DB_PW}
EOF
chmod 600 /root/cloud-credentials.txt

$STD docker compose pull
$STD docker compose up -d
msg_ok "Deployed cloud stack"

echo -e "${INFO}${YW} Credentials saved to /root/cloud-credentials.txt${CL}"

cat >/usr/bin/update <<'EOF'
#!/usr/bin/env bash
set -e
cd /opt/stacks/lxc-cloud
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null || true
cp -r /opt/homelab-scripts/lxc-cloud/compose.yml .
docker compose pull
docker compose up -d
echo "Cloud stack updated."
EOF
chmod +x /usr/bin/update

msg_ok "Install complete"
