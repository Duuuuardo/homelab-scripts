#!/usr/bin/env bash
# Author: Eduardo (Duuuuardo)
# Roda DENTRO do LXC media (privileged).
# Stack: Jellyfin + Sonarr + Radarr + Prowlarr + FlareSolverr + qBittorrent + Bazarr + Seerr + Unpackerr

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

# Intel VA-API para hardware transcoding do Jellyfin
if [[ -d /dev/dri ]]; then
  msg_info "Installing Intel VA-API drivers"
  $STD apt-get install -y vainfo intel-media-va-driver-non-free 2>/dev/null || \
    $STD apt-get install -y vainfo intel-media-va-driver 2>/dev/null || true
  msg_ok "VA-API drivers installed"
else
  msg_info "No /dev/dri — skipping VA-API (configure GPU passthrough in Proxmox if needed)"
fi

msg_info "Creating /data directories"
mkdir -p /data/{downloads,torrents,movies,tv,music}
chown -R 1000:1000 /data
msg_ok "Created /data structure"

msg_info "Cloning homelab repo"
$STD apt-get install -y git
$STD git clone --depth 1 https://github.com/Duuuuardo/homelab-scripts.git /opt/homelab-scripts
msg_ok "Cloned homelab repo"

msg_info "Deploying media stack"
STACK_DIR="/opt/stacks/lxc-media"
mkdir -p "$STACK_DIR"
cp -r /opt/homelab-scripts/lxc-media/. "$STACK_DIR/"
cd "$STACK_DIR"
[[ ! -f .env ]] && cp .env.example .env
$STD docker compose pull
$STD docker compose up -d
msg_ok "Deployed media stack"

cat >/usr/bin/update <<'EOF'
#!/usr/bin/env bash
set -e
cd /opt/stacks/lxc-media
git -C /opt/homelab-scripts pull --ff-only 2>/dev/null || true
cp -r /opt/homelab-scripts/lxc-media/compose.yml .
docker compose pull
docker compose up -d
echo "Media stack updated."
EOF
chmod +x /usr/bin/update

msg_ok "Install complete"
