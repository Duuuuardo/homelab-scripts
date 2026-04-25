#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Author: Eduardo (Duuuuardo)
# Stack: BookStack + Memos + Linkding

APP="Homelab Knowledge"
var_tags="${var_tags:-homelab;knowledge}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
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
  msg_info "Updating knowledge stack"
  cd /opt/stacks/lxc-knowledge && docker compose pull && docker compose up -d
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${INFO}${YW} Access at:${CL}"
echo -e "${TAB}${BGN}BookStack: http://${IP}:6875${CL}"
echo -e "${TAB}${BGN}Memos:     http://${IP}:5230${CL}"
echo -e "${TAB}${BGN}Linkding:  http://${IP}:9090${CL}"
echo -e "${INFO}${YW} Credentials: pct exec \$CTID -- cat /root/knowledge-credentials.txt${CL}"
