# Dokploy

Dokploy fica separado do resto do homelab.

LXC:

```txt
106 deploy
IP: 192.168.0.26
```

Função:

```txt
deploy de apps próprios
bots
APIs
workers
serviços de teste
```

## Instalação pelo Community Scripts

No shell do Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/dokploy.sh)"
```

Esse script cria/configura o ambiente do Dokploy pelo Community Scripts.

## Specs recomendadas

```txt
CPU: 4 vCPU
RAM: 8 GB
Disco: 64 GB+
Privileged: sim
Features: nesting,keyctl
```

## Acesso

Depois de instalado, acessar pelo IP do LXC/serviço criado.

Proxy host reservado:

```txt
dokploy.lab -> 192.168.0.26:3000
```

## Uso recomendado

```txt
discord-bot
api-pessoal
landing-page
worker
cron-job
webhook
micro-saas
```

Se for bot sem interface web, não precisa domínio. Só precisa rodar 24/7.

## Separação

NPM continua cuidando dos serviços do homelab.

Dokploy cuida dos apps que você desenvolver e quiser publicar/deployar.
