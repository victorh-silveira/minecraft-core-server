# AGENTS.md — Minecraft Core Server

Ponto de entrada para agentes Cursor/LLM neste repositorio.

## Idioma e ambiente

- Respostas e commits em **PT-BR**
- Terminal/scripts: **WSL Linux** (nunca CMD/PowerShell nativo)
- Sem emojis em codigo, logs ou docs tecnicos
- Sem comentarios no codigo

## Universo operacional

- Servidor Minecraft **Fabric 1.20.6** (imagem itzg/java21)
- Codigo Python hexagonal: sync de JARs a partir de `app/runtime/mods/mods-manifest.json`
- Camadas: `app/src/{domain,application,infrastructure,presentation}`
- Dados de jogo: `app/runtime/{world,configs,mods,plugins,logs,database}` — nunca em `app/src/`
- Entrega local: Docker Compose; producao: Azure AKS + Terraform
- Entrypoints sync: `python run.py`, `make docker-sync-mods`
- Gates: `make app-lint`, `make app-validate`, `make app-test`, `make app-security`
- Orquestrador: `app/scripts/operations/clean_workspace.py` (`--area` / `--stage`)
- Contrato: [`prompt-model.md`](prompt-model.md)

## O que o LLM e / nao e

- **E:** copiloto de engenharia e auditoria
- **Nao e:** processo do servidor Fabric, substituto dos gates, nem gerador de stack OTRS/WireMock/MariaDB

Doutrina: [`docs/llm-engineering-doctrine.md`](docs/llm-engineering-doctrine.md)
Matriz 100% cobertura: [`docs/agent-coverage.md`](docs/agent-coverage.md)
Rules/skills versionadas: [`.cursor/rules/`](.cursor/rules/) e [`.cursor/skills/`](.cursor/skills/)

## Proibicoes globais

- HTTP/DB/framework web em `domain` ou `application`
- Logs dentro de use case ou entidade
- Composition root fora de `presentation`
- Dados de jogo (mundo, JARs, logs) sob `app/src/`
- Arquivos `app/src/**/*.py` ou `run.py` acima de **300** linhas
- Cobertura branch nas camadas de app abaixo de **100%**
- Baixar `fail-under` ou pular mypy/ruff/vulture “temporariamente”
- Commitar `.env`, tokens ou `*.jar` de mods
- Assunto de commit em ingles; escopo fora do enum commitlint
- Copiar stack de outro dominio sem necessidade

## Escopos commitlint

`all`, `application`, `config`, `deps`, `docker`, `domain`, `infra`, `llm`, `mods`, `presentation`, `release`, `repo`, `runtime`, `scripts`, `test`, `tools`

Formato: `tipo(escopo): assunto em PT-BR` + corpo obrigatorio.

## Pre-commit / Make

`.pre-commit-config.yaml` + `clean_workspace.py` stages: lint, test (cov 100%), security, clean; commit-msg: commitlint.

| Alvo | Efeito |
|------|--------|
| `make app-setup` | venv + hooks |
| `make app-lint` | ruff, mypy, vulture, estrutura, imports |
| `make app-test` | pytest + cobertura 100% branch |
| `make app-security` | bandit + pip-audit |
| `make app-run` | sync de mods |
| `make app-pre-commit-run` | pre-commit em todos os arquivos |

## Leitura por tarefa

| Tarefa | Abrir primeiro |
|--------|----------------|
| Qualquer mudanca | este arquivo + `docs/agent-coverage.md` |
| Hexagonal / nova feature Python | `docs/arquitetura.md` + skill `mcs-hexagonal-tdd` |
| Sync de mods / manifesto | `docs/configuration.md` + skill `mcs-mods-sync` |
| Logging | `docs/engineering-logging.md` + skill `mcs-logging-audit` |
| Docker / volumes / runtime | `docs/infra-docker.md` + skill `mcs-infra-stack` |
| AKS / Terraform / ops | `docs/operations.md` + skill `mcs-ops-runbook` |
| QA / pre-commit / cobertura | `docs/engineering-python.md` + skill `mcs-precommit` |
| Deps Python | `docs/engineering-python-deps.md` + skill `mcs-python-deps` |
| Higienizacao | `docs/engineering-repo-hygiene.md` + skill `mcs-repo-hygiene` |
| Fechamento de mudanca | `docs/engineering-surface-sync.md` + skill `mcs-surface-sync` |
| Scaffold / contrato | `prompt-model.md` + skill `mcs-surface-sync` |

Inventario: [`docs/structure.md`](docs/structure.md)
Arquitetura app: [`docs/arquitetura.md`](docs/arquitetura.md)
Stack cloud: [`docs/architecture.md`](docs/architecture.md)
