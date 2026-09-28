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
| Servidor | `MINECRAFT_VERSION=26.3`, `SERVER_TYPE=FORGE`, `FORGE_VERSION=66.0.6`, `MINECRAFT_INIT_MEMORY`, `MINECRAFT_MAX_MEMORY`, `EULA_ACCEPTED` |
| Portas | `GAME_PORT`, `RCON_PORT` |
| Smoke de rede | `SMOKE_LAN_HOST`, `SMOKE_WAN_PORT`, `SMOKE_DNS_HOST`, `SMOKE_IPIFY_URL`, `SMOKE_CONNECT_TIMEOUT_SEC`, `SMOKE_STARTUP_TIMEOUT_SEC`, `SMOKE_EXPECTED_MOTD`, `SMOKE_EXTERNAL_STATUS_URL`, `SMOKE_USER_AGENT` |
| Acesso e comandos | `ONLINE_MODE=FALSE`, whitelist/perfil seguro desabilitados e OP para `AnonymousNoobz` |
| Jogo | `DIFFICULTY`, `MAX_PLAYERS` |
| Segredos | `RCON_PASSWORD` |
| Container | `UID`, `GID`, `SKIP_CHOWN`, `DOCKER_CPU_LIMIT`, `DOCKER_MEMORY_LIMIT`, `DOCKER_MEMORY_RESERVATION`, `DOCKER_MEMORY_SWAP_LIMIT`, `DOCKER_PIDS_LIMIT`, `DOCKER_TMPFS_LIMIT` |
| Build | `DOCKER_BASE_IMAGE`, `IMAGE_VERSION` |
| Sync Python | `LOG_LEVEL`, `SYNC_DISABLE_DOTENV`, `MODS_MANIFEST_PATH`, `MODS_DIR`, `SYNC_USER_AGENT` |

Producao AKS nao usa este `.env`; equivalentes estao no StatefulSet e no Secret `mc-rcon`.

## Producao AKS (StatefulSet + Secrets)

| Config | Origem |
|--------|--------|
| `VERSION`, `TYPE`, `INIT_MEMORY`, `MAX_MEMORY`, `DIFFICULTY`, `MAX_PLAYERS` | `infra/kubernetes/base/statefulset.yaml` e overlay prod |
| `ONLINE_MODE`, `WHITE_LIST`, `ENFORCE_WHITELIST`, `ENFORCE_SECURE_PROFILE` | StatefulSet (todos `FALSE`) |
| `ENABLE_COMMAND_BLOCK`, niveis OP/function | StatefulSet (habilitado, nivel 4) |
| `RCON_CMDS_STARTUP` | `keep_inventory=true`, sono com um jogador e feedback administrativo silencioso |
| `RCON_CMDS_ON_CONNECT` | `op AnonymousNoobz` |
| `RCON_PASSWORD` | Secret `mc-rcon` (CD) |
| Limites CPU/RAM | Patch `overlays/prod/patches/resources.yaml` |
| Propriedades extras | ConfigMap `mc-server-properties` |

Overlay prod: `kubectl apply -k infra/kubernetes/overlays/prod`.

O heap Java deve permanecer abaixo do limite do container. No Docker local, o padrao e `1G` inicial, `1536M` maximo e limite rigido de `2G`; os 512 MiB restantes acomodam Metaspace, buffers nativos, threads e o Forge. `DOCKER_MEMORY_SWAP_LIMIT=2G` igual ao limite de memoria impede swap adicional do container. No AKS prod, o heap maximo e `1G` sob limite de `1536Mi`.

## `server.properties`

Template: `app/runtime/configs/server.properties`. No Docker local, o bootstrap gera a copia gravavel e ignorada `app/runtime/server.properties` antes de iniciar o container.
Montado em `/data/server.properties` (gravavel pela imagem itzg).

| Propriedade | Padrao no arquivo | Producao efetiva |
|-------------|-------------------|------------------|
| `online-mode` | `false` | Alinhado a `ONLINE_MODE=FALSE` (local e K8s) |
| `white-list` | `false` | Desabilitada local e K8s |
| `enable-command-block` | `true` | Comandos de command block habilitados |
| `op-permission-level` | `4` | Administracao completa para jogadores com OP |
| `function-permission-level` | `4` | Funcoes com nivel maximo |
| `difficulty` | `hard` | Alinhado ao env |
| `max-players` | `20` | Alinhado ao env |
| `motd` | Duas linhas coloridas | Alinhado a `MOTD` no Compose e StatefulSet |
| `enable-rcon` | `true` | RCON ativo |
| `rcon.port` | `25575` | Porta interna |

Senha RCON efetiva: variavel de ambiente / Secret, nao o campo vazio no arquivo.

## Identidade na lista de servidores

- MOTD: `§a§lMinecraft Core Server§r` e `§7Forge 26.3 §8• §eSurvival §8• §bKeepInventory`.
- Icone: `app/runtime/configs/server-icon.png`, PNG exatamente 64x64.
- Runtime: `ICON=/templates/server-icon.png` e `OVERRIDE_ICON=true` copiam o ativo para `/data/server-icon.png`.
- Nome do servidor: definido pelo jogador ao salvar o endereco no cliente Vanilla; o servidor nao impoe esse campo.

## Duplicidade env vs `server.properties` (local)

Compose injeta `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` e monta `server.properties` em paralelo. A imagem itzg pode mesclar env no arquivo na inicializacao.

| Estrategia | Acao |
|------------|------|
| A (recomendada) | Env vars como fonte; minimizar duplicata no properties |
| B | Apenas `server.properties`; remover env duplicado |
| C (atual local) | Manter ambos com **valores identicos** |

Ver [devops.md](devops.md) (roadmap prioridade 1).

## Docker build args

| Arg | Origem |
|-----|--------|
| `BASE_IMAGE` | `DOCKER_BASE_IMAGE` (ex.: `itzg/minecraft-server:java25`) |
| `IMAGE_VERSION` | `.env` |
| `BUILD_DATE`, `VCS_REF` | Makefile `docker-build` |

## Manifesto de mods

O servidor Forge opera sem mods instalados. O manifesto versionado deve manter `mods: []`; a infraestrutura de sync continua disponivel para uma futura mudanca explicitamente aprovada.

`app/runtime/mods/mods-manifest.json`

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `id` | Sim | Nome local do mod |
| `version` | Sim | Versao exata |
| `source` | Sim | `modrinth` ou `curseforge` |
| `sha256` | Obrigatorio apos resolucao | Integridade SHA-256 (manifesto ou provedor) |
| `project_slug` | Modrinth | Slug no Modrinth |
| `download_url` | Opcional | URL direta |

```powershell
make docker-sync-mods
make app-test
```

JARs em `app/runtime/mods/*.jar` estao no `.gitignore`.

## Terraform (`terraform.tfvars`)

| Variavel | Descricao |
|----------|-----------|
| `subscription_id`, `tenant_id` | Azure |
| `kubernetes_version` | Padrao `1.34` (sem downgrade no Azure) |
| `admin_cidr_list` | CIDRs para RCON no NSG e allowlist da API AKS |
| `game_cidr_list` | CIDRs para porta 25565 (vazio = qualquer) |
| `game_dns_label` | Label DNS do LB (alinhar com patch K8s) |

Exemplo: `infra/terraform/live/prod/terraform.tfvars.example`.
