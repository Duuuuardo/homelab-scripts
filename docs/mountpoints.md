# Mountpoints

Dados grandes não devem ficar dentro do disco do LXC.

## Media

Host Proxmox:

```txt
/mnt/storage/media
```

Dentro do LXC media:

```txt
/data
```

Exemplo no Proxmox:

```bash
pct set 101 -mp0 /mnt/storage/media,mp=/data
```

Estrutura:

```bash
mkdir -p /mnt/storage/media/{downloads,torrents,movies,tv}
```

## Cloud

Host Proxmox:

```txt
/mnt/storage/cloud
```

Dentro do LXC cloud:

```txt
/data/cloud
```

Exemplo:

```bash
pct set 103 -mp0 /mnt/storage/cloud,mp=/data/cloud
```

## Permissões

Se usar PUID/PGID 1000 nos containers:

```bash
chown -R 1000:1000 /mnt/storage/media
chown -R 1000:1000 /mnt/storage/cloud
```
