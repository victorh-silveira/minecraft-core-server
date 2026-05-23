# Acesso e hostname do servidor

Controle de quem entra no servidor e como conectar sem depender de IP:porta.

## Camadas de seguranca

| Camada | Docker local | AKS producao |
|--------|--------------|--------------|
| Conta Mojang | `ONLINE_MODE=true` | `ONLINE_MODE=TRUE` no StatefulSet |
| Whitelist | `MINECRAFT_WHITELIST` no `.env` | Secret `mc-access` / GitHub `MINECRAFT_WHITELIST` |
| RCON | Porta publicada so em `127.0.0.1` | Service `ClusterIP` + `kubectl port-forward` |
| Rede (opcional) | Firewall do host | NSG `game_cidr_list` no Terraform |

Somente jogadores com conta Minecraft legitima **e** nick na whitelist conseguem entrar.

## Docker local

1. Copie `infra/docker/.env.example` para `infra/docker/.env`.
2. Preencha `MINECRAFT_WHITELIST=SeuNick,AmigoNick` (nicks exatos da conta Mojang).
3. Mantenha `ONLINE_MODE=true`, `WHITE_LIST=true`, `ENFORCE_WHITELIST=true`.
4. Suba com `make docker-build-up`.

RCON fica acessivel apenas em `127.0.0.1:25575` no host.

## AKS / GitHub Actions

### Secrets obrigatorios no environment `production`

| Secret | Exemplo |
|--------|---------|
| `RCON_PASSWORD` | senha forte |
| `MINECRAFT_WHITELIST` | `victorh,amigo1,amigo2` |

O CD cria o secret `mc-access` com a whitelist a cada deploy.

### Atualizar quem pode jogar

1. Edite o secret `MINECRAFT_WHITELIST` no GitHub (Settings > Secrets > Actions).
2. Rode o workflow **CD** em modo `deploy-app` ou aguarde a proxima release.

## Hostname sem comprar dominio

### Opcao 1 — Azure DNS gratuito (recomendado no AKS)

O Terraform cria um IP publico estatico com label DNS:

```
minecraftserverprod.brazilsouth.cloudapp.azure.com
```

Apos `deploy-infra` e `deploy-app`, conecte no Minecraft usando **somente esse hostname** (porta padrao 25565, sem `:25565`).

Consulte o FQDN:

```bash
terraform -chdir=infra/terraform/live/prod output -raw game_fqdn
```

Se o label estiver em uso na regiao, altere `game_dns_label` em `terraform.tfvars`.

### Opcao 2 — DuckDNS (subdominio personalizado)

Servico gratuito: `https://www.duckdns.org`

1. Crie um subdominio (ex: `meuminecraft.duckdns.org`).
2. Exporte `DUCKDNS_TOKEN` e `DUCKDNS_DOMAIN`.
3. Apos cada deploy ou mudanca de IP do LoadBalancer:

```bash
bash app/scripts/bash/update-duckdns.sh
```

Agende no cron ou Task Scheduler para manter o DNS sincronizado.

### Opcao 3 — nip.io (emergencia, sem cadastro)

Se o IP do LoadBalancer for `74.163.209.125`, use:

```
74-163-209-125.nip.io
```

Nao e DDNS: se o IP mudar, o hostname muda. Util para testes rapidos.

## Restringir por IP (opcional)

Se todos os jogadores tiverem IP fixo conhecido, preencha em `terraform.tfvars`:

```hcl
game_cidr_list = ["203.0.113.10/32", "198.51.100.0/24"]
```

Isso limita a porta 25565 no NSG. Amigos com IP dinamico devem usar apenas whitelist + online-mode.

## Migracao de modo offline para online

Se o mundo foi jogado com `online-mode=false`, os UUIDs dos jogadores podem mudar na primeira entrada com conta Mojang. Faca backup do mundo antes do deploy com as novas configuracoes.
