#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Author: Eduardo (Duuuuardo)
# Stack: Jellyfin + Sonarr + Radarr + Prowlarr + qBittorrent + Bazarr + Seerr + Unpackerr
# Privileged: necessário para /dev/dri passthrough do Jellyfin

APP="Homelab Media"
var_tags="${var_tags:-homelab;media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-32}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  msg_info "Updating media stack"
  cd /opt/stacks/lxc-media && docker compose pull && docker compose up -d
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${INFO}${YW} Access at:${CL}"
echo -e "${TAB}${BGN}Jellyfin:     http://${IP}:8096${CL}"
echo -e "${TAB}${BGN}Seerr:        http://${IP}:5055${CL}"
echo -e "${TAB}${BGN}qBittorrent:  http://${IP}:8080${CL}"
echo -e "${TAB}${BGN}Sonarr:       http://${IP}:8989${CL}"
echo -e "${TAB}${BGN}Radarr:       http://${IP}:7878${CL}"
echo -e "${TAB}${BGN}Prowlarr:     http://${IP}:9696${CL}"
echo -e "${TAB}${BGN}Bazarr:       http://${IP}:6767${CL}"
