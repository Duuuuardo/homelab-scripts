# LXC specs

Rede atual:

```txt
192.168.0.0/24
```

Sem VLAN.

## Resumo

| LXC | Hostname | IP | CPU | RAM | Disco | Privileged | Features | Observação |
|---|---|---:|---:|---:|---:|---|---|---|
| 100 | infra | 192.168.0.20 | 2 | 2 GB | 16 GB | Não | nesting,keyctl | Proxy/dashboard |
| 101 | media | 192.168.0.21 | 4 | 4-8 GB | 32 GB | Sim* | nesting,keyctl | Jellyfin com `/dev/dri` |
| 102 | dns | 192.168.0.22 | 1 | 512 MB-1 GB | 8 GB | Não | nesting,keyctl | AdGuard/Unbound |
| 103 | cloud | 192.168.0.23 | 2-4 | 4 GB | 32 GB | Não | nesting,keyctl | Nextcloud |
| 104 | knowledge | 192.168.0.24 | 2 | 2 GB | 16 GB | Não | nesting,keyctl | BookStack/Memos/Linkding |
| 105 | games | 192.168.0.25 | 2-6 | 4-16 GB | 32+ GB | Sim* | nesting,keyctl | Pelican |
| 106 | deploy | 192.168.0.26 | 4 | 8 GB | 64+ GB | Sim | nesting,keyctl | Dokploy |
| 107 | utilities | 192.168.0.27 | 2-4 | 4-8 GB | 32 GB | Não | nesting,keyctl | Whoogle/Actual/Neko |

`media` usa `/dev/dri` no compose do Jellyfin. No teu fluxo, os ajustes de LXC/GPU ficam a cargo do Docker LXC/Community Scripts quando aplicável.

`deploy` é separado porque Dokploy gerencia deploys próprios.

## Ordem sugerida

```txt
100 infra
102 dns
101 media
103 cloud
104 knowledge
105 games
106 deploy
107 utilities
```
