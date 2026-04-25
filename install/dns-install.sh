#!/usr/bin/env bash
# Stack: AdGuard Home
source "$(dirname "$0")/_lib.sh"

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-dns"

echo -e "\n${BL}══ DNS (AdGuard Home) ══${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"
deploy_stack "$STACK"
make_update_helper "/opt/stacks/${STACK}"

echo -e "\n${CM} ${GN}DNS instalado!${CL}"
echo "  AdGuard Home: http://$(hostname -I | awk '{print $1}'):3000"
