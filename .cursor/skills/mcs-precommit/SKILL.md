---
name: mcs-precommit
description: >-
  Diagnostica e corrige falhas de qualidade do minecraft-core-server (Ruff, mypy
  strict, Vulture, limite 300 linhas, imports hexagonais, pytest cobertura 100%
  branch, Bandit, pip-audit, commitlint PT-BR). Use when pre-commit fails,
  coverage is below 100%, a file exceeds 300 lines, or the user mentions
  clean_workspace, app-lint, app-test, app-security, or commitlint.
---

# Pre-commit / gates MCS

## Passos

1. Ler o trecho FAIL (lint / test / security / commitlint)
2. Lint: `make app-lint` no WSL — Ruff, mypy, vulture, 300 linhas, imports
3. Test: `make app-test` — cobrir misses reportados; fakes nos ports
4. Security: corrigir Bandit real; nao `# nosec` sem justificativa forte; `pip-audit`
5. Commitlint: tipo+escopo validos; assunto PT-BR; corpo nao vazio
6. Reexecutar gates ate verde

## Docs

`docs/engineering-python.md`, `AGENTS.md`, `docs/agent-coverage.md`
