# Minecraft Server

Servidor Minecraft **Fabric** com Clean Architecture, Docker local e deploy opcional em **Azure AKS**.

## Estrutura do repositorio

```text
minecraft-server/
├── README.md
├── Makefile
├── .dockerignore
├── .gitignore
├── .github/
├── infra/
│   ├── docker/          # Dockerfile, Compose, .env.example
│   ├── kubernetes/      # Manifestos K8s (base + overlays)
│   └── terraform/       # IaC Azure (bootstrap, modules, live/prod)
├── app/
│   ├── src/             # Clean Architecture (mundo, configs, mods)
│   ├── scripts/         # python, bash, powershell
│   ├── tests/
│   ├── tools/           # semantic-release, commitlint
│   ├── pyproject.toml
│   └── requirements*.txt
├── docs/                # Documentacao tecnica
└── linters/             # tflint, tfsec
```

### O que fica na raiz

| Arquivo | Motivo |
|---------|--------|
| `README.md` | Entrada do projeto |
| `Makefile` | Orquestracao de comandos |
| `.gitignore` / `.gitattributes` | Convencao Git |
| `.dockerignore` | Build context na raiz do monorepo |
| `.github/` | GitHub Actions (exigencia da plataforma) |

## Inicio rapido (Docker local)

```powershell
Copy-Item infra/docker/.env.example infra/docker/.env
pip install -r app/requirements-dev.txt
make pre-commit-install
make docker-build-up
make docker-logs
```

## Comandos principais

```bash
make docker-build-up
make docker-test
make k8s-apply
make k8s-test
make terraform-fmt
make pre-commit-install
```

## Documentacao

| Documento | Conteudo |
|-----------|----------|
| [docs/architecture.md](docs/architecture.md) | Clean Architecture e DDD |
| [docs/azure.md](docs/azure.md) | Terraform, AKS, ACR |
| [docs/devops.md](docs/devops.md) | Docker, CI, pre-commit |
| [docs/operations.md](docs/operations.md) | Operacao, backup, RCON |
| [docs/configuration.md](docs/configuration.md) | `.env`, `server.properties` |
| [docs/README.md](docs/README.md) | Indice completo |

## Pre-commit

Configuracao em [`.pre-commit-config.yaml`](.pre-commit-config.yaml). Padrao de nome: `Area | Acao`.

| Area | Hooks locais |
|------|----------------|
| Codigo | Lint e formatacao Python (Ruff), validacao JSON do manifesto |
| Infra | Formatar e validar Terraform, validar sintaxe YAML |
| Docker | Lint do Dockerfile |
| Arquivo | Newline no fim, remover espacos finais |
| Commit | Conventional Commits (hook `commit-msg`) |

Testes, seguranca e kubeconform rodam no CI (`make ci-test`, workflow `ci.yml`).

```bash
make pre-commit-install
pre-commit run --all-files
```
