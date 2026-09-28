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

WSL_HOST="$(ip -4 route get 1.1.1.1 | awk '{for (field_index = 1; field_index <= NF; field_index++) if ($field_index == "src") {print $(field_index + 1); exit}}')"
if [[ -z "${WSL_HOST}" ]]; then
  echo "[ERRO] IP do WSL nao identificado"
  exit 1
fi

echo ">>> Configurando ${LAN_HOST}:${GAME_PORT} -> WSL ${WSL_HOST}:${GAME_PORT} e Firewall (UAC)"
WIN_SCRIPT="$(wslpath -w "${ROOT}/app/scripts/bash/expose-lan-port.ps1")"
powershell.exe -NoProfile -Command \
  "Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','${WIN_SCRIPT}','-Port','${GAME_PORT}','-ConnectHost','${WSL_HOST}','-LanHost','${LAN_HOST}'"
