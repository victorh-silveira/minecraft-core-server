#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/gates-docker.sh $*"
  exit 1
fi

COMPOSE_FILE="infra/docker/docker-compose.yml"
DOCKERFILE="infra/docker/Dockerfile"
ENV_FILE="infra/docker/.env"
TOOLS_DIR="${REPO_ROOT}/.tools"
TRIVY_VERSION="${TRIVY_VERSION:-0.74.0}"

synthetic_env() {
  if [[ -f "${REPO_ROOT}/${ENV_FILE}" ]]; then
    echo ">>> reutilizando ${ENV_FILE} existente"
    return 0
  fi
  cat > "${REPO_ROOT}/${ENV_FILE}" << 'EOF'
MINECRAFT_VERSION=1.20.6
SERVER_TYPE=FABRIC
MEMORY_LIMIT=2G
EULA_ACCEPTED=TRUE
GAME_PORT=25565
RCON_PORT=25575
ONLINE_MODE=false
WHITE_LIST=true
ENFORCE_WHITELIST=true
MINECRAFT_WHITELIST=AnonymousNoobz
DIFFICULTY=hard
MAX_PLAYERS=20
RCON_PASSWORD=ci-test-password
UID=1000
GID=1000
SKIP_CHOWN=false
IMAGE_VERSION=0.1.0
DOCKER_PIDS_LIMIT=512
EOF
}

hadolint_bin() {
  if command -v hadolint &>/dev/null; then
    command -v hadolint
    return
  fi
  if docker image inspect hadolint/hadolint:2.12.0 >/dev/null 2>&1 || docker pull hadolint/hadolint:2.12.0 >/dev/null 2>&1; then
    echo "docker"
    return
  fi
  echo ""
}

run_hadolint() {
  local bin
  bin="$(hadolint_bin)"
  if [[ -z "${bin}" ]]; then
    echo "[ERRO] hadolint indisponivel"
    exit 1
  fi
  if [[ "${bin}" == "docker" ]]; then
    docker run --rm -i hadolint/hadolint:2.12.0 hadolint - < "${DOCKERFILE}"
  else
    "${bin}" "${DOCKERFILE}"
  fi
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
  echo ">>> hadolint"
  run_hadolint
}

cmd_validate() {
  echo ">>> docker compose config"
  if ! command -v docker >/dev/null 2>&1; then
    echo "[ERRO] docker nao encontrado"
    exit 1
  fi
  synthetic_env
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config --quiet
}

cmd_test() {
  echo ">>> docker smoke estatico"
  local failed=0
  command -v docker >/dev/null 2>&1 || { echo "[FAIL] docker ausente"; failed=1; }
  docker compose version >/dev/null 2>&1 || { echo "[FAIL] docker compose ausente"; failed=1; }
  [[ -f "${COMPOSE_FILE}" ]] || { echo "[FAIL] compose ausente"; failed=1; }
  [[ -f "${DOCKERFILE}" ]] || { echo "[FAIL] Dockerfile ausente"; failed=1; }
  [[ -f app/runtime/mods/mods-manifest.json ]] || { echo "[FAIL] manifesto ausente"; failed=1; }
  synthetic_env
  if docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config --quiet; then
    echo "[OK] compose config"
  else
    echo "[FAIL] compose config"
    failed=1
  fi
  if [[ "${failed}" -ne 0 ]]; then
    exit 1
  fi
  echo "[OK] smoke docker estatico"
}

cmd_security() {
  local trivy
  trivy="$(trivy_bin)"
  echo ">>> trivy config infra/docker"
  "${trivy}" config --exit-code 1 --severity HIGH,CRITICAL --ignorefile linters/.trivyignore infra/docker
  if [[ -n "${TRIVY_IMAGE:-}" ]]; then
    echo ">>> trivy image ${TRIVY_IMAGE}"
    "${trivy}" image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "${TRIVY_IMAGE}"
  fi
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
