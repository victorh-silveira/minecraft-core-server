#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="infra/docker/docker-compose.yml"
ENV_FILE="infra/docker/.env"
CONTAINER="minecraft_core_server"
SERVICE="mc-server"
FAILED=0

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
else
  fail ".env ausente (copie infra/docker/.env.example para $ENV_FILE)"
fi

GAME_PORT="$(load_env_value GAME_PORT 25565)"
RCON_PORT="$(load_env_value RCON_PORT 25575)"
LAN_HOST="${SMOKE_LAN_HOST:-$(load_env_value SMOKE_LAN_HOST 192.168.0.50)}"
WAN_PORT="${SMOKE_WAN_PORT:-$(load_env_value SMOKE_WAN_PORT "${GAME_PORT}")}"
DNS_HOST="${SMOKE_DNS_HOST:-$(load_env_value SMOKE_DNS_HOST noobz.ddns.net)}"
IPIFY_URL="${SMOKE_IPIFY_URL:-$(load_env_value SMOKE_IPIFY_URL 'https://api.ipify.org?format=json')}"
CONNECT_TIMEOUT_SEC="${SMOKE_CONNECT_TIMEOUT_SEC:-$(load_env_value SMOKE_CONNECT_TIMEOUT_SEC 5)}"
EXPECTED_MOTD="${SMOKE_EXPECTED_MOTD:-$(load_env_value SMOKE_EXPECTED_MOTD 'Minecraft Core Server')}"
STARTUP_TIMEOUT_SEC="${SMOKE_STARTUP_TIMEOUT_SEC:-$(load_env_value SMOKE_STARTUP_TIMEOUT_SEC 900)}"
EXTERNAL_STATUS_URL="${SMOKE_EXTERNAL_STATUS_URL:-$(load_env_value SMOKE_EXTERNAL_STATUS_URL 'https://api.mcsrvstat.us/3')}"
SMOKE_USER_AGENT="${SMOKE_USER_AGENT:-$(load_env_value SMOKE_USER_AGENT 'minecraft-core-server-smoke/1.0')}"

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

PROBE_PS="${ROOT}/app/scripts/bash/probe-tcp.ps1"
MINECRAFT_PROBE="${ROOT}/app/scripts/python/probe_minecraft_status.py"
EXTERNAL_MINECRAFT_PROBE="${ROOT}/app/scripts/python/probe_external_minecraft.py"

probe_tcp_linux() {
  local host="$1"
  local port="$2"
  timeout "${CONNECT_TIMEOUT_SEC}" bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null
}

probe_tcp_windows() {
  local host="$1"
  local port="$2"
  if ! command -v powershell.exe >/dev/null 2>&1; then
    return 1
  fi
  powershell.exe -NoProfile -File "$(wslpath -w "${PROBE_PS}")" \
    -HostName "${host}" -Port "${port}" -TimeoutMs "$((CONNECT_TIMEOUT_SEC * 1000))" >/dev/null 2>&1
}

probe_tcp() {
  local host="$1"
  local port="$2"
  probe_tcp_windows "${host}" "${port}" || probe_tcp_linux "${host}" "${port}"
}

probe_minecraft() {
  local host="$1"
  local port="$2"
  python "${MINECRAFT_PROBE}" "${host}" "${port}" \
    --timeout "${CONNECT_TIMEOUT_SEC}" --expected-motd "${EXPECTED_MOTD}"
}

probe_external_minecraft() {
  local target="$1"
  local expected_ip="$2"
  python "${EXTERNAL_MINECRAFT_PROBE}" "${target}" \
    --base-url "${EXTERNAL_STATUS_URL}" --timeout "$((CONNECT_TIMEOUT_SEC * 3))" \
    --user-agent "${SMOKE_USER_AGENT}" --expected-ip "${expected_ip}" --expected-motd "${EXPECTED_MOTD}"
}

fetch_wan_ip() {
  local payload
  payload="$(curl --fail --silent --show-error --location \
    --connect-timeout "${CONNECT_TIMEOUT_SEC}" --max-time "$((CONNECT_TIMEOUT_SEC * 2))" \
    --header 'Accept: application/json' "${IPIFY_URL}")" || return 1
  python -c 'import ipaddress,json,sys; address=ipaddress.ip_address(json.load(sys.stdin)["ip"]); assert address.is_global; print(address)' <<< "${payload}"
}

resolve_dns() {
  getent ahosts "$1" 2>/dev/null | awk '{print $1}' | sort -u
}

step "Verificando mods sincronizados"
if [[ -f app/runtime/mods/mods-manifest.json ]]; then
  pass "mods-manifest.json presente"
  JAR_COUNT="$(find app/runtime/mods -maxdepth 1 -name '*.jar' 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${JAR_COUNT:-0}" -eq 0 ]]; then
    pass "nenhum mod instalado"
  else
    fail "${JAR_COUNT} mod(s) encontrado(s); o runtime Forge deve permanecer sem mods"
  fi
