#!/usr/bin/env bash
# Stack: NPM + Homepage + Uptime Kuma
source "$(dirname "$0")/_lib.sh"

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-infra"

echo -e "\n${BL}══ Infra (NPM + Homepage + Uptime Kuma) ══${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"
deploy_stack "$STACK"
make_update_helper "/opt/stacks/${STACK}"

echo -e "\n${CM} ${GN}Infra instalado!${CL}"
echo "  NPM:        http://$(hostname -I | awk '{print $1}'):81"
echo "  Homepage:   http://$(hostname -I | awk '{print $1}'):3000"
echo "  Uptime:     http://$(hostname -I | awk '{print $1}'):3001"
