# Infra Docker

Entrega local do servidor Fabric. Stack Azure: [architecture.md](architecture.md) e [azure.md](azure.md).

## Artefatos

| Arquivo | Papel |
|---------|-------|
| [`infra/docker/Dockerfile`](../infra/docker/Dockerfile) | Imagem baseada em `itzg/minecraft-server:java21` |
| [`infra/docker/docker-compose.yml`](../infra/docker/docker-compose.yml) | Servico `mc-server` |
| [`infra/docker/.env.example`](../infra/docker/.env.example) | Variaveis do Compose (copiar para `.env`) |

O Compose usa `infra/docker/.env`, nao o `.env` da raiz. A raiz [`.env.example`](../.env.example) documenta tambem as vars do sync Python.

## Volumes (`app/runtime/` → `/data`)

| Host | Container |
|------|-----------|
| `app/runtime/world` | `/data/world` |
| `app/runtime/configs/server.properties` | `/data/server.properties` |
| `app/runtime/mods` | `/data/mods` |
| `app/runtime/plugins` | `/data/plugins` |
| `app/runtime/logs` | `/data/logs` |
| `app/runtime/database` | `/data/database` |

Templates copiados na imagem: `server.properties` e `mods-manifest.json`. Bind mounts locais prevalecem em runtime.

## Comandos

```bash
Copy-Item infra/docker/.env.example infra/docker/.env
make docker-up
make docker-logs
make docker-smoke
```

Sync de mods: `python run.py` (Makefile `docker-sync-mods`). JARs nao entram no Git.
