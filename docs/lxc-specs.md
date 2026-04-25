# LXC specs

Rede atual:

```txt
192.168.0.0/24
```

Sem VLAN.

## Resumo

| LXC | Hostname | IP | CPU | RAM | Disco | Privileged | Features | GPU |
|---|---|---:|---:|---:|---:|---|---|---|
| 100 | infra | 192.168.0.20 | 2 | 2 GB | 16 GB | Não | nesting,keyctl | Não |
| 101 | media | 192.168.0.21 | 4 | 4-8 GB | 32 GB | Sim* | nesting,keyctl | Sim |
| 102 | dns | 192.168.0.22 | 1 | 512 MB-1 GB | 8 GB | Não | nesting,keyctl | Não |
| 103 | cloud | 192.168.0.23 | 2-4 | 4 GB | 32 GB | Não | nesting,keyctl | Não |
| 104 | knowledge | 192.168.0.24 | 2 | 2 GB | 16 GB | Não | nesting,keyctl | Não |
| 105 | games | 192.168.0.25 | 2-6 | 4-16 GB | 32+ GB | Sim* | nesting,keyctl | Não |

`media` pode ser unprivileged, mas GPU passthrough em LXC costuma ser mais simples com privileged.

`games` depende do Pelican/Wings e dos servidores que vão rodar.

## Storage

Manter dados fora do disco interno do container.

Exemplo:

```txt
Host: /mnt/storage/media
LXC:  /data
```

Estrutura esperada:

```txt
/data
├── cloud
├── downloads
├── torrents
├── movies
└── tv
```

## Ordem sugerida

```txt
100 infra
102 dns
101 media
103 cloud
104 knowledge
105 games
```
