#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/gates-terraform.sh $*"
  exit 1
fi

TERRAFORM_VERSION="${TERRAFORM_VERSION:-$(tr -d '[:space:]' < "${REPO_ROOT}/linters/.terraform-version" 2>/dev/null || true)}"
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.15.4}"
TFLINT_VERSION="${TFLINT_VERSION:-v0.54.0}"
TFSEC_VERSION="${TFSEC_VERSION:-v1.28.11}"
TOOLS_DIR="${REPO_ROOT}/.tools"

terraform_bin() {
  if [[ -n "${TERRAFORM_BIN:-}" && -x "${TERRAFORM_BIN}" ]]; then
    echo "${TERRAFORM_BIN}"
    return
  fi
  local cache="${TOOLS_DIR}/terraform/${TERRAFORM_VERSION}"
  local bin="${cache}/terraform"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  if command -v terraform &>/dev/null; then
    command -v terraform
    return
  fi
  mkdir -p "${cache}"
  local os arch zip url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) echo "SO nao suportado"; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  zip="terraform_${TERRAFORM_VERSION}_${os}_${arch}.zip"
  url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${zip}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${zip}"
  unzip -o -q "${TOOLS_DIR}/${zip}" -d "${cache}"
  rm -f "${TOOLS_DIR}/${zip}"
  chmod +x "${bin}"
  echo "${bin}"
}

tflint_bin() {
  if command -v tflint &>/dev/null; then
    command -v tflint
    return
  fi
  local cache="${TOOLS_DIR}/tflint/${TFLINT_VERSION}"
  local bin="${cache}/tflint"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local os arch asset url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) echo "SO nao suportado"; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  asset="tflint_${os}_${arch}.zip"
  url="https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${asset}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${asset}"
  unzip -o -q "${TOOLS_DIR}/${asset}" -d "${cache}"
  rm -f "${TOOLS_DIR}/${asset}"
  chmod +x "${bin}"
  echo "${bin}"
}

tfsec_bin() {
  if command -v tfsec &>/dev/null; then
    command -v tfsec
    return
  fi
  local cache="${TOOLS_DIR}/tfsec/${TFSEC_VERSION}"
  local bin="${cache}/tfsec"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local os arch asset url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) echo "SO nao suportado"; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  asset="tfsec-${os}-${arch}"
  url="https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/${asset}"
  curl -fsSL "${url}" -o "${bin}"
  chmod +x "${bin}"
  echo "${bin}"
}

cmd_fmt() {
  local tf
  tf="$(terraform_bin)"
  echo ">>> terraform fmt"
  "${tf}" fmt -recursive infra/terraform/
}

cmd_lint() {
  local tf tflint config
  tf="$(terraform_bin)"
  tflint="$(tflint_bin)"
  config="$(pwd)/linters/.tflint.hcl"
  echo ">>> terraform fmt -check"
  "${tf}" fmt -check -recursive infra/terraform/
  echo ">>> tflint --init"
  "${tflint}" --init --config="${config}"
  echo ">>> tflint live/prod"
  (cd infra/terraform/live/prod && "${tflint}" --config="${config}" --minimum-failure-severity=error)
}

cmd_validate() {
  local tf
  tf="$(terraform_bin)"
  echo ">>> terraform validate"
  (cd infra/terraform/live/prod && "${tf}" init -backend=false -input=false && "${tf}" validate)
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git checkout -- infra/terraform/live/prod/.terraform.lock.hcl 2>/dev/null || true
  fi
}

cmd_test() {
  local tf
  tf="$(terraform_bin)"
  echo ">>> terraform test (modulo label)"
  (cd infra/terraform/modules/label && "${tf}" init -backend=false -input=false && "${tf}" test)
}

cmd_security() {
  local tfsec
  tfsec="$(tfsec_bin)"
  echo ">>> tfsec"
  "${tfsec}" --config-file linters/.tfsec.yml .
}

cmd_build() {
  local tf
  tf="$(terraform_bin)"
  echo ">>> terraform init (build providers)"
  (cd infra/terraform/live/prod && "${tf}" init -backend=false -input=false)
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git checkout -- infra/terraform/live/prod/.terraform.lock.hcl 2>/dev/null || true
  fi
  echo "[OK] terraform init"
}

main() {
  case "${1:-}" in
    fmt) cmd_fmt ;;
    lint) cmd_lint ;;
    security) cmd_security ;;
    test) cmd_test ;;
    validate) cmd_validate ;;
    build) cmd_build ;;
    all)
      cmd_lint
      cmd_security
      cmd_test
      cmd_validate
      cmd_build
      ;;
    *)
      echo "Uso: $0 fmt|lint|security|test|validate|build|all"
      exit 1
      ;;
  esac
}

main "$@"
