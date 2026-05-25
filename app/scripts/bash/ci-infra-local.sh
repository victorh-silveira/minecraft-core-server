#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/ci-infra-local.sh $*"
  exit 1
fi

TERRAFORM_VERSION="${TERRAFORM_VERSION:-$(tr -d '[:space:]' < "${REPO_ROOT}/linters/.terraform-version")}"
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
  local bin=""
  case "$(uname -s)" in
    Linux|Darwin) bin="${cache}/terraform" ;;
    *)
      echo "SO nao suportado para bootstrap do Terraform"
      exit 1
      ;;
  esac
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  if command -v terraform &>/dev/null; then
    command -v terraform
    return
  fi
  bootstrap_terraform "${cache}" "${bin}"
  echo "${bin}"
}

bootstrap_terraform() {
  local cache="$1"
  local bin="$2"
  mkdir -p "${cache}"
  local os arch zip url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *)
      echo "SO nao suportado"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *)
      echo "Arquitetura nao suportada"
      exit 1
      ;;
  esac
  zip="terraform_${TERRAFORM_VERSION}_${os}_${arch}.zip"
  url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${zip}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${zip}"
  unzip -o -q "${TOOLS_DIR}/${zip}" -d "${cache}"
  rm -f "${TOOLS_DIR}/${zip}"
  chmod +x "${bin}"
}

tflint_bin() {
  if command -v tflint &>/dev/null; then
    command -v tflint
    return
  fi
  local cache="${TOOLS_DIR}/tflint/${TFLINT_VERSION}"
  local bin=""
  case "$(uname -s)" in
    Linux|Darwin) bin="${cache}/tflint" ;;
    *)
      echo "SO nao suportado"
      exit 1
      ;;
  esac
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  bootstrap_tflint "${cache}" "${bin}"
  echo "${bin}"
}

bootstrap_tflint() {
  local cache="$1"
  local bin="$2"
  mkdir -p "${cache}"
  local os arch asset url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *)
      echo "SO nao suportado"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *)
      echo "Arquitetura nao suportada"
      exit 1
      ;;
  esac
  asset="tflint_${os}_${arch}.zip"
  url="https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${asset}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${asset}"
  unzip -o -q "${TOOLS_DIR}/${asset}" -d "${cache}"
  rm -f "${TOOLS_DIR}/${asset}"
  chmod +x "${bin}"
}

tfsec_bin() {
  if command -v tfsec &>/dev/null; then
    command -v tfsec
    return
  fi
  local cache="${TOOLS_DIR}/tfsec/${TFSEC_VERSION}"
  local bin=""
  case "$(uname -s)" in
    Linux|Darwin) bin="${cache}/tfsec" ;;
    *)
      echo "SO nao suportado"
      exit 1
      ;;
  esac
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  bootstrap_tfsec "${cache}" "${bin}"
  echo "${bin}"
}

bootstrap_tfsec() {
  local cache="$1"
  local bin="$2"
  mkdir -p "${cache}"
  local os arch asset url
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *)
      echo "SO nao suportado"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *)
      echo "Arquitetura nao suportada"
      exit 1
      ;;
  esac
  asset="tfsec-${os}-${arch}"
  url="https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/${asset}"
  curl -fsSL "${url}" -o "${bin}"
  chmod +x "${bin}"
}

cmd_fmt() {
  local tf ver
  tf="$(terraform_bin)"
  ver="$("${tf}" version | head -n1)"
  echo ">>> terraform fmt (${ver})"
  "${tf}" fmt -recursive infra/terraform/
}

cmd_lint() {
  local tf
  tf="$(terraform_bin)"
  echo ">>> terraform fmt -check"
  "${tf}" fmt -check -recursive infra/terraform/
  if command -v hadolint &>/dev/null; then
    echo ">>> hadolint"
    hadolint --ignore=DL3006 infra/docker/Dockerfile
  else
    echo ">>> hadolint ausente; pulando"
  fi
  if command -v actionlint &>/dev/null; then
    echo ">>> actionlint"
    actionlint
  else
    echo ">>> actionlint ausente; pulando"
  fi
  echo ">>> validar YAML"
  python -m pip install --quiet pyyaml
  python - <<'PY'
import sys
from pathlib import Path
import yaml

errors = []
for path in Path(".").rglob("*"):
    if not path.is_file():
        continue
    if path.suffix not in {".yml", ".yaml"}:
        continue
    parts = set(path.parts)
    if ".github" not in parts and "infra" not in parts:
        continue
    if ".github" in parts and "templates" in parts:
        continue
    try:
        list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
    except yaml.YAMLError as exc:
        errors.append(f"{path}: {exc}")
if errors:
    print("\n".join(errors))
    sys.exit(1)
PY
}

cmd_validate() {
  local tf tflint tfsec config
  tf="$(terraform_bin)"
  tflint="$(tflint_bin)"
  tfsec="$(tfsec_bin)"
  config="$(pwd)/linters/.tflint.hcl"
  echo ">>> tflint --init"
  "${tflint}" --init --config="${config}"
  echo ">>> tflint live/prod"
  (cd infra/terraform/live/prod && "${tflint}" --config="${config}" --minimum-failure-severity=error)
  echo ">>> tfsec"
  "${tfsec}" --config-file linters/.tfsec.yml .
  echo ">>> terraform validate"
  (cd infra/terraform/live/prod && "${tf}" init -backend=false -input=false && "${tf}" validate)
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git checkout -- infra/terraform/live/prod/.terraform.lock.hcl 2>/dev/null || true
  fi
}

main() {
  case "${1:-all}" in
    fmt) cmd_fmt ;;
    lint) cmd_lint ;;
    validate) cmd_validate ;;
    all)
      cmd_fmt
      cmd_lint
      cmd_validate
      ;;
    *)
      echo "Uso: $0 fmt|lint|validate|all"
      exit 1
      ;;
  esac
}

main "$@"
