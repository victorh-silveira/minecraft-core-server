# Engenharia Python

Qualidade, testes e entrypoints da aplicacao.

## Stack

| Gate | Ferramenta |
|------|------------|
| Lint / format | Ruff |
| Tipos | mypy `--strict` |
| Dead code | vulture |
| Teste + cobertura | pytest + coverage.py fail-under 100 (branch) |
| Seguranca | bandit + pip-audit |
| Hooks | pre-commit + commitlint |
| Orquestrador | `app/scripts/operations/clean_workspace.py` |

Configuracao: [`app/pyproject.toml`](../app/pyproject.toml).

## Makefile

| Alvo | Efeito |
|------|--------|
| `app-setup` | deps + hooks |
| `app-install` | `.venv` e requirements |
| `app-run` | sync de mods (`run.py`) |
| `app-lint` | ruff, mypy, vulture, limite 300 linhas, imports hexagonais |
| `app-test` | pytest + cobertura 100% |
| `app-security` | bandit + pip-audit |
| `app-clean` | caches |
| `app-pre-commit` | instala hooks |
| `app-pre-commit-run` | `pre-commit run --all-files` |

Aliases historicos: `ci-test` → `app-test`, `clean` → `app-clean`, `dev-deps` → `app-install`, `docker-sync-mods` → `app-run`, `pre-commit-install` → `app-pre-commit`.

## Entrypoints

```bash
python run.py
cd app && python -m presentation.cli
make docker-sync-mods
```

`run.py` na raiz adiciona `app/src` ao `sys.path` e chama `presentation.cli.main`.

## Testes

| Camada | Onde | Estrategia |
|--------|------|------------|
| domain | `tests/unit/domain/` | entidades e services |
| application | `tests/unit/application/` | use case com fakes dos ports |
| infrastructure | `tests/unit/infrastructure/` | adapters com HTTP fake |
| presentation | `tests/unit/presentation/` | CLI, exit code, eventos |
| integracao | `tests/integration/infrastructure/` | transporte HTTP mock (Modrinth) |

Testes definem `SYNC_DISABLE_DOTENV=1` em `app/tests/conftest.py`.

## Commits

Formato `tipo(escopo): assunto` com corpo obrigatorio. Config: [`linters/commitlint.config.mjs`](../linters/commitlint.config.mjs). Hook: [`linters/git-hooks/commit-msg`](../linters/git-hooks/commit-msg).
