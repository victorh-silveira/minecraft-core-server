---
name: mcs-python-deps
description: >-
  Adiciona ou alinha dependencias Python (requirements.txt, requirements-dev.txt,
  pyproject.toml) e roda pip-audit. Use when adding packages, upgrading Ruff/mypy/
  pytest, or when the user mentions requirements or python deps.
---

# Python deps

## Passos

1. Decidir se e runtime ou dev
2. Atualizar `app/requirements.txt` e/ou `requirements-dev.txt`
3. Espelhar em `app/pyproject.toml` (`dependencies` / `optional-dependencies.dev`)
4. `make app-install` + `make app-security`
5. Se o fluxo do agente mudou, alinhar rule `mcs-python-deps`

## Docs

`docs/engineering-python-deps.md`
