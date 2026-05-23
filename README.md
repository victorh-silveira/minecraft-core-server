# Minecraft Server

Servidor Minecraft **Fabric** com Docker Compose, Clean Architecture em `src/` e sincronizacao de mods via manifesto lockfile.

## Proposito

- **Clean Architecture** em `src/` (dominio, aplicacao, interface, infraestrutura)
- **Infraestrutura como codigo** (Dockerfile, Docker Compose, `.env`)
- **Lockfile de mods** (`mods-manifest.json`) com download idempotente via Python
- **Quality gates** (pre-commit, pytest, bandit, pip-audit)

## Inicio rapido

```powershell
Copy-Item .env.example .env
pip install -r requirements-dev.txt
make docker-build-up
make docker-logs
```

## Estrutura do repositorio

```text
minecraft-server/
├── README.md                 # Entrada do projeto
├── docs/                     # Guias detalhados
├── .env / .env.example
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── scripts/
│   ├── python/
│   │   ├── sync_mods.py
│   │   └── clean_workspace.py
│   ├── bash/
│   │   └── test-docker.sh
│   └── powershell/
│       └── test-docker.ps1
├── src/
│   ├── domain/world-data/
│   ├── application/configs/
│   ├── interface/mods/
│   ├── interface/plugins/
│   └── infrastructure/
│       ├── logging/
│       └── database/
├── tests/
└── tools/
```

## Camadas (Clean Architecture)

| Camada | Pasta | Responsabilidade |
|--------|-------|------------------|
| Dominio | `src/domain/world-data` | Estado do jogo (mundo, progresso) |
| Aplicacao | `src/application/configs` | Regras e parametros (`server.properties`) |
| Interface | `src/interface/mods`, `plugins` | Extensoes (mods Fabric, plugins futuros) |
| Infraestrutura | `src/infrastructure/logging` | Logs operacionais |

Scripts de automacao (`scripts/python`, `scripts/bash`, `scripts/powershell`) e orquestracao (Compose, Makefile) ficam na raiz, fora de `src/`.

## Comandos Make (prefixo docker-*)

```bash
make docker-build-up
make docker-logs
make docker-down
make docker-sh
```

## Modo hibrido (online-mode=false)

- Whitelist quando necessario
- Mod ou plugin de autenticacao interna em redes publicas
- RCON restrito a localhost ou VPN (ver [docs/operations.md](docs/operations.md))

## Documentacao

| Documento | Conteudo |
|-----------|----------|
| [docs/architecture.md](docs/architecture.md) | Clean Architecture e DDD |
| [docs/principles.md](docs/principles.md) | DRY, SOLID e analise de codigo |
| [docs/configuration.md](docs/configuration.md) | `.env`, `server.properties` e variaveis |
| [docs/devops.md](docs/devops.md) | Docker, Compose, Makefile, pre-commit |
| [docs/operations.md](docs/operations.md) | Checklist operacional, backup, seguranca |
| [docs/roadmap.md](docs/roadmap.md) | Gaps conhecidos e prioridades |

Indice completo: [docs/README.md](docs/README.md)
