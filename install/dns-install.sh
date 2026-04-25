#!/usr/bin/env bash
# Author: Eduardo (Duuuuardo)
# Roda DENTRO do LXC dns.
# Stack: AdGuard Home + Unbound
# Nota: AdGuard usa network_mode: host — porta 53 vai direto no LXC.

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

# AdGuard usa port 53 — garante que nada mais está usando
msg_info "Freeing port 53"
$STD systemctl disable --now systemd-resolved 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" >/etc/resolv.conf
msg_ok "Port 53 freed"

msg_info "Cloning homelab repo"
$STD apt-get install -y git
$STD git clone --depth 1 https://github.com/Duuuuardo/homelab-scripts.git /opt/homelab-scripts
msg_ok "Cloned homelab repo"

msg_info "Deploying DNS stack"
STACK_DIR="/opt/stacks/lxc-dns"
mkdir -p "$STACK_DIR"
cp -r /opt/homelab-scripts/lxc-dns/. "$STACK_DIR/"
cd "$STACK_DIR"
[[ ! -f .env ]] && cp .env.example .env
$STD docker compose pull
$STD docker compose up -d
msg_ok "Deployed DNS stack"

cat >/usr/bin/update <<'EOF'
#!/usr/bin/env bash
set -e
cd /opt/stacks/lxc-dns
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null || true
cp -r /opt/homelab-scripts/lxc-dns/compose.yml .
docker compose pull
docker compose up -d
echo "DNS stack updated."
EOF
chmod +x /usr/bin/update

msg_ok "Install complete"
