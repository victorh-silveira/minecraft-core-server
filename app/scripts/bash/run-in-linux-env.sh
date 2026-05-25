#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

is_wsl_linux() {
  grep -qi microsoft /proc/version 2>/dev/null
}

is_windows_host() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

repo_path_for_wsl() {
  if command -v wslpath &>/dev/null; then
    wslpath -u "${REPO_ROOT}"
    return
  fi
  if command -v wsl.exe &>/dev/null; then
    wsl.exe wslpath -u "$(cygpath -w "${REPO_ROOT}" 2>/dev/null || echo "${REPO_ROOT}")"
    return
  fi
  echo "wslpath ou wsl.exe nao encontrado. Execute este comando dentro do WSL." >&2
  exit 1
}

run_wsl() {
  local repo_linux cmd
  repo_linux="$(repo_path_for_wsl)"
  cmd="$(printf '%q ' "$@")"
  exec wsl.exe bash -lc "cd $(printf '%q' "${repo_linux}") && ${cmd}"
}

if is_wsl_linux || ! is_windows_host; then
  cd "${REPO_ROOT}"
  exec "$@"
fi

run_wsl "$@"
