# Community Scripts - Docker LXC

Fluxo usado neste homelab:

```txt
1. Criar Docker LXC pelo Community Scripts
2. Definir IP estático
3. Ativar nesting/keyctl
4. Copiar a pasta do stack correspondente
5. Subir com docker compose
```

Site:

```txt
https://community-scripts.org/
```

Usar:

```txt
Docker LXC
```

## Parâmetros sugeridos

### 100 - infra

```txt
Hostname: infra
IP: 192.168.0.20/24
Gateway: 192.168.0.1
CPU: 2
RAM: 2048 MB
Disk: 16 GB
Privileged: no
Features: nesting,keyctl
```

### 101 - media

```txt
Hostname: media
IP: 192.168.0.21/24
Gateway: 192.168.0.1
CPU: 4
RAM: 4096-8192 MB
Disk: 32 GB
Privileged: yes
Features: nesting,keyctl
```

Privileged é recomendado aqui para facilitar GPU passthrough para Jellyfin.

### 102 - dns

```txt
Hostname: dns
IP: 192.168.0.22/24
Gateway: 192.168.0.1
CPU: 1
RAM: 512-1024 MB
Disk: 8 GB
Privileged: no
Features: nesting,keyctl
```

### 103 - cloud

```txt
Hostname: cloud
IP: 192.168.0.23/24
Gateway: 192.168.0.1
CPU: 2-4
RAM: 4096 MB
Disk: 32 GB
Privileged: no
Features: nesting,keyctl
```

### 104 - knowledge

```txt
Hostname: knowledge
IP: 192.168.0.24/24
Gateway: 192.168.0.1
CPU: 2
RAM: 2048 MB
Disk: 16 GB
Privileged: no
Features: nesting,keyctl
```

### 105 - games

```txt
Hostname: games
IP: 192.168.0.25/24
Gateway: 192.168.0.1
CPU: 2-6
RAM: 4096-16384 MB
Disk: 32+ GB
Privileged: yes
Features: nesting,keyctl
```

## Deploy de um stack

Exemplo com infra:

```bash
mkdir -p /opt/homelab
cd /opt/homelab
```

Copiar a pasta `lxc-infra` do repo para:

```txt
/opt/homelab/lxc-infra
```

Depois:

```bash
cd /opt/homelab/lxc-infra
cp .env.example .env
docker compose up -d
```

Repetir para os outros LXCs:

```txt
lxc-media      -> media
lxc-dns        -> dns
lxc-cloud      -> cloud
lxc-knowledge  -> knowledge
lxc-games      -> games
lxc-utilities  -> utilities
```

## Teste rápido

Dentro de cada LXC:

```bash
docker ps
docker compose version
```


## Dokploy

Para Dokploy, usar o script addon específico no shell do Proxmox:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/dokploy.sh)"
```

Depois seguir:

```txt
docs/dokploy.md
```


## GPU / media

O compose do media já monta:

```txt
/dev/dri
```

Para Jellyfin com aceleração, criar o Docker LXC media de forma compatível com passthrough pelo fluxo do Community Scripts/Proxmox.
