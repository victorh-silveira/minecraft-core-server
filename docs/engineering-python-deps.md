# Dependencias Python

SSOT de dependencias deste monorepo.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| [`app/requirements.txt`](../app/requirements.txt) | Runtime (`requests`) |
| [`app/requirements-dev.txt`](../app/requirements-dev.txt) | Dev/QA (Ruff, mypy, pytest, bandit, …) |
| [`app/pyproject.toml`](../app/pyproject.toml) | Metadados, Ruff, mypy, coverage, bandit, vulture; `project.optional-dependencies.dev` alinhado ao requirements-dev |

## Regras

- Toda dependencia de runtime entra em `requirements.txt` **e** em `[project].dependencies` do `pyproject.toml`.
- Toda ferramenta de QA entra em `requirements-dev.txt` **e** em `[project.optional-dependencies].dev`.
- Nao duplicar pins conflitantes; preferir a mesma faixa minima nos tres lugares.
- `pip-audit` roda sobre `requirements.txt` no stage security.
- Instalar via `make app-install` / `make app-setup` (venv na raiz + WSL).

## Ao adicionar pacote

1. Justificar o uso (adapter, teste ou gate).
2. Atualizar requirements + pyproject.
3. Rodar `make app-security`.
4. Se o fluxo do agente mudar, alinhar rule/skill `mcs-python-deps`.

Skill: `mcs-python-deps`.
