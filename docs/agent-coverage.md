# Matriz de cobertura do agente (100%)

Cada superficie do servidor tem **doc + rule + skill** (ou `—` justificado). Entrada: [`AGENTS.md`](../AGENTS.md).

Rules/skills vivem em [`.cursor/`](../.cursor/) e sao **versionadas** no git.

## Matriz

| Superficie | Doc | Rule (`.cursor/rules/`) | Skill (`.cursor/skills/`) |
|------------|-----|-------------------------|---------------------------|
| Doutrina LLM | [llm-engineering-doctrine.md](llm-engineering-doctrine.md) | `mcs-llm-doctrine.mdc` | `mcs-surface-sync` |
| Engenharia / QA | [engineering-python.md](engineering-python.md) | `mcs-engineering.mdc` + `mcs-testing.mdc` | `mcs-precommit` |
| Hexagonal / domain | [arquitetura.md](arquitetura.md) + [structure.md](structure.md) | `mcs-hexagonal.mdc` + `mcs-domain-pure.mdc` | `mcs-hexagonal-tdd` |
| Testing / TDD | [engineering-python.md](engineering-python.md) | `mcs-testing.mdc` | `mcs-hexagonal-tdd` + `mcs-precommit` |
| Logging | [engineering-logging.md](engineering-logging.md) | `mcs-logging.mdc` | `mcs-logging-audit` |
| Sync de mods | [arquitetura.md](arquitetura.md) + [configuration.md](configuration.md) | `mcs-mods-sync.mdc` | `mcs-mods-sync` |
| Runtime / dados Fabric | [structure.md](structure.md) + [infra-docker.md](infra-docker.md) | `mcs-runtime-data.mdc` | `mcs-infra-stack` |
| Infra Docker / AKS | [infra-docker.md](infra-docker.md) + [architecture.md](architecture.md) + [azure.md](azure.md) | `mcs-infra.mdc` | `mcs-infra-stack` + `mcs-ops-runbook` |
| Scripts / ops | [operations.md](operations.md) + [structure.md](structure.md) | `mcs-scripts.mdc` | `mcs-ops-runbook` |
| Deps Python | [engineering-python-deps.md](engineering-python-deps.md) | `mcs-python-deps.mdc` | `mcs-python-deps` |
| Higienizacao | [engineering-repo-hygiene.md](engineering-repo-hygiene.md) | `mcs-repo-hygiene.mdc` | `mcs-repo-hygiene` |
| Surface sync | [engineering-surface-sync.md](engineering-surface-sync.md) | `mcs-surface-sync.mdc` | `mcs-surface-sync` |
| Contrato prompt-modelo | [prompt-model.md](../prompt-model.md) | `mcs-engineering.mdc` | `mcs-surface-sync` |

## Pastas DDD ↔ matriz

| Pasta | Linha da matriz |
|-------|-----------------|
| `app/src/domain/` | Hexagonal / domain |
| `app/src/application/` | Hexagonal / domain |
| `app/src/infrastructure/` | Sync de mods + Logging |
| `app/src/presentation/` | Sync de mods + Logging |
| `app/runtime/` | Runtime / dados Fabric |
| `infra/` | Infra Docker / AKS |
| `app/scripts/` | Scripts / ops |
| `.cursor/` | Surface sync + Doutrina LLM |

## Enforcement

- Gates: `make app-lint`, `make app-validate`, `make app-test`, `make app-security`
- Orquestrador: `app/scripts/operations/clean_workspace.py`
- Commitlint: `linters/commitlint.config.mjs` (escopo `llm` para superficie de agentes)
