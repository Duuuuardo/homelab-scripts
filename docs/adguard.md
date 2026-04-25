# AdGuard Home

Acesso inicial:

```txt
http://192.168.0.22:3000
```

Depois da primeira configuração, o painel normalmente fica em:

```txt
http://192.168.0.22
```

## Upstream DNS

Usar Unbound local:

```txt
127.0.0.1:5335
```

## DNS rewrites

Criar em:

```txt
Filters > DNS rewrites
```

Todos apontam para o proxy:

```txt
home.lab       -> 192.168.0.20
status.lab     -> 192.168.0.20
jellyfin.lab   -> 192.168.0.20
requests.lab   -> 192.168.0.20
sonarr.lab     -> 192.168.0.20
radarr.lab     -> 192.168.0.20
prowlarr.lab   -> 192.168.0.20
qbitt.lab      -> 192.168.0.20
bazarr.lab     -> 192.168.0.20
cloud.lab      -> 192.168.0.20
bookstack.lab  -> 192.168.0.20
memos.lab      -> 192.168.0.20
links.lab      -> 192.168.0.20
games.lab      -> 192.168.0.20
dokploy.lab    -> 192.168.0.20
search.lab     -> 192.168.0.20
budget.lab     -> 192.168.0.20
neko.lab       -> 192.168.0.20
invoices.lab   -> 192.168.0.20
```

## Roteador

No DHCP do roteador, configurar:

```txt
DNS: 192.168.0.22
```

Se o roteador não permitir trocar DNS, configurar manualmente nos dispositivos principais.

## Teste

Em um PC da rede:

```bash
nslookup home.lab 192.168.0.22
nslookup cloud.lab 192.168.0.22
```

Resultado esperado:

```txt
192.168.0.20
```
