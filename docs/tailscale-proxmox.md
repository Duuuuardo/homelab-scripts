# Tailscale no Proxmox

Tailscale roda no host Proxmox, não dentro de cada LXC.

## Instalação

No shell do Proxmox:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Subir o node:

```bash
tailscale up
```

Abrir o link exibido no terminal e autenticar.

## Acesso básico

Depois de autenticado, testar:

```bash
tailscale status
tailscale ip -4
```

A GUI do Proxmox poderá ser acessada pelo IP Tailscale:

```txt
https://IP_TAILSCALE_DO_PVE:8006
```

## Acessar a rede da casa via Tailscale

Para acessar os LXCs pelo IP `192.168.0.x` fora de casa, anunciar rota da subnet:

```bash
tailscale up --advertise-routes=192.168.0.0/24
```

Depois, no painel web do Tailscale:

```txt
Machines > Proxmox host > Edit route settings > Approve 192.168.0.0/24
```

## Usar DNS do AdGuard fora de casa

No painel web do Tailscale:

```txt
DNS > Nameservers > Add nameserver
```

Adicionar:

```txt
192.168.0.22
```

Ativar:

```txt
Override local DNS
```

Com isso, estando conectado ao Tailscale, domínios como `home.lab` e `cloud.lab` devem resolver.

## Teste fora da rede

Com o notebook ou celular no 4G/5G e Tailscale conectado:

```bash
nslookup home.lab
ping 192.168.0.20
```

Abrir:

```txt
http://home.lab
```

## Observação

Não abrir portas do roteador para esses serviços.

Acesso externo fica via Tailscale.
