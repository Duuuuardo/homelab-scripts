# Media setup

## Serviços

| Serviço | Uso |
|---|---|
| Jellyfin | Player de filmes, séries e biblioteca local |
| Seerr | Pedidos de filmes e séries |
| Sonarr | Séries |
| Radarr | Filmes |
| Prowlarr | Indexadores |
| qBittorrent | Downloads |
| Bazarr | Legendas |
| FlareSolverr | Ajuda em indexadores com proteção |
| Unpackerr | Extração automática de arquivos compactados |

## Pastas

Estrutura esperada no LXC media:

```txt
/data
├── downloads
├── torrents
├── movies
└── tv
```

## Jellyfin

Bibliotecas:

```txt
Movies -> /data/movies
TV     -> /data/tv
```

## qBittorrent

Acesso:

```txt
http://qbitt.lab
```

Categorias recomendadas:

```txt
movies -> /data/downloads/movies
tv     -> /data/downloads/tv
```

## Prowlarr

Acesso:

```txt
http://prowlarr.lab
```

Adicionar indexadores e depois conectar em:

```txt
Settings > Apps
```

Apps:

```txt
Sonarr  http://sonarr:8989
Radarr  http://radarr:7878
```

## Download client nos apps

Em Sonarr e Radarr:

```txt
Settings > Download Clients > qBittorrent
```

Config:

```txt
Host: qbittorrent
Port: 8080
```

## Root folders

Sonarr:

```txt
/data/tv
```

Radarr:

```txt
/data/movies
```

## Seerr

Acesso:

```txt
http://requests.lab
```

Conectar:

```txt
Jellyfin
Sonarr
Radarr
```

## Fluxo

```txt
Seerr
↓
Sonarr/Radarr
↓
Prowlarr
↓
qBittorrent
↓
Unpackerr
↓
/data/movies ou /data/tv
↓
Jellyfin
```

## Unpackerr

Unpackerr já está no compose, mas precisa de API keys.

Pegar API key em cada app:

```txt
Settings > General > Security > API Key
```

Depois preencher no serviço `unpackerr` em `lxc-media/compose.yml`:

```yaml
UN_SONARR_0_API_KEY=
UN_RADARR_0_API_KEY=
```

Recriar:

```bash
docker compose up -d
```
