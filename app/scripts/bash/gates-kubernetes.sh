#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/gates-kubernetes.sh $*"
  exit 1
fi

OVERLAY="infra/kubernetes/overlays/prod"
K8S_ROOT="infra/kubernetes"
TOOLS_DIR="${REPO_ROOT}/.tools"
KUBECONFORM_VERSION="${KUBECONFORM_VERSION:-0.6.7}"
KUSTOMIZE_VERSION="${KUSTOMIZE_VERSION:-v5.4.3}"
TRIVY_VERSION="${TRIVY_VERSION:-0.58.2}"

kustomize_bin() {
  if command -v kubectl >/dev/null 2>&1; then
    echo "kubectl"
    return
  fi
  local cache="${TOOLS_DIR}/kustomize/${KUSTOMIZE_VERSION}"
  local bin="${cache}/kustomize"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local os arch url
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
  url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${os}_${arch}.tar.gz"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/kustomize.tgz"
  tar -xzf "${TOOLS_DIR}/kustomize.tgz" -C "${cache}"
  rm -f "${TOOLS_DIR}/kustomize.tgz"
  chmod +x "${bin}"
  echo "${bin}"
}

render_overlay() {
  local bin
  bin="$(kustomize_bin)"
  if [[ "${bin}" == "kubectl" ]]; then
    kubectl kustomize "${OVERLAY}"
  else
    "${bin}" build "${OVERLAY}"
  fi
}

kubeconform_bin() {
  if command -v kubeconform >/dev/null 2>&1; then
    command -v kubeconform
    return
  fi
  local cache="${TOOLS_DIR}/kubeconform/${KUBECONFORM_VERSION}"
  local bin="${cache}/kubeconform"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local arch asset
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  asset="kubeconform-linux-${arch}.tar.gz"
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/${asset}" -o "${TOOLS_DIR}/${asset}"
  tar -xzf "${TOOLS_DIR}/${asset}" -C "${cache}" kubeconform
  rm -f "${TOOLS_DIR}/${asset}"
  chmod +x "${bin}"
  echo "${bin}"
}

trivy_bin() {
  if command -v trivy &>/dev/null; then
    command -v trivy
    return
  fi
  local cache="${TOOLS_DIR}/trivy/${TRIVY_VERSION}"
  local bin="${cache}/trivy"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  local os arch asset url
  case "$(uname -s)" in
    Linux) os=Linux ;;
    Darwin) os=macOS ;;
    *) echo "SO nao suportado"; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=64bit ;;
    aarch64|arm64) arch=ARM64 ;;
    *) echo "Arquitetura nao suportada"; exit 1 ;;
  esac
  asset="trivy_${TRIVY_VERSION}_${os}-${arch}.tar.gz"
  url="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${asset}"
  curl -fsSL "${url}" -o "${TOOLS_DIR}/${asset}"
  tar -xzf "${TOOLS_DIR}/${asset}" -C "${cache}" trivy
  rm -f "${TOOLS_DIR}/${asset}"
  chmod +x "${bin}"
  echo "${bin}"
}

cmd_lint() {
  echo ">>> YAML sintaxe infra/kubernetes"
  python - <<'PY'
from pathlib import Path
import sys
import yaml

errors = []
root = Path("infra/kubernetes")
for path in root.rglob("*"):
    if not path.is_file() or path.suffix not in {".yml", ".yaml"}:
        continue
    if path.name.endswith(".example"):
        continue
    try:
        list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
    except yaml.YAMLError as exc:
        errors.append(f"{path}: {exc}")
if errors:
    print("\n".join(errors))
    sys.exit(1)
print("[OK] YAML kubernetes valido")
PY
}

cmd_validate() {
  local kc
  kc="$(kubeconform_bin)"
  echo ">>> kustomize + kubeconform"
  render_overlay | "${kc}" -kubernetes-version 1.34.0 -summary -ignore-missing-schemas
}

cmd_test() {
  echo ">>> k8s smoke estatico"
  local rendered
  rendered="$(render_overlay)"
  echo "${rendered}" | grep -q "kind: StatefulSet" || { echo "[FAIL] StatefulSet ausente"; exit 1; }
  echo "${rendered}" | grep -q "kind: Service" || { echo "[FAIL] Service ausente"; exit 1; }
  echo "${rendered}" | grep -q "mc-server" || { echo "[FAIL] recurso mc-server ausente"; exit 1; }
  echo "[OK] smoke k8s estatico"
}

cmd_security() {
  local trivy rendered
  trivy="$(trivy_bin)"
  rendered="$(mktemp)"
  echo ">>> trivy config (overlay renderizado)"
  render_overlay > "${rendered}"
  "${trivy}" config --exit-code 1 --severity HIGH,CRITICAL --ignorefile linters/.trivyignore "${rendered}"
  rm -f "${rendered}"
}

main() {
  case "${1:-}" in
    lint) cmd_lint ;;
    validate) cmd_validate ;;
    test) cmd_test ;;
    security) cmd_security ;;
    *)
      echo "Uso: $0 lint|validate|test|security"
      exit 1
      ;;
  esac
}

main "$@"
