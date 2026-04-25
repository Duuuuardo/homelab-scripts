# Homelab

Stacks separados por LXC no Proxmox.

Rede atual:

```txt
192.168.0.0/24
```

Sem VLAN.

## LXCs

| LXC | Função | IP |
|---|---|---|
| infra | proxy, dashboard e monitoramento | 192.168.0.20 |
| media | Jellyfin, Seerr e automação de filmes/séries | 192.168.0.21 |
| dns | AdGuard Home e Unbound | 192.168.0.22 |
| cloud | Nextcloud | 192.168.0.23 |
| knowledge | notas, wiki e links | 192.168.0.24 |
| games | painel de jogos | 192.168.0.25 |

## Serviços principais

- Nextcloud: arquivos, PDFs e sync.
- Memos: notas rápidas.
- BookStack: conhecimento organizado.
- Linkding: links úteis.
- Jellyfin: player de mídia.
- Seerr: pedidos de filmes e séries.
- Sonarr/Radarr: automação de séries e filmes.
- Prowlarr/qBittorrent/Bazarr: indexadores, downloads e legendas.
- Pelican: painel de jogos.
- Homepage: entrada central do homelab.
- Nginx Proxy Manager: reverse proxy.
- AdGuard Home: DNS local e bloqueios.

## Deploy

Ordem recomendada:

```txt
docs/deploy-order.md
```

## Configuração

- `docs/community-scripts-docker-lxc.md`
- `docs/lxc-specs.md`
- `docs/mountpoints.md`
- `docs/gpu-passthrough-media.md`
- `docs/adguard.md`
- `docs/nginx-proxy-manager.md`
- `docs/tailscale-proxmox.md`
- `docs/media-setup.md`
- `docs/nextcloud.md`
- `docs/knowledge-workflow.md`
- `docs/proxmox-layout.md`

## Homepage

A configuração do Homepage já fica em:

```txt
lxc-infra/data/homepage
```

Após subir o LXC infra:

```txt
http://192.168.0.20:3000
http://home.lab
```

## Tailscale

Tailscale roda no host Proxmox.

Não abrir portas no roteador para os serviços.
