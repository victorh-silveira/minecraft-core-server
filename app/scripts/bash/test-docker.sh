#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="infra/docker/docker-compose.yml"
ENV_FILE="infra/docker/.env"
CONTAINER="minecraft_core_server"
SERVICE="mc-server"
FAILED=0
STARTUP_TIMEOUT_SEC="${STARTUP_TIMEOUT_SEC:-180}"

pass() {
  echo "[OK] $1"
}

fail() {
  echo "[FAIL] $1"
  FAILED=1
}

warn() {
  echo "[WARN] $1"
}

step() {
  echo ""
  echo ">>> $1"
}

load_env_value() {
  local key="$1"
  local default="${2:-}"
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "$default"
    return
  fi
  local line
  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "$default"
    return
  fi
  echo "${line#*=}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

compose_logs() {
  local tail_n="${1:-80}"
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail="${tail_n}" "$SERVICE" 2>/dev/null || true
}

step "Verificando Docker e Compose"
if command -v docker >/dev/null 2>&1; then
  pass "docker encontrado: $(docker --version)"
else
  fail "docker nao encontrado no PATH"
fi

if docker compose version >/dev/null 2>&1; then
  pass "docker compose disponivel: $(docker compose version --short 2>/dev/null || docker compose version)"
else
  fail "docker compose indisponivel"
fi

step "Verificando arquivo .env"
if [[ -f "$ENV_FILE" ]]; then
  pass ".env presente em infra/docker/"
  WHITELIST_NICK="$(load_env_value MINECRAFT_WHITELIST)"
  if [[ "${WHITELIST_NICK}" == "ci-test-player" ]]; then
    fail "MINECRAFT_WHITELIST=ci-test-player (placeholder de CI); use um nick real no .env"
  fi
else
  fail ".env ausente (copie infra/docker/.env.example para $ENV_FILE)"
fi

GAME_PORT="$(load_env_value GAME_PORT 25565)"
RCON_PORT="$(load_env_value RCON_PORT 25575)"
LAN_HOST="${SMOKE_LAN_HOST:-192.168.0.50}"

step "Validando docker-compose.yml"
if [[ -f "$ENV_FILE" ]] && docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config --quiet >/dev/null 2>&1; then
  pass "docker compose config valido"
else
  fail "docker compose config falhou"
fi

step "Verificando container ${CONTAINER}"
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  pass "container registrado"
  STATE="$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo unknown)"
  HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$CONTAINER" 2>/dev/null || echo n/a)"
  echo "     status=${STATE} health=${HEALTH}"
  if [[ "$STATE" == "running" ]]; then
    pass "container em execucao"
  else
    fail "container nao esta running (status=${STATE})"
  fi
else
  fail "container ${CONTAINER} nao encontrado (rode: make docker-up)"
fi

step "Verificando portas publicadas"
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  PORTS="$(docker port "$CONTAINER" 2>/dev/null || true)"
  if echo "$PORTS" | grep -q "25565/tcp"; then
    pass "porta do jogo mapeada (container 25565)"
  else
    fail "porta 25565/tcp nao mapeada no container"
  fi
  if echo "$PORTS" | grep -q "25575/tcp"; then
    pass "porta RCON mapeada (container 25575)"
  else
    warn "porta 25575/tcp nao mapeada no container"
  fi
  echo "$PORTS" | sed 's/^/     /'
else
  warn "container parado; pulando checagem de portas"
fi

step "Testando conectividade TCP (localhost + LAN)"
PROBE_PS="${ROOT}/app/scripts/bash/probe-tcp.ps1"

probe_tcp_linux() {
  local host="$1"
  local port="$2"
  timeout 3 bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null
}

probe_tcp_windows() {
  local host="$1"
  local port="$2"
  if ! command -v powershell.exe >/dev/null 2>&1; then
    return 1
  fi
  powershell.exe -NoProfile -File "$(wslpath -w "${PROBE_PS}")" -HostName "${host}" -Port "${port}" >/dev/null 2>&1
}

if probe_tcp_linux "127.0.0.1" "${GAME_PORT}"; then
  pass "porta ${GAME_PORT} acessivel em 127.0.0.1"
else
  fail "porta ${GAME_PORT} nao respondeu em 127.0.0.1"
fi

if probe_tcp_windows "${LAN_HOST}" "${GAME_PORT}" || probe_tcp_linux "${LAN_HOST}" "${GAME_PORT}"; then
  pass "porta ${GAME_PORT} acessivel em ${LAN_HOST}"
else
  fail "porta ${GAME_PORT} nao respondeu em ${LAN_HOST} (confira bind 0.0.0.0 e Firewall do Windows)"
fi

if probe_tcp_linux "127.0.0.1" "${RCON_PORT}"; then
  pass "porta RCON ${RCON_PORT} acessivel em 127.0.0.1"
else
  warn "porta RCON ${RCON_PORT} nao respondeu em 127.0.0.1"
fi

step "Verificando mods sincronizados"
if [[ -f app/runtime/mods/mods-manifest.json ]]; then
  pass "mods-manifest.json presente"
  JAR_COUNT="$(find app/runtime/mods -maxdepth 1 -name '*.jar' 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${JAR_COUNT:-0}" -gt 0 ]]; then
    pass "${JAR_COUNT} jar(s) em app/runtime/mods"
  else
    warn "nenhum jar em app/runtime/mods (rode: make docker-sync-mods)"
  fi
else
  fail "mods-manifest.json ausente"
fi

step "Aguardando startup do servidor (timeout ${STARTUP_TIMEOUT_SEC}s)"
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  deadline=$((SECONDS + STARTUP_TIMEOUT_SEC))
  started=0
  while (( SECONDS < deadline )); do
    LOGS="$(compose_logs 120)"
    if echo "${LOGS}" | grep -Eqi "Could not resolve user|Invalid parameter provided for 'manage-users'"; then
      fail "falha ao resolver whitelist (manage-users); rode make docker-up com MINECRAFT_WHITELIST valido"
      echo "${LOGS}" | tail -n 20 | sed 's/^/     /'
      started=-1
      break
    fi
    HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$CONTAINER" 2>/dev/null || echo n/a)"
    if echo "${LOGS}" | grep -q 'Done (.*)! For help, type "help"'; then
      pass "servidor Minecraft reportou startup completo nos logs"
      started=1
      break
    fi
    if [[ "${HEALTH}" == "healthy" ]]; then
      pass "healthcheck do container esta healthy"
      started=1
      break
    fi
    sleep 5
  done
  if [[ "${started}" -eq 0 ]]; then
    warn "startup completo nao confirmado em ${STARTUP_TIMEOUT_SEC}s (health ainda iniciando?)"
    compose_logs 15 | sed 's/^/     /'
  fi
else
  warn "container parado; logs omitidos"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "[SUCESSO] Testes Docker concluidos sem falhas criticas."
  exit 0
fi

echo "[ERRO] Um ou mais testes criticos falharam."
exit 1
