#!/usr/bin/env bash
# Stack: Game servers
source /tmp/homelab-install/_lib.sh

echo -e "\n${BL}=== Games ===${CL}\n"

base_setup
install_docker

STACK_DIR="/opt/stacks/lxc-games"
mkdir -p "$STACK_DIR"

msg_info "Escrevendo docker-compose.yml"
cat > "$STACK_DIR/docker-compose.yml" << 'COMPOSE'
# Adicione seus game servers aqui
# Exemplo Minecraft:
# services:
#   minecraft:
#     image: itzg/minecraft-server:latest
#     container_name: minecraft
#     restart: unless-stopped
#     environment:
#       EULA: "TRUE"
#       TYPE: PAPER
#       MEMORY: 4G
#     ports:
#       - "25565:25565"
#     volumes:
#       - minecraft_data:/data
#
# volumes:
#   minecraft_data:
services: {}
COMPOSE
msg_ok "docker-compose.yml criado (vazio — adicione seus servers)"

cat > /usr/bin/update << 'UPDATER'
#!/usr/bin/env bash
cd /opt/stacks/lxc-games
docker compose pull
docker compose up -d
UPDATER
chmod +x /usr/bin/update

echo -e "\n${CM} ${GN}Games: LXC pronto!${CL}"
echo "  Edite /opt/stacks/lxc-games/docker-compose.yml e rode: update"
