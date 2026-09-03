# Engenharia Python

Qualidade, testes e entrypoints da aplicacao.

## Matriz de qualidade

Orquestrador: [`app/scripts/operations/clean_workspace.py`](../app/scripts/operations/clean_workspace.py)

```bash
python app/scripts/operations/clean_workspace.py --area <area> --stage <stage>
```

| Area | Lint | Seguranca | Testes | Validate | Build |
|------|------|-----------|--------|----------|-------|
| python | Ruff, vulture, hexagonal, manifesto | Bandit, pip-audit, hash/https | pytest + ids | mypy + parse JSON | compileall + sha |
| docker | Hadolint | Trivy config | smoke estatico | compose config | compose build (imagem no CI) |
| kubernetes | YAML sintaxe | Trivy config | smoke estatico | kustomize + kubeconform | kustomize build |
| terraform | fmt-check + tflint | tfsec | terraform test (modulo label) | terraform validate | terraform init |
| github | parse workflows/hooks | sem credencial estatica | jobs da matriz CI | actionlint | actions locais existem |
| scripts | bash -n | sem credencial em .sh | shellcheck | Makefile dry-run | shebang bash |
| clean | limpeza full-stack (caches, `.tools`, `.terraform`, logs) | | | | |

Commitlint: primeiro no pre-commit (`Commit | Lint`) e no hook `commit-msg`. Actionlint: stage validate da area github. Manifesto JSON entra na area python.

## Makefile

| Alvo | Efeito |
|------|--------|
| `app-setup` | deps + hooks |
| `app-install` | `.venv` e requirements |
| `app-run` | sync de mods (`run.py`) |
| `app-lint` | `--area all --stage lint` |
| `app-security` | `--area all --stage security` |
| `app-test` | `--area all --stage test` |
| `app-validate` | `--area all --stage validate` |
| `app-build` | `--area all --stage build` |
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
