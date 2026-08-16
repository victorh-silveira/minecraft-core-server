# Estrutura do repositorio

Arvore e regras de dependencia. Contrato: [prompt-model.md](../prompt-model.md).

## Arvore

```text
minecraft-core-server/
├── run.py
├── Makefile
├── AGENTS.md
├── prompt-model.md
├── .env.example
├── app/
│   ├── src/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   ├── runtime/
│   │   ├── world/
│   │   ├── configs/server.properties
│   │   ├── mods/mods-manifest.json
│   │   ├── plugins/
│   │   ├── logs/
│   │   └── database/
│   ├── tests/
│   │   ├── unit/{domain,application,infrastructure,presentation}/
│   │   └── integration/infrastructure/
│   ├── scripts/
│   │   ├── bash/
│   │   ├── operations/clean_workspace.py
│   │   └── setup.sh
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── requirements-dev.txt
├── docs/
├── infra/{docker,kubernetes,terraform}/
└── linters/
```

## Codigo vs runtime

| Caminho | Tipo |
|---------|------|
| `app/src/` | Codigo Python hexagonal |
| `app/runtime/` | Dados do servidor Fabric (bind mounts Docker) |
| `app/tests/` | Testes |
| `infra/` | Docker, Kubernetes, Terraform |

Imports da aplicacao: `from domain...`, `from application...`, `from infrastructure...`, `from presentation...` (`PYTHONPATH=app/src`).

## Dependencias entre camadas

```text
presentation → application → domain
presentation → infrastructure → application → domain
```

Proibido:

- `domain` importar `application`, `infrastructure` ou `presentation`
- `application` importar `infrastructure` ou `presentation`

O orquestrador (`make app-lint`) falha se essas regras quebrarem.

## Limite de arquivo

Arquivos `.py` em `app/` e `run.py` devem ter no maximo 300 linhas.
