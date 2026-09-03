#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/gates-scripts.sh $*"
  exit 1
fi

TOOLS_DIR="${REPO_ROOT}/.tools"
SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-v0.10.0}"

list_scripts() {
  find app/scripts linters/git-hooks -type f -name '*.sh' | sort
}

shellcheck_bin() {
  if command -v shellcheck &>/dev/null; then
    command -v shellcheck
    return
  fi
  local cache="${TOOLS_DIR}/shellcheck/${SHELLCHECK_VERSION}"
  local bin="${cache}/shellcheck"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local os arch url tarball
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) echo "SO nao suportado"; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  tarball="shellcheck-${SHELLCHECK_VERSION}.${os}.${arch}.tar.xz"
  url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/${tarball}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${tarball}"
  tar -xJf "${TOOLS_DIR}/${tarball}" -C "${cache}" --strip-components=1
  rm -f "${TOOLS_DIR}/${tarball}"
  chmod +x "${bin}"
  echo "${bin}"
}

cmd_lint() {
  echo ">>> bash -n (sintaxe)"
  local failed=0
  local file
  while IFS= read -r file; do
    if ! bash -n "${file}"; then
      echo "[FAIL] ${file}"
      failed=1
    fi
  done < <(list_scripts)
  if [[ "${failed}" -ne 0 ]]; then
    exit 1
  fi
  echo "[OK] sintaxe bash"
}

cmd_security() {
  echo ">>> scripts seguranca (credencial estatica)"
  if grep -R -nE 'AZURE_CREDENTIALS=|ARM_CLIENT_SECRET=|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY' \
    app/scripts linters/git-hooks --include='*.sh' --exclude='gates-scripts.sh'; then
    echo "[ERRO] segredo ou credencial estatica em script"
    exit 1
  fi
  echo "[OK] scripts sem credencial estatica"
}

cmd_test() {
  local sc
  sc="$(shellcheck_bin)"
  echo ">>> shellcheck"
  local files
  mapfile -t files < <(list_scripts)
  "${sc}" --severity=error --exclude=SC1090,SC1091,SC2016 "${files[@]}"
  echo "[OK] shellcheck"
}

cmd_validate() {
  echo ">>> Makefile dry-run"
  make -n help >/dev/null
  echo "[OK] Makefile parseavel"
}

cmd_build() {
  echo ">>> shebang bash"
  local file
  while IFS= read -r file; do
    if ! head -n 1 "${file}" | grep -qE '^#!/(usr/)?bin/(env bash|bash)'; then
      echo "[ERRO] shebang bash ausente: ${file}"
      exit 1
    fi
  done < <(list_scripts)
  echo "[OK] shebang bash nos scripts"
}

main() {
  case "${1:-}" in
    lint) cmd_lint ;;
    security) cmd_security ;;
    test) cmd_test ;;
    validate) cmd_validate ;;
    build) cmd_build ;;
    *)
      echo "Uso: $0 lint|security|test|validate|build"
      exit 1
      ;;
  esac
}

main "$@"