else
  fail "mods-manifest.json ausente"
fi

step "Aguardando startup do servidor (timeout ${STARTUP_TIMEOUT_SEC}s)"
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  deadline=$((SECONDS + STARTUP_TIMEOUT_SEC))
  next_progress=${SECONDS}
  started=0
  while (( SECONDS < deadline )); do
    LOGS="$(compose_logs 120)"
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
    if (( SECONDS >= next_progress )); then
      INSTALLER_SIZE="$(docker exec "$CONTAINER" sh -lc \
        "stat -c '%s' /data/forge-installer-*.jar.download 2>/dev/null || echo 0" | tail -n 1)"
      echo "     aguardando startup: health=${HEALTH} forge_download_bytes=${INSTALLER_SIZE}"
      next_progress=$((SECONDS + 30))
    fi
    sleep 5
  done
  if [[ "${started}" -eq 0 ]]; then
    fail "startup completo nao confirmado em ${STARTUP_TIMEOUT_SEC}s"
    compose_logs 15 | sed 's/^/     /'
  fi
else
  warn "container parado; logs omitidos"
fi

step "Teste local"
if probe_tcp "127.0.0.1" "${GAME_PORT}"; then
  pass "porta ${GAME_PORT} aberta em 127.0.0.1"
else
  fail "porta ${GAME_PORT} nao respondeu em 127.0.0.1"
fi
if probe_minecraft "127.0.0.1" "${GAME_PORT}"; then
  pass "conexao Minecraft local concluida"
else
  fail "servidor Minecraft nao respondeu localmente"
fi
if probe_tcp_linux "127.0.0.1" "${RCON_PORT}"; then
  pass "porta RCON ${RCON_PORT} acessivel em 127.0.0.1"
else
  warn "porta RCON ${RCON_PORT} nao respondeu em 127.0.0.1"
fi

step "Teste LAN: porta aberta + conexao"
if probe_tcp "${LAN_HOST}" "${GAME_PORT}"; then
  pass "porta LAN ${GAME_PORT} aberta em ${LAN_HOST}"
else
  fail "porta LAN ${GAME_PORT} nao respondeu em ${LAN_HOST}"
fi
if probe_minecraft "${LAN_HOST}" "${GAME_PORT}"; then
  pass "conexao Minecraft pela LAN concluida"
else
  fail "servidor Minecraft nao respondeu pela LAN"
fi

step "Teste WAN: ipify JSON + porta aberta + conexao"
WAN_IP="$(fetch_wan_ip)" || WAN_IP=""
if [[ -n "${WAN_IP}" ]]; then
  pass "ipify JSON retornou o IP WAN ${WAN_IP}"
  if probe_external_minecraft "${WAN_IP}:${WAN_PORT}" "${WAN_IP}"; then
    pass "porta WAN ${WAN_PORT} aberta e conexao Minecraft externa concluida em ${WAN_IP}"
  else
    fail "porta WAN ${WAN_PORT} ou conexao Minecraft externa falhou em ${WAN_IP}"
  fi
  if probe_minecraft "${WAN_IP}" "${WAN_PORT}"; then
    pass "NAT loopback respondeu pelo IP WAN"
  else
    warn "NAT loopback indisponivel pelo IP WAN; resultado externo permanece autoritativo"
  fi
else
  fail "ipify JSON nao retornou um IP WAN valido"
fi

step "Teste DNS/WAN: resolucao + infraestrutura LAN + porta + conexao"
DNS_ADDRESSES="$(resolve_dns "${DNS_HOST}")"
if [[ -n "${WAN_IP}" ]] && grep -Fxq "${WAN_IP}" <<< "${DNS_ADDRESSES}"; then
  pass "${DNS_HOST} resolve corretamente para o IP WAN ${WAN_IP}"
else
  fail "${DNS_HOST} nao resolve para o IP WAN ${WAN_IP:-indisponivel} (resolvido: ${DNS_ADDRESSES:-nenhum})"
fi
if probe_external_minecraft "${DNS_HOST}:${WAN_PORT}" "${WAN_IP}"; then
  pass "${DNS_HOST} alcancou externamente a porta e o servidor Minecraft esperado"
else
  fail "${DNS_HOST} nao alcancou externamente a porta e o servidor Minecraft esperado"
fi
if probe_minecraft "${DNS_HOST}" "${WAN_PORT}"; then
  pass "NAT loopback respondeu por ${DNS_HOST}"
else
  warn "NAT loopback indisponivel por ${DNS_HOST}; resultado externo permanece autoritativo"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "[SUCESSO] Testes Docker concluidos sem falhas criticas."
  exit 0
fi

echo "[ERRO] Um ou mais testes criticos falharam."
exit 1
