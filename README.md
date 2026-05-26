# Minecraft Server

Servidor Minecraft **Fabric 1.20.6** com Clean Architecture, entrega local via Docker Compose e producao em **Azure AKS** (IaC Terraform + manifestos Kubernetes).

## Arquitetura em uma linha

| Camada | Tecnologia | Papel |
|--------|------------|-------|
| Jogo | itzg/minecraft-server (Java 21) | Processo do servidor Fabric |
| App | Python `infrastructure.mods` | Sync de mods via manifesto |
| Container local | Docker Compose | Desenvolvimento e testes |
| Orquestracao cloud | AKS 1.34 (1 node) | StatefulSet + PVC + LoadBalancer |
| IaC | Terraform `live/prod` | RG, VNet, ACR, AKS, identidade de backup |
| CI/CD | GitHub Actions | Validacao, GitOps de infra, release, deploy |
| Dados | Azure Disk (Retain) + Blob `world-backups` | Mundo persistente e backup diario |

Diagrama completo: [docs/architecture.md](docs/architecture.md). Deploy Azure: [docs/azure.md](docs/azure.md).

## Estrutura do repositorio

```text
minecraft-core-server/
├── README.md
├── Makefile
├── .github/                 workflows CI, CD, Destroy e composite actions
├── infra/
│   ├── docker/              Dockerfile, Compose, .env
│   ├── kubernetes/          base + overlay prod (Kustomize)
│   └── terraform/           modules + live/prod (brazilsouth)
├── app/
│   ├── src/                 configs, mods (sync), dados locais (world/logs)
│   ├── scripts/bash/        deploy, testes, annotations, CI infra
│   ├── scripts/python/      clean_workspace (lint/test/security)
│   ├── tests/unit/          testes do sync de mods
│   └── tools/               commitlint, releaserc
├── docs/                    documentacao tecnica (indice em docs/README.md)
└── linters/                 tflint, tfsec (ver linters/README.md)
```

## Inicio rapido (Docker local)

```powershell
Copy-Item infra/docker/.env.example infra/docker/.env
```

Referencia minima de variaveis na raiz: `.env.example` (o Compose usa `infra/docker/.env`).
make dev-deps
make pre-commit-install
make docker-sync-mods
make docker-build-up
make docker-logs
```

Conecte em `localhost:25565` (ou `GAME_PORT` do `.env`).

## Inicio rapido (AKS)

Pre-requisitos: Azure CLI, Terraform, kubectl, credenciais no GitHub (OIDC).

```bash
cd infra/terraform/live/prod
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
az aks get-credentials -g rg-minecraft-server-prod -n aks-minecraft-server-prod
make k8s-apply
make k8s-annotate
make k8s-test
```

Endereco do jogo (apos LoadBalancer provisionar):

```bash
kubectl -n minecraft-server-prod get svc mc-server-game \
  -o jsonpath='{.metadata.annotations.minecraft-server\.io/conectividade-endereco}{"\n"}'
```

## Comandos principais

| Comando | Descricao |
|---------|-----------|
| `make docker-build-up` | Sync mods, build e sobe servidor local |
| `make docker-test` | Valida Docker local |
| `make ci-lint` / `make ci-test` | Espelha gates do CI |
| `make k8s-deploy` | Deploy manual completo no AKS |
| `make k8s-apply` | Aplica overlay prod no cluster |
| `make k8s-annotate` | Atualiza annotations de conectividade e saude |
| `make k8s-test` | Diagnostico AKS pos-deploy |
| `make terraform-plan` | Plan Terraform live/prod |

## Documentacao

| Documento | Conteudo |
|-----------|----------|
| [docs/README.md](docs/README.md) | Indice completo |
| [docs/architecture.md](docs/architecture.md) | Azure, Kubernetes, Minecraft |
| [docs/annotations.md](docs/annotations.md) | Catalogo `minecraft-server.io/*` e diagramas |
| [docs/azure.md](docs/azure.md) | Terraform, AKS, backup, custos |
| [docs/devops.md](docs/devops.md) | Docker, CI/CD, principios, roadmap |
| [docs/operations.md](docs/operations.md) | Operacao, backup, troubleshooting |
| [docs/configuration.md](docs/configuration.md) | `.env`, mods, server.properties |
| [docs/access-and-hostname.md](docs/access-and-hostname.md) | Whitelist, hostname, NSG |
| [.github/README.md](.github/README.md) | Workflows e secrets |

Historico de versoes: [docs/CHANGELOG.md](docs/CHANGELOG.md) (gerado por release semantica).

## Pre-commit

Padrao de hooks: `Area | Acao` em [`.pre-commit-config.yaml`](.pre-commit-config.yaml).

```bash
make pre-commit-install
pre-commit run --all-files
```

Testes, seguranca, kubeconform e Terraform validate rodam no workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
