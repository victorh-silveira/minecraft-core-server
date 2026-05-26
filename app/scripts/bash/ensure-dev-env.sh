#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${REPO_ROOT:-}" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

VENV="${REPO_ROOT}/.venv"
PYTHON="${VENV}/bin/python"
PIP="${VENV}/bin/pip"

if [[ ! -x "${PYTHON}" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 nao encontrado. Instale Python 3.13+ no WSL." >&2
    exit 1
  fi
  python3 -m venv "${VENV}"
fi

REQ_STAMP="${VENV}/.requirements.sha256"
REQ_HASH="$(cat "${REPO_ROOT}/app/requirements.txt" "${REPO_ROOT}/app/requirements-dev.txt" | sha256sum | awk '{print $1}')"

if [[ ! -f "${REQ_STAMP}" ]] || [[ "$(cat "${REQ_STAMP}")" != "${REQ_HASH}" ]]; then
  "${PIP}" install -q --upgrade pip
  "${PIP}" install -q \
    -r "${REPO_ROOT}/app/requirements.txt" \
    -r "${REPO_ROOT}/app/requirements-dev.txt"
  printf '%s' "${REQ_HASH}" > "${REQ_STAMP}"
fi

export REPO_ROOT
export VENV_PYTHON="${PYTHON}"
export PYTHONPATH="${REPO_ROOT}/app/src${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="${VENV}/bin:${PATH}"
