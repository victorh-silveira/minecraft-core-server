# Pre-commit / gates MCS

## Matriz (crash-first)

Ordem unica de stages: **lint → seguranca → testes → validate → build**.

| Area | Stages |
|------|--------|
| python / docker / kubernetes / terraform / github / scripts | lint, security, test, validate, build |
| stack | clean (ultimo) |
| commit | Commit \| Lint **primeiro** (pre-commit + commit-msg) |

SSOT: `python app/scripts/operations/clean_workspace.py --area X --stage Y`

Nomes dos hooks = nomes dos steps CI: `Python | Lint`, `Docker | Seguranca`, etc.

## Passos

1. Ler o hook FAIL (nome `Area | Stage`)
2. Reproduzir no WSL na mesma ordem: `make app-lint` / `app-security` / `app-test` / `app-validate` / `app-build`
3. Python: Ruff; Bandit/pip-audit/Gitleaks; pytest; mypy; compileall
4. TF/Docker/K8s/GitHub/Scripts: `app/scripts/bash/gates-*.sh`
5. Commitlint: tipo+escopo; assunto PT-BR; corpo nao vazio — falha antes dos gates pesados quando ha `COMMIT_EDITMSG`
6. Reexecutar `make app-pre-commit-run` ate verde

## Docs

`docs/engineering-python.md`, `AGENTS.md`, `.github/README.md`
