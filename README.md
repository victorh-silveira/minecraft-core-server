# Minecraft Core Server

[![CI](https://github.com/victorh-silveira/minecraft-core-server/actions/workflows/ci.yml/badge.svg)](https://github.com/victorh-silveira/minecraft-core-server/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/victorh-silveira/minecraft-core-server?color=blue&logo=github)](https://github.com/victorh-silveira/minecraft-core-server/releases/latest)
[![Python 3.13+](https://img.shields.io/badge/python-3.13%2B-3776AB?logo=python&logoColor=white)](app/pyproject.toml)
[![Minecraft Forge](https://img.shields.io/badge/minecraft-Forge%2026.3-62B47A?logo=minecraft&logoColor=white)](docs/architecture.md)
[![Forge 66.0.6](https://img.shields.io/badge/forge-66.0.6-E04E14)](https://files.minecraftforge.net/net/minecraftforge/forge/)
[![Java 25](https://img.shields.io/badge/java-25-ED8B00?logo=openjdk&logoColor=white)](infra/docker/Dockerfile)
[![Coverage](https://img.shields.io/badge/coverage-100%25%20branch-brightgreen)](docs/engineering-python.md)
[![Ruff](https://img.shields.io/badge/linter-ruff-D7FF64?logo=ruff&logoColor=black)](docs/engineering-python.md)
[![mypy strict](https://img.shields.io/badge/typecheck-mypy%20strict-294E80)](docs/engineering-python.md)
[![Docker](https://img.shields.io/badge/docker-compose-2496ED?logo=docker&logoColor=white)](docs/infra-docker.md)
[![Kubernetes](https://img.shields.io/badge/k8s-Azure%20AKS-326CE5?logo=kubernetes&logoColor=white)](docs/azure.md)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform&logoColor=white)](docs/azure.md)

Servidor Minecraft Java **26.3 com Forge 66.0.6, sem mods instalados**, arquitetura hexagonal (DDD + TDD), entrega local via Docker Compose e producao em **Azure AKS** (IaC Terraform + manifestos Kubernetes).

## Arquitetura em uma linha

| Camada | Tecnologia | Papel |
|--------|------------|-------|
| Jogo | itzg/minecraft-server (Java 25) | Processo do servidor Forge |
| App | Python hexagonal (`domain` → CLI) | Manifesto vazio e sync opcional de mods |
| Runtime | `app/runtime/` | Mundo, configs, JARs, logs |
| Container local | Docker Compose | Desenvolvimento e testes |
| Orquestracao cloud | AKS 1.34 Free (1x B2ats_v2) | StatefulSet + PVC + LoadBalancer |
| IaC | Terraform `live/prod` | RG, VNet, AKS, tfstate |
| CI/CD | GitHub Actions | Validacao, GitOps de infra, release, deploy |

Codigo da aplicacao: [docs/arquitetura.md](docs/arquitetura.md). Stack Azure: [docs/architecture.md](docs/architecture.md). Deploy: [docs/azure.md](docs/azure.md). Contrato: [prompt-model.md](prompt-model.md). Agentes: [AGENTS.md](AGENTS.md) + [docs/agent-coverage.md](docs/agent-coverage.md).

## Estrutura do repositorio

```text
minecraft-core-server/
├── run.py                   CLI na raiz
├── Makefile                 app-*, docker-*, k8s-*
├── AGENTS.md                entrada para agentes LLM
├── prompt-model.md
├── .cursor/
│   ├── rules/               rules mcs-*.mdc
│   └── skills/              skills mcs-*/SKILL.md
├── .vscode/settings.json
├── .github/                 workflows CI, CD, Destroy
├── infra/
│   ├── docker/
│   ├── kubernetes/
│   └── terraform/
├── app/
│   ├── src/                 domain, application, infrastructure, presentation
│   ├── runtime/             mundo, configs, mods, plugins, logs, database
│   ├── scripts/bash/        deploy, testes, annotations, CI infra
│   ├── scripts/powershell/  probe TCP, exposicao LAN Windows
│   ├── scripts/operations/  orquestrador lint/test/security/clean
│   └── tests/               unit por camada + integration
├── docs/
└── linters/                 commitlint, tflint, tfsec, git-hooks
```

## Inicio rapido (Docker local)

```powershell
Copy-Item infra/docker/.env.example infra/docker/.env
```

Referencia de variaveis na raiz: `.env.example` (o Compose usa `infra/docker/.env`).

```bash
make app-setup
make docker-up
make docker-logs
```

Conecte em `localhost:25565` (ou `GAME_PORT` do `.env`).

Docker local e AKS operam sem autenticacao Mojang e sem whitelist, aceitando clientes originais e launchers paralelos. `AnonymousNoobz` recebe OP nivel 4 ao conectar; `keepInventory`, sono com um jogador e feedback silencioso sao configurados no boot.

Na lista de servidores, o MOTD exibe **Minecraft Core Server** e os dados do runtime em duas linhas coloridas. O icone versionado e um PNG 64x64. O nome salvo acima do MOTD continua sendo escolhido por cada jogador no cliente Vanilla.

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
| `make app-lint` / `app-test` / `app-security` | Gates de qualidade |
| `make docker-up` | Valida o manifesto vazio, build e sobe o servidor Forge local |
| `make docker-smoke` | Valida Docker local |
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
| [AGENTS.md](AGENTS.md) | Prioridades e leitura por tarefa para agentes |
| [docs/agent-coverage.md](docs/agent-coverage.md) | Matriz doc + rule + skill |
| [docs/arquitetura.md](docs/arquitetura.md) | Camadas hexagonais, ports, sync |
| [docs/structure.md](docs/structure.md) | Arvore e regras de dependencia |
| [docs/engineering-python.md](docs/engineering-python.md) | Ruff, mypy, testes, Make |
| [docs/engineering-logging.md](docs/engineering-logging.md) | Eventos de log |
| [docs/infra-docker.md](docs/infra-docker.md) | Compose e volumes locais |
| [docs/architecture.md](docs/architecture.md) | Azure, Kubernetes, Minecraft |
| [docs/annotations.md](docs/annotations.md) | Catalogo `minecraft-server.io/*` |
| [docs/azure.md](docs/azure.md) | Terraform, AKS, backup, custos |
| [docs/devops.md](docs/devops.md) | Docker, CI/CD, principios, roadmap |
| [docs/operations.md](docs/operations.md) | Operacao, backup, troubleshooting |
| [docs/configuration.md](docs/configuration.md) | `.env`, mods, server.properties |
| [docs/access-and-hostname.md](docs/access-and-hostname.md) | Whitelist, hostname, NSG |
| [.github/WORKFLOWS.md](.github/WORKFLOWS.md) | Workflows e secrets |

Historico de versoes: [docs/CHANGELOG.md](docs/CHANGELOG.md) (gerado por release semantica).

## Pre-commit

Padrao de hooks: `Area | Acao` em [`.pre-commit-config.yaml`](.pre-commit-config.yaml).

```bash
make app-setup
pre-commit run --all-files
```

Testes, seguranca, kubeconform e Terraform validate rodam no workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
