# Documentacao tecnica

Indice dos guias do projeto **Minecraft Server** (Fabric, Docker, Azure AKS, Terraform, Kubernetes).

## Por onde comecar

| Perfil | Documento |
|--------|-----------|
| Visao geral da stack | [architecture.md](architecture.md) |
| Subir localmente | [configuration.md](configuration.md) + [operations.md](operations.md) (secao Docker) |
| Deploy na Azure | [azure.md](azure.md) |
| Conectar jogadores / hostname | [access-and-hostname.md](access-and-hostname.md) |
| Pipelines e qualidade | [devops.md](devops.md) |
| Dia a dia e troubleshooting | [operations.md](operations.md) |

## Indice completo

| Documento | Descricao |
|-----------|-----------|
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
| `app/src/` | Dados e codigo do dominio |
| `app/scripts/bash/` | `deploy-aks.sh`, `test-aks.sh`, `resolve-whitelist.sh` |
| `docs/` | Esta documentacao |
| `linters/` | Configuracao tflint e tfsec |

Entrada do repositorio: [README.md](../README.md).
