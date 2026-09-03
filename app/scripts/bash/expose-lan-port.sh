#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${ROOT}"

ENV_FILE="infra/docker/.env"
GAME_PORT=25565
LAN_HOST="${SMOKE_LAN_HOST:-192.168.0.50}"

if [[ -f "${ENV_FILE}" ]]; then
  line="$(grep -E '^GAME_PORT=' "${ENV_FILE}" | tail -n 1 || true)"
  if [[ -n "${line}" ]]; then
    GAME_PORT="${line#*=}"
    GAME_PORT="$(printf '%s' "${GAME_PORT}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  fi
fi

if ! command -v powershell.exe >/dev/null 2>&1; then
  echo "[WARN] powershell.exe indisponivel; pulando exposicao LAN"
  exit 0
fi

echo ">>> Expondo porta ${GAME_PORT} na LAN (${LAN_HOST}) via portproxy (UAC)"
WIN_SCRIPT="$(wslpath -w "${ROOT}/app/scripts/bash/expose-lan-port.ps1")"
powershell.exe -NoProfile -Command \
  "Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','${WIN_SCRIPT}','-Port','${GAME_PORT}','-LanHost','${LAN_HOST}'"
