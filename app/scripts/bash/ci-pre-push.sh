#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

bash app/scripts/bash/ci-infra-local.sh all
cd app
python -m ruff format --config pyproject.toml src/infrastructure/mods tests
python -m ruff check --fix --config pyproject.toml src/infrastructure/mods tests
cd "${REPO_ROOT}"
python app/scripts/python/clean_workspace.py --stage lint

echo "ci-pre-push: fmt, lint-infra, validate-infra e lint Python concluidos"
