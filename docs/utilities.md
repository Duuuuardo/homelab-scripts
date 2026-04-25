# Utilities

LXC:

```txt
107 utilities
IP: 192.168.0.27
```

Função:

```txt
apps úteis, mas não essenciais para infra
```

## Apps incluídos

| App | Domínio | Porta | Uso |
|---|---|---:|---|
| Whoogle | search.lab | 5000 | busca privada |
| Actual Budget | budget.lab | 5006 | finanças pessoais |
| Neko | neko.lab | 8080 | navegador/desktop virtual |

## Deploy

No LXC utilities:

```bash
cd /opt/homelab/lxc-utilities
cp .env.example .env
docker compose up -d
```

## Whoogle

```txt
http://search.lab
```

## Actual Budget

```txt
http://budget.lab
```

## Neko

```txt
http://neko.lab
```

Portas:

```txt
8080/tcp
52000-52100/udp
```

Se acessar via Tailscale, ajustar no `.env`:

```env
NEKO_NAT1TO1=IP_TAILSCALE_OU_IP_LAN
```

## InvoiceShelf

Não incluído direto no compose principal.

Domínio reservado:

```txt
invoices.lab
```

Instalar apenas se for usar para clientes, cobranças ou orçamentos.
