# Homelab

Repo com os stacks separados por LXC no Proxmox.

Rede atual:

```txt
192.168.0.0/24
```

Sem VLAN.

## LXCs

| LXC | Função | IP |
|---|---|---|
| infra | proxy, dashboard e monitoramento | 192.168.0.20 |
| media | Jellyfin e automação de mídia/música | 192.168.0.21 |
| dns | AdGuard Home e Unbound | 192.168.0.22 |
| cloud | Nextcloud | 192.168.0.23 |
| knowledge | notas, wiki e links | 192.168.0.24 |
| games | painel de jogos | 192.168.0.25 |

## Ideia do setup

- Nextcloud guarda arquivos, PDFs, documentos e sync.
- Memos recebe notas rápidas e ideias soltas.
- BookStack guarda conhecimento organizado.
- Linkding guarda links úteis.
- Pelican fica isolado para game servers.
- Nginx Proxy Manager centraliza os domínios locais.
- AdGuard resolve os domínios `.lab`.

## Deploy

Dentro de cada LXC:

```bash
cp .env.example .env
docker compose up -d
```

## Domínios locais

Todos os domínios apontam para o LXC infra:

```txt
home.lab       -> 192.168.0.20
status.lab     -> 192.168.0.20
jellyfin.lab   -> 192.168.0.20
music.lab      -> 192.168.0.20
requests.lab   -> 192.168.0.20
cloud.lab      -> 192.168.0.20
memos.lab      -> 192.168.0.20
bookstack.lab  -> 192.168.0.20
links.lab      -> 192.168.0.20
games.lab      -> 192.168.0.20
```

O encaminhamento para cada serviço é feito no Nginx Proxy Manager.

## Tailscale

Tailscale roda no host Proxmox.

Assim o acesso externo fica privado, sem abrir os serviços direto na internet.
