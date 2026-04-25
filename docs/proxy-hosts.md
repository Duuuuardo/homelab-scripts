# Proxy hosts

Criar no Nginx Proxy Manager.

| Domínio | Forward hostname/IP | Porta |
|---|---|---:|
| home.lab | 192.168.0.20 | 3000 |
| status.lab | 192.168.0.20 | 3001 |
| jellyfin.lab | 192.168.0.21 | 8096 |
| music.lab | 192.168.0.21 | 8096 |
| requests.lab | 192.168.0.21 | 5055 |
| lidarr.lab | 192.168.0.21 | 8686 |
| prowlarr.lab | 192.168.0.21 | 9696 |
| qbitt.lab | 192.168.0.21 | 8080 |
| bazarr.lab | 192.168.0.21 | 6767 |
| cloud.lab | 192.168.0.23 | 8081 |
| bookstack.lab | 192.168.0.24 | 6875 |
| memos.lab | 192.168.0.24 | 5230 |
| links.lab | 192.168.0.24 | 9090 |
| games.lab | 192.168.0.25 | 8084 |

## SSL

Para `.lab`, usar HTTP local.

Para domínio real, usar DNS Challenge no Nginx Proxy Manager.
