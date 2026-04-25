# GPU passthrough no LXC media

Objetivo: permitir que o Jellyfin use hardware acceleration.

LXC afetado:

```txt
101 media
```

## Intel iGPU

No host Proxmox:

```bash
ls -lah /dev/dri
```

Esperado:

```txt
card0
renderD128
```

## Config do LXC

No host Proxmox:

```bash
nano /etc/pve/lxc/101.conf
```

Adicionar:

```txt
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

Reiniciar o LXC:

```bash
pct restart 101
```

## Dentro do LXC media

Verificar:

```bash
ls -lah /dev/dri
```

Instalar ferramentas:

```bash
apt update
apt install -y vainfo intel-media-va-driver-non-free
vainfo
```

Se `vainfo` retornar informação do driver, o passthrough está funcionando.

## Docker Compose

O compose do `lxc-media` já inclui:

```yaml
devices:
  - /dev/dri:/dev/dri
```

## Jellyfin

No painel do Jellyfin:

```txt
Dashboard > Playback > Transcoding
```

Ativar hardware acceleration:

```txt
Intel QuickSync
```

Marcar os codecs suportados pelo hardware.

## Observação

Para NVIDIA ou AMD, o passthrough muda. Este guia cobre Intel iGPU, que é o cenário mais comum para homeserver.
