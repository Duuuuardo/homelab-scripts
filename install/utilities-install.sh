#!/usr/bin/env bash
# Author: Eduardo (Duuuuardo)
# Roda DENTRO do LXC utilities.
# Stack: Whoogle + Actual Budget + Neko

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

msg_info "Deploying utilities stack"
STACK_DIR="/opt/stacks/lxc-utilities"
mkdir -p "$STACK_DIR"
cp -r /opt/homelab-scripts/lxc-utilities/. "$STACK_DIR/"
cd "$STACK_DIR"
[[ ! -f .env ]] && cp .env.example .env

NEKO_PW="$(openssl rand -base64 16 | tr -d '/+=')"
NEKO_ADMIN_PW="$(openssl rand -base64 16 | tr -d '/+=')"

sed -i "s|^NEKO_PASSWORD=.*|NEKO_PASSWORD=${NEKO_PW}|" .env
sed -i "s|^NEKO_ADMIN_PASSWORD=.*|NEKO_ADMIN_PASSWORD=${NEKO_ADMIN_PW}|" .env

cat >/root/utilities-credentials.txt <<EOF
Utilities Stack Credentials
Generated: $(date -Is)

Whoogle: http://$(hostname -I | awk '{print $1}'):5000
Actual:  http://$(hostname -I | awk '{print $1}'):5006
Neko:    http://$(hostname -I | awk '{print $1}'):8080

Neko user pw:  ${NEKO_PW}
Neko admin pw: ${NEKO_ADMIN_PW}

Nota: ajuste NEKO_NAT1TO1 no .env com o IP do host Proxmox se WebRTC não conectar.
EOF
chmod 600 /root/utilities-credentials.txt

$STD docker compose pull
$STD docker compose up -d
msg_ok "Deployed utilities stack"

echo -e "${INFO}${YW} Credentials saved to /root/utilities-credentials.txt${CL}"

cat >/usr/bin/update <<'EOF'
#!/usr/bin/env bash
set -e
cd /opt/stacks/lxc-utilities
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null || true
cp -r /opt/homelab-scripts/lxc-utilities/compose.yml .
docker compose pull
docker compose up -d
echo "Utilities stack updated."
EOF
chmod +x /usr/bin/update

msg_ok "Install complete"
