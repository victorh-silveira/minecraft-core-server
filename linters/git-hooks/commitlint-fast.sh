#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MSG="${1:-}"
if [[ -z "${MSG}" ]]; then
  MSG="${ROOT}/.git/COMMIT_EDITMSG"
fi
if [[ ! -f "${MSG}" ]]; then
  echo "[OK] Commit | Lint adiado (sem COMMIT_EDITMSG)"
  exit 0
fi
if ! grep -qE '^[^#[:space:]]' "${MSG}"; then
  echo "[OK] Commit | Lint adiado (mensagem vazia; commit-msg valida depois)"
  exit 0
fi
npx --yes -p @commitlint/cli -p @commitlint/config-conventional \
  commitlint --config "${ROOT}/linters/commitlint.config.mjs" --edit "${MSG}"
