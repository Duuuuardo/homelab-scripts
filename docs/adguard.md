# AdGuard Home

## Acesso inicial

```txt
http://192.168.0.22:3000
```

## Upstream DNS

Usar Unbound local:

```txt
127.0.0.1:5335
```

## DNS rewrites

Todos apontam para o proxy:

```txt
home.lab       -> 192.168.0.20
status.lab     -> 192.168.0.20
jellyfin.lab   -> 192.168.0.20
music.lab      -> 192.168.0.20
requests.lab   -> 192.168.0.20
cloud.lab      -> 192.168.0.20
bookstack.lab  -> 192.168.0.20
memos.lab      -> 192.168.0.20
links.lab      -> 192.168.0.20
games.lab      -> 192.168.0.20
```

## Roteador

Configurar o DHCP do roteador para entregar:

```txt
DNS: 192.168.0.22
```

Caso o roteador não permita, configurar manualmente nos dispositivos principais.
