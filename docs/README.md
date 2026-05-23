# Documentacao tecnica

Indice dos guias do projeto Minecraft Server.

| Documento | Descricao |
|-----------|-----------|
| [architecture.md](architecture.md) | Clean Architecture, DDD, volumes, scorecard |
| [principles.md](principles.md) | DRY, SOLID, testes, pre-commit |
| [configuration.md](configuration.md) | `.env`, `server.properties`, manifesto de mods |
| [devops.md](devops.md) | Dockerfile, Compose, Makefile, CI |
| [azure.md](azure.md) | Terraform, AKS, ACR, manifestos Kubernetes |
| [operations.md](operations.md) | Checklist, backup, RCON, troubleshooting |
| [roadmap.md](roadmap.md) | Gaps e prioridades de evolucao |
| [CHANGELOG.md](CHANGELOG.md) | Historico de versoes (semantic-release) |

## Layout do monorepo

| Pasta | Conteudo |
|-------|----------|
| `infra/docker/` | Dockerfile, Compose, `.env` |
| `infra/kubernetes/` | Manifestos AKS |
| `infra/terraform/` | IaC Azure |
| `app/` | Codigo, testes, scripts, dependencias Python |
| `docs/` | Documentacao |
| `linters/` | tflint, tfsec, pre-commit |

Entrada principal do repositorio: [README.md](../README.md).
