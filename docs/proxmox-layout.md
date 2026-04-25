# Proxmox layout

## Rede

```txt
192.168.0.0/24
```

Sem VLAN.

## Host

Tailscale roda no host Proxmox.

## LXCs

| Nome | IP | Recursos iniciais |
|---|---:|---|
| infra | 192.168.0.20 | 2 vCPU / 2 GB RAM |
| media | 192.168.0.21 | 4 vCPU / 4-8 GB RAM |
| dns | 192.168.0.22 | 1 vCPU / 512 MB-1 GB RAM |
| cloud | 192.168.0.23 | 2-4 vCPU / 4 GB RAM |
| knowledge | 192.168.0.24 | 2 vCPU / 2 GB RAM |
| games | 192.168.0.25 | conforme os jogos |

## Storage

Montagens esperadas:

```txt
/data
├── cloud
├── downloads
├── torrents
├── movies
├── tv
└── music
```

No futuro, quando entrar um NAS, manter os caminhos internos iguais.
