# Acesso e hostname

Quem pode entrar no servidor e como conectar de forma estavel (hostname em vez de IP volatil).

## Camadas de seguranca

| Camada | Docker local | AKS producao |
|--------|--------------|--------------|
| Conta Mojang | `ONLINE_MODE=false` no `.env` | `ONLINE_MODE=FALSE` no StatefulSet |
| Whitelist | Desabilitada | Desabilitada |
| Perfil seguro | `ENFORCE_SECURE_PROFILE=FALSE` | `ENFORCE_SECURE_PROFILE=FALSE` |
| Comandos | `AnonymousNoobz` recebe OP ao conectar | `AnonymousNoobz` recebe OP ao conectar |
| RCON | Porta `127.0.0.1:25575` apenas | Service `mc-server-rcon` ClusterIP + port-forward |
| Rede (opcional) | Firewall do host | NSG `game_cidr_list` no Terraform |

Servidor em modo offline (`online-mode=false`): nao exige conta Mojang e aceita clientes originais ou launchers paralelos. Qualquer nick pode entrar. `RCON_CMDS_ON_CONNECT=op AnonymousNoobz` concede OP nivel 4 ao administrador, permitindo comandos como `/gamemode`.

No boot, `RCON_CMDS_STARTUP` aplica:

- `gamerule keep_inventory true`
- `gamerule players_sleeping_percentage 1`
- `gamerule command_block_output false`
- `gamerule send_command_feedback false`

> **Risco critico:** nao existe verificacao de identidade. Qualquer pessoa que use o nick `AnonymousNoobz` recebe administracao completa do mundo. Restrinja `game_cidr_list` no AKS e o firewall do host quando o servidor nao deva ser publico.

## Docker local

1. `Copy-Item infra/docker/.env.example infra/docker/.env`
2. `ONLINE_MODE=false`
3. `make docker-up`

O Compose fixa `WHITE_LIST=FALSE`, `ENFORCE_WHITELIST=FALSE` e `ENFORCE_SECURE_PROFILE=FALSE`. As variaveis de whitelist nao fazem parte do `.env` local.

RCON: `127.0.0.1:25575` no host (Compose publica RCON so em localhost).

Jogo na LAN: o Compose publica `0.0.0.0:GAME_PORT` dentro do WSL; `make docker-up` detecta o IP atual do WSL, atualiza o portproxy do Windows e cria a regra de Firewall (UAC). O smoke valida conexão Minecraft local, LAN, IP WAN obtido via ipify e `noobz.ddns.net`, incluindo correspondencia DNS, porta e MOTD.

## Identificacao no cliente

O servidor publica um MOTD de duas linhas com formatacao Minecraft e o icone `server-icon.png` 64x64. O cliente Vanilla nao recebe um nome fixo do servidor: cada jogador escolhe o campo **Server Name** ao adicionar o endereco.

## AKS e GitHub Actions

### Secret (environment `production`)

| Secret | Uso |
|--------|-----|
| `RCON_PASSWORD` | Secret `mc-rcon` |

O pipeline recria `mc-rcon` a cada `deploy-app` (`ci.yml` apos nova tag, ou `cd.yml` manual).

### RCON administrativo

```bash
kubectl port-forward -n minecraft-server-prod svc/mc-server-rcon 25575:25575
```

Senha: valor de `RCON_PASSWORD` no GitHub.

## Hostname para jogadores

### Opcao 1 — DNS label do LoadBalancer Azure (recomendado)

O overlay prod define no Service `mc-server-game`:

```yaml
service.beta.kubernetes.io/azure-dns-label-name: minecraftserverprod
```

FQDN tipico apos provisionamento:

```text
minecraftserverprod.brazilsouth.cloudapp.azure.com
```

No cliente Minecraft use **Multiplayer > Adicionar servidor** com esse host (porta 25565 implicita).

Consultar endereco real (IP ou hostname ja resolvido):

```bash
kubectl -n minecraft-server-prod get svc mc-server-game \
  -o jsonpath='{.metadata.annotations.minecraft-server\.io/conectividade-endereco}{"\n"}'
```

Ou:

```bash
make k8s-annotate
kubectl -n minecraft-server-prod describe svc mc-server-game
```

Label alternativo: configure `game_dns_label` em `terraform.tfvars` e alinhe o patch `service-game-lb.yaml` se mudar o nome.

### Opcao 2 — DuckDNS

Apos obter o IP do LoadBalancer (`make k8s-annotate`), atualize manualmente em https://www.duckdns.org com o token da sua conta.

### Opcao 3 — nip.io (teste rapido)

Com IP `74.163.209.125`:

```text
74-163-209-125.nip.io
```

IP dinamico: hostname muda quando o LB mudar.

## Restringir por IP no NSG (opcional)

Em `infra/terraform/live/prod/terraform.tfvars`:

```hcl
game_cidr_list = ["203.0.113.10/32", "198.51.100.0/24"]
```

Limita TCP 25565 no NSG. Sem whitelist, esta e a unica restricao de entrada do jogo no AKS.

`admin_cidr_list` restringe RCON (25575) na borda da rede Azure e a API do AKS quando preenchido.

## Migracao offline para online

Mundos criados com `online-mode=false` podem ter UUIDs diferentes ao ativar conta Mojang. Faca backup antes (`make docker-down` + zip local ou backup AKS).
