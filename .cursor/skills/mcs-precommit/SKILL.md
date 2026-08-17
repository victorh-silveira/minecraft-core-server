---
name: mcs-precommit
description: >-
  Diagnostica e corrige falhas de qualidade do minecraft-core-server (matriz
  Lint/Validate/Testes/Seguranca por area, clean_workspace, commitlint PT-BR).
  Use when pre-commit fails, coverage is below 100%, a file exceeds 300 lines,
  or the user mentions clean_workspace, app-lint, app-test, app-security, or
  commitlint.
---

# Pre-commit / gates MCS

## Matriz

| Area | Stages |
|------|--------|
| python / terraform / docker / kubernetes | lint, validate, test, security |
| json | lint, validate |
| stack | clean |
| commit | commitlint (commit-msg) |

SSOT: `python app/scripts/operations/clean_workspace.py --area X --stage Y`

## Passos

1. Ler o hook FAIL (nome `Area | Stage`)
2. Reproduzir: `make app-lint` / `app-validate` / `app-test` / `app-security` no WSL
3. Python: Ruff/mypy/vulture/estrutura; testes com fakes; Bandit/pip-audit
4. TF/Docker/K8s: scripts `app/scripts/bash/gates-*.sh`
5. Commitlint: tipo+escopo; assunto PT-BR; corpo nao vazio
6. Reexecutar `make app-pre-commit-run` ate verde

## Docs

`docs/engineering-python.md`, `AGENTS.md`, `.github/README.md`
