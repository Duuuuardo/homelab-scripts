# Nextcloud

Acesso via proxy:

```txt
http://cloud.lab
```

## Pastas

Arquivos ficam em:

```txt
/data/cloud
```

Sugestão dentro do Nextcloud:

```txt
Documents/
PDFs/
References/
Manuals/
Receipts/
```

## Pós-instalação

Após subir:

```bash
docker logs nextcloud
```

Se o proxy reclamar de trusted domain, conferir `.env`:

```env
NEXTCLOUD_TRUSTED_DOMAINS=cloud.lab 192.168.0.23
```

## Ajustes via occ

Dentro do LXC cloud:

```bash
docker exec -u www-data nextcloud php occ status
docker exec -u www-data nextcloud php occ config:system:set trusted_proxies 0 --value="192.168.0.20"
docker exec -u www-data nextcloud php occ config:system:set overwritehost --value="cloud.lab"
docker exec -u www-data nextcloud php occ config:system:set overwriteprotocol --value="http"
```
