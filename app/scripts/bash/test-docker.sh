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

step "Testando conectividade TCP local"
if command -v bash >/dev/null 2>&1; then
  if timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${GAME_PORT}" 2>/dev/null; then
    pass "porta ${GAME_PORT} acessivel em 127.0.0.1"
  else
    warn "porta ${GAME_PORT} nao respondeu em 127.0.0.1"
  fi
  if timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${RCON_PORT}" 2>/dev/null; then
    pass "porta RCON ${RCON_PORT} acessivel em 127.0.0.1"
  else
    warn "porta RCON ${RCON_PORT} nao respondeu em 127.0.0.1"
  fi
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

step "Ultimas linhas do log do servico"
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=15 "$SERVICE" 2>/dev/null | sed 's/^/     /'
  if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=80 "$SERVICE" 2>/dev/null | grep -q "Done (.*)! For help, type \"help\""; then
    pass "servidor Minecraft reportou startup completo nos logs"
  else
    warn "mensagem 'Done!' nao encontrada nos ultimos logs (servidor ainda iniciando?)"
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
