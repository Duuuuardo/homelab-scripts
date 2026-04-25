# Ordem de deploy

## 1. Criar Docker LXCs

Usar Community Scripts:

```txt
Docker LXC
```

Seguir:

```txt
docs/community-scripts-docker-lxc.md
docs/lxc-specs.md
```

## 2. Configurar mountpoints

Principalmente:

```txt
101 media -> /data
103 cloud -> /data/cloud
```

Ver:

```txt
docs/mountpoints.md
```

## 3. Subir infra

No LXC infra:

```bash
cd /opt/homelab/lxc-infra
cp .env.example .env
docker compose up -d
```

Acessar:

```txt
http://192.168.0.20:81
```

## 4. Subir DNS

No LXC dns:

```bash
cd /opt/homelab/lxc-dns
cp .env.example .env
docker compose up -d
```

Configurar:

```txt
docs/adguard.md
```

## 5. Configurar NPM

Criar os hosts:

```txt
docs/nginx-proxy-manager.md
```

## 6. Subir media

No LXC media:

```bash
cd /opt/homelab/lxc-media
cp .env.example .env
docker compose up -d
```

Configurar:

```txt
docs/media-setup.md
```

Observação: o LXC media usa `/dev/dri` no compose para aceleração de hardware do Jellyfin. No fluxo deste repo, os ajustes de LXC/GPU ficam no setup do Docker LXC/Community Scripts quando aplicável.

## 7. Subir cloud, knowledge, games e utilities

Em cada LXC:

```bash
cp .env.example .env
docker compose up -d
```

## 8. Dokploy

Ver:

```txt
docs/dokploy.md
```

## 9. Testar

```txt
http://home.lab
http://jellyfin.lab
http://requests.lab
http://cloud.lab
http://bookstack.lab
http://search.lab
http://budget.lab
```
