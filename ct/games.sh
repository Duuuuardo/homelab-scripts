#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Author: Eduardo (Duuuuardo)
# Stack: Pelican Panel (game servers)
# Privileged: necessário para game servers

APP="Homelab Games"
var_tags="${var_tags:-homelab;games}"
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
  msg_info "Updating games stack"
  cd /opt/stacks/lxc-games && docker compose pull && docker compose up -d
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${INFO}${YW} Access at:${CL}"
echo -e "${TAB}${BGN}Pelican Panel: http://${IP}:8084${CL}"
