# Engenharia Python

Qualidade, testes e entrypoints da aplicacao.

## Matriz de qualidade

Orquestrador: [`app/scripts/operations/clean_workspace.py`](../app/scripts/operations/clean_workspace.py)

```bash
python app/scripts/operations/clean_workspace.py --area <area> --stage <stage>
```

| Area | Lint | Validate | Testes | Seguranca |
|------|------|----------|--------|-----------|
| python | Ruff, vulture, pylint dupe, ≤300 linhas, imports | mypy strict | pytest + cov 100% branch | Bandit + pip-audit |
| terraform | fmt-check + tflint | terraform validate | terraform test (modulo label) | tfsec |
| docker | Hadolint | compose config | smoke estatico | Trivy config |
| kubernetes | YAML sintaxe | kustomize + kubeconform | smoke estatico | Trivy config |
| json | schema do manifesto | parse JSON | — | — |
| clean | limpeza full-stack (caches, `.tools`, `.terraform`, logs) | | | |

Commitlint: hook `commit-msg`. Actionlint: somente CI (job Workflows).

## Makefile

| Alvo | Efeito |
|------|--------|
| `app-setup` | deps + hooks |
| `app-install` | `.venv` e requirements |
| `app-run` | sync de mods (`run.py`) |
| `app-lint` | `--area all --stage lint` |
| `app-validate` | `--area all --stage validate` |
| `app-test` | `--area all --stage test` |
| `app-security` | `--area all --stage security` |
| `app-clean` | limpeza full-stack |
| `app-pre-commit` | instala hooks |
| `app-pre-commit-run` | matriz completa via pre-commit |

## Entrypoints

```bash
python run.py
cd app && python -m presentation.cli
make docker-sync-mods
```

## Testes Python

| Camada | Onde | Estrategia |
|--------|------|------------|
| domain | `tests/unit/domain/` | entidades e services |
| application | `tests/unit/application/` | use case com fakes dos ports |
| infrastructure | `tests/unit/infrastructure/` | adapters com HTTP fake |
| presentation | `tests/unit/presentation/` | CLI, exit code, eventos |
| integracao | `tests/integration/infrastructure/` | transporte HTTP mock (Modrinth) |

`SYNC_DISABLE_DOTENV=1` em `app/tests/conftest.py`.

## Commits

Formato `tipo(escopo): assunto` com corpo obrigatorio. Config: [`linters/commitlint.config.mjs`](../linters/commitlint.config.mjs).
