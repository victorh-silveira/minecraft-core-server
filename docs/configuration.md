# Configuracao

## Arquivo `.env`

Copie o template e preencha valores reais:

```powershell
Copy-Item .env.example .env
```

### Secoes do `.env.example`

| Secao | Variaveis |
|-------|-----------|
| Definicoes globais | `MINECRAFT_VERSION`, `SERVER_TYPE`, `MEMORY_LIMIT`, `EULA_ACCEPTED` |
| Portas | `GAME_PORT`, `RCON_PORT` |
| Jogo | `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` |
| Segredos | `RCON_PASSWORD` |
| Docker | `DOCKER_BASE_IMAGE`, `IMAGE_VERSION`, `DOCKER_PIDS_LIMIT`, `UID`, `GID`, `SKIP_CHOWN` |

**Nunca** versione `.env` — esta no `.gitignore`.

Mantenha `.env` **sincronizado** com `.env.example` (mesmas chaves; valores reais no `.env`).

---

## `server.properties`

Arquivo: `app/src/application/configs/server.properties`

Montado em `/data/server.properties` (gravavel). A imagem itzg mescla variaveis de ambiente no arquivo na inicializacao; por isso **nao** use `read_only: true` nesse volume.

| Propriedade | Valor padrao | Efeito |
|-------------|--------------|--------|
| `online-mode` | `false` | Modo hibrido |
| `difficulty` | `hard` | Dificuldade |
| `max-players` | `20` | Capacidade |
| `enable-rcon` | `true` | RCON ativo |
| `rcon.port` | `25575` | Porta interna RCON |
| `white-list` | `false` | Whitelist desligada |
| `spawn-protection` | `16` | Protecao do spawn |

A senha RCON efetiva vem de `RCON_PASSWORD` no `.env` (variavel de ambiente do container itzg), nao do campo `rcon.password` vazio no arquivo.

---

## Duplicidade: env vars vs `server.properties`

### Problema

O Compose injeta:

```yaml
ONLINE_MODE: "${ONLINE_MODE}"
DIFFICULTY: "${DIFFICULTY}"
MAX_PLAYERS: "${MAX_PLAYERS}"
```

E simultaneamente monta `server.properties` com os mesmos conceitos. Duas fontes de verdade podem divergir.

### Estrategias

#### Opcao A — Env vars como fonte primaria (recomendada para itzg)

- Remover chaves duplicadas de `server.properties` **ou** nao montar o arquivo
- Configurar tudo via `.env` + environment no Compose
- Vantagem: alinhado ao modelo da imagem itzg

#### Opcao B — `server.properties` como fonte primaria

- Remover `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` do environment no Compose
- Manter apenas variaveis que a imagem exige (`EULA`, `VERSION`, `TYPE`, `MEMORY`, RCON)
- Adicionar `OVERRIDE_SERVER_PROPERTIES: "true"` se necessario na imagem itzg

#### Opcao C — Hibrida documentada (estado atual)

- Manter ambos **com valores identicos**
- Documentar que alteracoes devem ser feitas nos **dois lugares** ou automatizar geracao futura

**Acao pendente (roadmap):** adotar Opcao A ou B e eliminar duplicidade.

---

## Docker build args

Passados no build via Compose:

| Arg | Origem | Uso |
|-----|--------|-----|
| `BASE_IMAGE` | `DOCKER_BASE_IMAGE` | Imagem base itzg |
| `IMAGE_VERSION` | `IMAGE_VERSION` | Label OCI |
| `BUILD_DATE` | Makefile (`docker-build`) | Label OCI |
| `VCS_REF` | Git short hash | Label OCI |

---

## Manifesto de mods

`app/src/interface/mods/mods-manifest.json`

Campos por mod:

| Campo | Obrigatorio | Descricao |
|-------|-------------|-----------|
| `id` | Sim | Identificador local |
| `version` | Sim | Versao exata |
| `source` | Sim | `modrinth` ou `curseforge` |
| `sha256` | Recomendado | Integridade (vazio = obtido do Modrinth) |
| `project_slug` | Modrinth | Slug do projeto |
| `download_url` | Alternativa | URL direta |

Sync:

```powershell
cd app && python -m infrastructure.mods
make docker-sync-mods
```
