# Nginx Proxy Manager

Acesso inicial:

```txt
http://192.168.0.20:81
```

Login padrão do NPM na primeira inicialização:

```txt
Email: admin@example.com
Password: changeme
```

Trocar email e senha no primeiro login.

## Proxy Hosts

Criar em:

```txt
Hosts > Proxy Hosts > Add Proxy Host
```

Configuração padrão para todos:

```txt
Scheme: http
Block Common Exploits: enabled
Websockets Support: enabled
Access List: Publicly Accessible
```

Para `.lab`, não ativar SSL.

## Lista de hosts

| Domain Names | Forward Hostname / IP | Forward Port |
|---|---|---:|
| home.lab | 192.168.0.20 | 3000 |
| status.lab | 192.168.0.20 | 3001 |
| jellyfin.lab | 192.168.0.21 | 8096 |
| requests.lab | 192.168.0.21 | 5055 |
| sonarr.lab | 192.168.0.21 | 8989 |
| radarr.lab | 192.168.0.21 | 7878 |
| prowlarr.lab | 192.168.0.21 | 9696 |
| qbitt.lab | 192.168.0.21 | 8080 |
| bazarr.lab | 192.168.0.21 | 6767 |
| cloud.lab | 192.168.0.23 | 8081 |
| bookstack.lab | 192.168.0.24 | 6875 |
| memos.lab | 192.168.0.24 | 5230 |
| links.lab | 192.168.0.24 | 9090 |
| games.lab | 192.168.0.25 | 8084 |

## Advanced config recomendada para Jellyfin

Em `jellyfin.lab`, aba Advanced:

```nginx
proxy_buffering off;
client_max_body_size 20G;
```

## Advanced config recomendada para Nextcloud

Em `cloud.lab`, aba Advanced:

```nginx
client_max_body_size 20G;
proxy_request_buffering off;
proxy_buffering off;
```

Depois, dentro do container do Nextcloud, ajustar trusted proxy se necessário:

```bash
docker exec -u www-data nextcloud php occ config:system:set trusted_proxies 0 --value="192.168.0.20"
docker exec -u www-data nextcloud php occ config:system:set overwritehost --value="cloud.lab"
docker exec -u www-data nextcloud php occ config:system:set overwriteprotocol --value="http"
```

Para uso com domínio real e HTTPS, mudar `overwriteprotocol` para `https`.
