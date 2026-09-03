#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${ROOT}"

COMPOSE_FILE="infra/docker/docker-compose.yml"
ENV_FILE="infra/docker/.env"
SERVICE="mc-server"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[ERRO] ${ENV_FILE} ausente (copie infra/docker/.env.example)"
  exit 1
fi

load_dotenv() {
  local key value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      UID|GID) continue ;;
    esac
    export "${key}=${value}"
  done < "${ENV_FILE}"
}

load_dotenv

ONLINE_MODE_NORM="$(printf '%s' "${ONLINE_MODE:-false}" | tr '[:upper:]' '[:lower:]')"
if [[ "${ONLINE_MODE_NORM}" == "false" ]]; then
  if [[ -z "${MINECRAFT_WHITELIST:-}" ]]; then
    echo "[ERRO] MINECRAFT_WHITELIST vazio no .env"
    exit 1
  fi
  if [[ "${MINECRAFT_WHITELIST}" == "ci-test-player" ]]; then
    echo "[ERRO] MINECRAFT_WHITELIST=ci-test-player e placeholder de CI; use um nick real (ex. AnonymousNoobz)"
    exit 1
  fi
  RESOLVED="$(bash app/scripts/bash/resolve-whitelist.sh "${MINECRAFT_WHITELIST}")"
  export MINECRAFT_WHITELIST="${RESOLVED}"
  echo ">>> Whitelist offline resolvida para UUID(s): ${MINECRAFT_WHITELIST}"
fi

BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo local)"
export BUILD_DATE VCS_REF

if [[ "${DOCKER_REBUILD:-0}" == "1" ]]; then
  echo ">>> Rebuild sem cache (--no-cache --pull)"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" build --no-cache --pull "${SERVICE}"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --force-recreate --no-build "${SERVICE}"
else
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --build --force-recreate "${SERVICE}"
fi

bash "${ROOT}/app/scripts/bash/expose-lan-port.sh"
