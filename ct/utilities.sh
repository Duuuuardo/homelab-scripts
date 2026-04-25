#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Author: Eduardo (Duuuuardo)
# Stack: Whoogle + Actual Budget + Neko

APP="Homelab Utilities"
var_tags="${var_tags:-homelab;utilities}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-32}"
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
  msg_info "Updating utilities stack"
  cd /opt/stacks/lxc-utilities && docker compose pull && docker compose up -d
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${INFO}${YW} Access at:${CL}"
echo -e "${TAB}${BGN}Whoogle: http://${IP}:5000${CL}"
echo -e "${TAB}${BGN}Actual:  http://${IP}:5006${CL}"
echo -e "${TAB}${BGN}Neko:    http://${IP}:8080${CL}"
echo -e "${INFO}${YW} Credentials: pct exec \$CTID -- cat /root/utilities-credentials.txt${CL}"
