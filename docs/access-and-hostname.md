# Acesso e hostname

Quem pode entrar no servidor e como conectar de forma estavel (hostname em vez de IP volatil).

## Camadas de seguranca

| Camada | Docker local | AKS producao |
|--------|--------------|--------------|
| Conta Mojang | `ONLINE_MODE=false` no `.env` | `ONLINE_MODE=FALSE` no StatefulSet |
| Whitelist | `MINECRAFT_WHITELIST` no `.env` | Secret `mc-access` / GitHub `MINECRAFT_WHITELIST` |
| RCON | Porta `127.0.0.1:25575` apenas | Service `mc-server-rcon` ClusterIP + port-forward |
| Rede (opcional) | Firewall do host | NSG `game_cidr_list` no Terraform |

Servidor em modo offline (`online-mode=false`): nao exige conta Mojang; whitelist continua validando nicks permitidos. No deploy, nicks do secret `MINECRAFT_WHITELIST` sao convertidos para UUID offline (PlayerDB nao resolve nicks sem conta Mojang).

## Docker local

1. `Copy-Item infra/docker/.env.example infra/docker/.env`
2. `MINECRAFT_WHITELIST=AnonymousNoobz` (ou varios nicks separados por virgula)
3. `ONLINE_MODE=false`, `WHITE_LIST=true`, `ENFORCE_WHITELIST=true`
4. `make docker-build-up`

RCON: `127.0.0.1:25575` no host (Compose publica RCON só em localhost).

## AKS e GitHub Actions

### Secrets (environment `production`)

| Secret | Uso |
|--------|-----|
| `RCON_PASSWORD` | Secret `mc-rcon` |
| `MINECRAFT_WHITELIST` | Secret `mc-access` (virgula, sem espacos extras; padrao `AnonymousNoobz` no workflow se ausente) |

O pipeline recria os secrets a cada `deploy-app` (`ci.yml` apos nova tag, ou `cd.yml` manual).

### Atualizar whitelist

1. Altere `MINECRAFT_WHITELIST` em GitHub Secrets
2. Push em `main` com nova release, ou dispare `cd.yml` modo `deploy-app`

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

Limita TCP 25565 no NSG. Jogadores com IP dinamico dependem de whitelist, nao desta lista.

`admin_cidr_list` restringe RCON (25575) na borda da rede Azure quando preenchido.

## Migracao offline para online

Mundos criados com `online-mode=false` podem ter UUIDs diferentes ao ativar conta Mojang. Faca backup antes (`make docker-down` + zip local ou backup AKS).
