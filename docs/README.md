# Documentacao tecnica

Indice dos guias do projeto **Minecraft Server** (Fabric, Docker, Azure AKS, Terraform, Kubernetes, aplicacao hexagonal).

## Por onde comecar

| Perfil | Documento |
|--------|-----------|
| Agentes / LLM | [AGENTS.md](../AGENTS.md) + [agent-coverage.md](agent-coverage.md) |
| Contrato de engenharia | [prompt-model.md](../prompt-model.md) |
| Codigo Python (camadas) | [arquitetura.md](arquitetura.md) + [structure.md](structure.md) |
| Visao da stack cloud | [architecture.md](architecture.md) |
| Subir localmente | [infra-docker.md](infra-docker.md) + [configuration.md](configuration.md) |
| Deploy na Azure | [azure.md](azure.md) |
| Conectar jogadores / hostname | [access-and-hostname.md](access-and-hostname.md) |
| Pipelines e qualidade | [engineering-python.md](engineering-python.md) + [devops.md](devops.md) |
| Dia a dia e troubleshooting | [operations.md](operations.md) |

## Indice completo

| Documento | Descricao |
|-----------|-----------|
| [agent-coverage.md](agent-coverage.md) | Matriz doc + rule + skill para agentes |
| [llm-engineering-doctrine.md](llm-engineering-doctrine.md) | Doutrina: LLM copiloto, invariantes |
| [engineering-surface-sync.md](engineering-surface-sync.md) | Checklist de fechamento de mudanca |
| [engineering-repo-hygiene.md](engineering-repo-hygiene.md) | Remocao segura de codigo morto |
| [engineering-python-deps.md](engineering-python-deps.md) | SSOT de requirements / pyproject |
| [arquitetura.md](arquitetura.md) | Camadas, ports, fluxo do sync, config |
| [structure.md](structure.md) | Arvore e regras de dependencia |
| [engineering-python.md](engineering-python.md) | Qualidade, testes, entrypoints |
| [engineering-logging.md](engineering-logging.md) | Eventos e anti-poluicao |
| [infra-docker.md](infra-docker.md) | Compose e volumes `app/runtime/` |
| [architecture.md](architecture.md) | Stack Azure + AKS + Minecraft, volumes, fluxos |
| [annotations.md](annotations.md) | Catalogo completo `minecraft-server.io/*` e diagramas |
| [azure.md](azure.md) | Terraform, modulos, AKS, ACR, backup, custos, destroy |
| [devops.md](devops.md) | Dockerfile, Compose, Makefile, CI/CD, principios, roadmap |
| [operations.md](operations.md) | Checklists, backup, RCON, annotations, troubleshooting |
| [configuration.md](configuration.md) | `infra/docker/.env`, `server.properties`, manifesto de mods |
| [access-and-hostname.md](access-and-hostname.md) | Whitelist, online-mode, DNS Azure, DuckDNS, NSG |
| [CHANGELOG.md](CHANGELOG.md) | Historico de versoes (nao editar manualmente) |

## Recursos Azure (producao)

| Recurso | Nome |
|---------|------|
| Regiao | `brazilsouth` |
| Resource group | `rg-minecraft-server-prod` |
| VNet | `vnet-minecraft-server-prod-bs` |
| AKS | `aks-minecraft-server-prod` |
| ACR | `acrminecraftserverprod` |
| Storage account | `stminecraftserverprod001` |
| Containers blob | `tfstate`, `world-backups` |
| Identidade backup | `id-mc-world-backup-prod` |

## Recursos Kubernetes (producao)

| Recurso | Nome | Namespace |
|---------|------|-----------|
| Namespace | `minecraft-server-prod` | — |
| StatefulSet | `mc-server` | `minecraft-server-prod` |
| PVC | `mc-data` (32Gi, Retain) | `minecraft-server-prod` |
| Service jogo | `mc-server-game` (LoadBalancer :25565) | `minecraft-server-prod` |
| Service RCON | `mc-server-rcon` (ClusterIP :25575) | `minecraft-server-prod` |
| CronJob backup | `mc-world-backup` (03:00 America/Sao_Paulo) | `minecraft-server-prod` |

Metadados operacionais: annotations `minecraft-server.io/*` — [annotations.md](annotations.md).

## Layout do monorepo

| Pasta | Conteudo |
|-------|----------|
| `infra/docker/` | Imagem e Compose local |
| `infra/kubernetes/base/` | Manifestos K8s reutilizaveis |
| `infra/kubernetes/overlays/prod/` | Patch de producao (recursos, DNS LB, annotations) |
| `infra/terraform/modules/` | Modulos ACR, AKS, network |
| `infra/terraform/live/prod/` | Stack de producao |
| `app/src/` | Codigo hexagonal (domain, application, infrastructure, presentation) |
| `app/runtime/` | Mundo, configs, mods, plugins, logs, database |
| `app/scripts/bash/` | `deploy-aks.sh`, `test-aks.sh`, `resolve-whitelist.sh` |
| `app/scripts/operations/` | Orquestrador de qualidade |
| `docs/` | Esta documentacao |
| `linters/` | commitlint, tflint, tfsec, git-hooks |
| `.cursor/rules/` | Rules versionadas para agentes (`mcs-*.mdc`) |
| `.cursor/skills/` | Skills versionadas (`mcs-*/SKILL.md`) |

Entrada do repositorio: [README.md](../README.md).
