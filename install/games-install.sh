#!/usr/bin/env bash
# Stack: Game servers via Docker
source /tmp/homelab-install/_lib.sh

REPO_URL="${REPO_URL:-https://github.com/Duuuuardo/homelab-scripts.git}"
STACK="lxc-games"

echo -e "\n${BL}══ Games ══${CL}\n"

base_setup
install_docker
clone_repo "$REPO_URL"
deploy_stack "$STACK"
make_update_helper "/opt/stacks/${STACK}"

echo -e "\n${CM} ${GN}Games instalado!${CL}"
