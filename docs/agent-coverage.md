# Matriz de Cobertura do Agente de IA (100%)

Cada superficie arquitetural, funcional e operacional do servidor Minecraft possui cobertura formal composta por **documentacao tecnica + regra de governanca + habilidade operacional** (ou indicacao justificada de dispensa).

Ponto de entrada canônico do repositorio: [`AGENTS.md`](../AGENTS.md).
As regras e habilidades residem no harness canônico em [`.agents/`](../.agents/) e sao **estritamente versionadas** no Git.

## 1. Matriz de Cobertura de Superficies

| Superficie | Doc | Rule (`.agents/rules/`) | Skill (`.agents/skills/`) |
|---|---|---|---|
| Doutrina LLM | [llm-engineering-doctrine.md](llm-engineering-doctrine.md) | `mcs-llm-doctrine.mdc` | `mcs-surface-sync` |
| Engenharia / QA | [engineering-python.md](engineering-python.md) | `mcs-engineering.mdc` + `mcs-testing.mdc` | `mcs-precommit` |
| Hexagonal / Dominio | [arquitetura.md](arquitetura.md) + [structure.md](structure.md) | `mcs-hexagonal.mdc` + `mcs-domain-pure.mdc` | `mcs-hexagonal-tdd` |
| Testes / TDD | [engineering-python.md](engineering-python.md) | `mcs-testing.mdc` | `mcs-hexagonal-tdd` + `mcs-precommit` |
| Logging Semantico | [engineering-logging.md](engineering-logging.md) | `mcs-logging.mdc` | `mcs-logging-audit` |
| Sincronizacao de Mods | [arquitetura.md](arquitetura.md) + [configuration.md](configuration.md) | `mcs-mods-sync.mdc` | `mcs-mods-sync` |
| Runtime / Dados Forge | [structure.md](structure.md) + [infra-docker.md](infra-docker.md) | `mcs-runtime-data.mdc` | `mcs-infra-stack` |
| Infra Docker / AKS | [infra-docker.md](infra-docker.md) + [architecture.md](architecture.md) + [azure.md](azure.md) | `mcs-infra.mdc` | `mcs-infra-stack` + `mcs-ops-runbook` |
| Scripts e Operacoes | [operations.md](operations.md) + [structure.md](structure.md) | `mcs-scripts.mdc` | `mcs-ops-runbook` |
| Dependencias Python | [engineering-python-deps.md](engineering-python-deps.md) | `mcs-python-deps.mdc` | `mcs-python-deps` |
| Higiene de Repositorio | [engineering-repo-hygiene.md](engineering-repo-hygiene.md) | `mcs-repo-hygiene.mdc` | `mcs-repo-hygiene` |
| Fechamento e Superficie | [engineering-surface-sync.md](engineering-surface-sync.md) | `mcs-surface-sync.mdc` | `mcs-surface-sync` |
| Contrato e Scaffold | [prompt-model.md](../prompt-model.md) | `mcs-engineering.mdc` | `mcs-surface-sync` |
| Barra Senior (SW + Cloud Ops) | [engineering-senior-bar.md](engineering-senior-bar.md) | `mcs-senior-posture.mdc` + `mcs-senior-python.mdc` + `mcs-senior-docker.mdc` + `mcs-senior-cloud.mdc` + `mcs-senior-cicd.mdc` | `mcs-senior-software` + `mcs-senior-cloud-ops` + `mcs-senior-review` |

## 2. Mapeamento de Diretorios DDD ↔ Superficie

| Diretorio no Repositorio | Superficie Correspondente na Matriz |
|---|---|
| `app/src/domain/` | Hexagonal / Dominio |
| `app/src/application/` | Hexagonal / Dominio |
| `app/src/infrastructure/` | Sincronizacao de Mods + Logging Semantico |
| `app/src/presentation/` | Sincronizacao de Mods + Logging Semantico |
| `app/runtime/` | Runtime / Dados Forge |
| `infra/` | Infra Docker / AKS |
| `app/scripts/` | Scripts e Operacoes |
| `.agents/` | Fechamento e Superficie + Doutrina LLM + Barra Senior |
| `.agents/agents/` | Barra Senior (Subagentes Especializados) |
| `.github/` | Barra Senior (CI/CD) |

## 3. Mecanismo de Garantia e Enforcement

1. Validacao Automatizada por Teste: O teste de integridade em `app/tests/unit/infrastructure/test_agent_coverage_matrix.py` analisa este documento a cada execucao do Pytest, garantindo que nenhum documento, regra ou habilidade fique orfao ou deixe de existir.
2. Gates de Qualidade: Comandos `make app-lint`, `make app-validate`, `make app-security` e `make app-test`.
3. Orquestrador Central: Execucao unificada via `app/scripts/operations/clean_workspace.py`.
4. Rastreamento Git: Escopo de commitlint `llm` reservado exclusivamente para alteracoes no harness de agentes.
