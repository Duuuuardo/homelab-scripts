#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Author: Eduardo (Duuuuardo)
# Stack: AdGuard Home + Unbound

APP="Homelab DNS"
var_tags="${var_tags:-homelab;dns}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  msg_info "Updating DNS stack"
  cd /opt/stacks/lxc-dns && docker compose pull && docker compose up -d
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${INFO}${YW} Access at:${CL}"
echo -e "${TAB}${BGN}AdGuard: http://${IP}:3000${CL}"
