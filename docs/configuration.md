# Configuracao

Variaveis de ambiente, propriedades do servidor e manifesto de mods — local (Docker) e producao (Kubernetes).

## Arquivo `.env` (Docker local)

Templates (nao versionar o `.env` real):

| Arquivo | Uso |
|---------|-----|
| [infra/docker/.env.example](../infra/docker/.env.example) | **Recomendado** — usado pelo `docker-compose` e `make docker-*` |
| [.env.example](../.env.example) | Referencia minima (mesmas chaves do exemplo enxuto na raiz) |

```powershell
Copy-Item infra/docker/.env.example infra/docker/.env
```

Preencha cada valor no formato `VARIAVEL=valor`. Os templates usam placeholders `<insira_aqui_...>`.

### Secoes

| Secao | Variaveis |
|-------|-----------|
| Servidor | `MINECRAFT_VERSION`, `SERVER_TYPE`, `MEMORY_LIMIT`, `EULA_ACCEPTED` |
| Portas | `GAME_PORT`, `RCON_PORT` |
| Seguranca | `ONLINE_MODE`, `WHITE_LIST`, `ENFORCE_WHITELIST`, `MINECRAFT_WHITELIST` |
| Jogo | `DIFFICULTY`, `MAX_PLAYERS` |
| Segredos | `RCON_PASSWORD` |
| Container | `UID`, `GID`, `SKIP_CHOWN`, `DOCKER_PIDS_LIMIT` |
| Build | `DOCKER_BASE_IMAGE`, `IMAGE_VERSION` |

Producao AKS nao usa este `.env`; equivalentes estao no StatefulSet e nos Secrets `mc-rcon` / `mc-access`.

## Producao AKS (StatefulSet + Secrets)

| Config | Origem |
|--------|--------|
| `VERSION`, `TYPE`, `MEMORY`, `DIFFICULTY`, `MAX_PLAYERS` | `infra/kubernetes/base/statefulset.yaml` |
| `ONLINE_MODE`, `WHITE_LIST`, `ENFORCE_WHITELIST` | StatefulSet (`TRUE`) |
| `WHITELIST` | Secret `mc-access` (CD) |
| `RCON_PASSWORD` | Secret `mc-rcon` (CD) |
| Limites CPU/RAM | Patch `overlays/prod/patches/resources.yaml` |
| Propriedades extras | ConfigMap `mc-server-properties` |

Overlay prod: `kubectl apply -k infra/kubernetes/overlays/prod`.

## `server.properties`

Arquivo: `app/src/application/configs/server.properties`  
Montado em `/data/server.properties` (gravavel pela imagem itzg).

| Propriedade | Padrao no arquivo | Producao efetiva |
|-------------|-------------------|------------------|
| `online-mode` | `false` no arquivo | Sobrescrito por `ONLINE_MODE=TRUE` no K8s |
| `difficulty` | `hard` | Alinhado ao env |
| `max-players` | `20` | Alinhado ao env |
| `enable-rcon` | `true` | RCON ativo |
| `rcon.port` | `25575` | Porta interna |

Senha RCON efetiva: variavel de ambiente / Secret, nao o campo vazio no arquivo.

## Duplicidade env vs `server.properties` (local)

Compose injeta `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` e monta `server.properties` em paralelo. A imagem itzg pode mesclar env no arquivo na inicializacao.

| Estrategia | Acao |
|------------|------|
| A (recomendada) | Env vars como fonte; minimizar duplicata no properties |
| B | Apenas `server.properties`; remover env duplicado |
| C (atual local) | Manter ambos com **valores identicos** |

Ver [roadmap.md](roadmap.md) prioridade 1.

## Docker build args

| Arg | Origem |
|-----|--------|
| `BASE_IMAGE` | `DOCKER_BASE_IMAGE` (ex.: `itzg/minecraft-server:java21`) |
| `IMAGE_VERSION` | `.env` |
| `BUILD_DATE`, `VCS_REF` | Makefile `docker-build` |

## Manifesto de mods

`app/src/interface/mods/mods-manifest.json`

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `id` | Sim | Nome local do mod |
| `version` | Sim | Versao exata |
| `source` | Sim | `modrinth` ou `curseforge` |
| `sha256` | Recomendado | Integridade |
| `project_slug` | Modrinth | Slug no Modrinth |
| `download_url` | Opcional | URL direta |

```powershell
make docker-sync-mods
cd app && python -m pytest tests/unit/infrastructure/mods/test_sync.py
```

JARs em `app/src/interface/mods/*.jar` estao no `.gitignore`.

## Terraform (`terraform.tfvars`)

| Variavel | Descricao |
|----------|-----------|
| `subscription_id`, `tenant_id` | Azure |
| `kubernetes_version` | Padrao `1.31` |
| `admin_cidr_list` | CIDRs para RCON no NSG |
| `game_cidr_list` | CIDRs para porta 25565 (vazio = qualquer) |
| `game_dns_label` | Label DNS do LB (alinhar com patch K8s) |

Exemplo: `infra/terraform/live/prod/terraform.tfvars.example`.
