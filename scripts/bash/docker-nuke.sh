#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERRO] docker nao encontrado no PATH"
  exit 1
fi

confirm_nuke() {
  while true; do
    printf '%s' "ATENCAO: isso apaga TODOS os containers, imagens, volumes e redes do Docker neste daemon (WSL). Continuar? [s/N]: "
    read -r answer
    answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    case "$answer" in
      s|sim|y|yes)
        return 0
        ;;
      n|nao|no|"")
        echo "Operacao cancelada."
        exit 0
        ;;
      *)
        echo "Resposta invalida. Use s/S/sim ou n/N/nao."
        ;;
    esac
  done
}

echo ">>> docker-nuke: limpeza total do Docker"
echo ""
docker info --format 'Daemon: {{.Name}} | Containers: {{.Containers}} | Images: {{.Images}}' 2>/dev/null || docker info | head -n 5
echo ""

confirm_nuke

echo ""
echo ">>> Parando e removendo containers..."
if [[ -n "$(docker ps -aq 2>/dev/null || true)" ]]; then
  docker ps -aq | xargs -r docker stop 2>/dev/null || true
  docker ps -aq | xargs -r docker rm -f 2>/dev/null || true
fi

if [[ -f .env ]] && docker compose version >/dev/null 2>&1; then
  echo ">>> Removendo stack deste projeto (compose down -v)..."
  docker compose --env-file .env down --remove-orphans -v 2>/dev/null || true
fi

echo ">>> Removendo volumes nao utilizados..."
docker volume ls -q 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true

echo ">>> Removendo redes customizadas..."
docker network ls --format '{{.ID}} {{.Name}}' 2>/dev/null | while read -r net_id net_name; do
  case "$net_name" in
    bridge|host|none) continue ;;
    *) docker network rm "$net_id" 2>/dev/null || true ;;
  esac
done

echo ">>> Prune de imagens, containers, volumes e cache (system + builder)..."
docker system prune -a --volumes -f
docker builder prune -a -f 2>/dev/null || true

echo ""
echo "[SUCESSO] Docker limpo. Estado atual:"
docker system df 2>/dev/null || true
docker ps -a 2>/dev/null || true
docker images 2>/dev/null || true
docker volume ls 2>/dev/null || true
docker network ls 2>/dev/null || true
