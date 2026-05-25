#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
STATEFULSET="${STATEFULSET:-mc-server}"
POD="${POD:-mc-server-0}"
GAME_PORT="${GAME_PORT:-25565}"
GAME_SVC="${GAME_SVC:-mc-server-game}"
DNS_FQDN_ESPERADO="${DNS_FQDN_ESPERADO:-minecraftserverprod.brazilsouth.cloudapp.azure.com}"

annotate() {
  local kind="$1"
  local name="$2"
  shift 2
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi
  kubectl annotate -n "$NAMESPACE" "$kind" "$name" --overwrite "$@"
}

GAME_HOST="$(kubectl -n "$NAMESPACE" get svc "$GAME_SVC" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
GAME_IP="$(kubectl -n "$NAMESPACE" get svc "$GAME_SVC" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [[ -z "$GAME_HOST" ]]; then
  GAME_HOST="$GAME_IP"
fi

CONECTIVIDADE_ENDERECO=""
if [[ -n "$GAME_HOST" ]]; then
  if echo "$GAME_HOST" | grep -q '[a-zA-Z]'; then
    CONECTIVIDADE_ENDERECO="${GAME_HOST}"
  else
    CONECTIVIDADE_ENDERECO="${GAME_HOST}:${GAME_PORT}"
  fi
fi

LB_STATUS="$(kubectl -n "$NAMESPACE" get svc "$GAME_SVC" -o jsonpath='{.status.loadBalancer.ingress[0]}' 2>/dev/null || true)"
if [[ -z "$LB_STATUS" ]]; then
  LB_PROVISIONAMENTO="pendente"
else
  LB_PROVISIONAMENTO="ativo"
fi

READY="$(kubectl -n "$NAMESPACE" get statefulset "$STATEFULSET" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
DESIRED="$(kubectl -n "$NAMESPACE" get statefulset "$STATEFULSET" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 1)"
if [[ "${READY:-0}" == "${DESIRED:-1}" ]] && [[ "${READY:-0}" != "0" ]]; then
  STS_SAUDE="pronto"
else
  STS_SAUDE="aguardando (${READY:-0}/${DESIRED:-1})"
fi

TCP_SAUDE="nao-testado"
if [[ -n "$GAME_HOST" ]]; then
  if timeout 3 bash -c "echo > /dev/tcp/${GAME_HOST}/${GAME_PORT}" 2>/dev/null; then
    TCP_SAUDE="acessivel"
  else
    TCP_SAUDE="indisponivel"
  fi
else
  TCP_SAUDE="sem-host-publico"
fi

LOG_SAUDE="desconhecido"
if kubectl -n "$NAMESPACE" get pod "$POD" >/dev/null 2>&1; then
  if kubectl -n "$NAMESPACE" logs "$POD" --tail=80 2>/dev/null | grep -q 'Done (.*)! For help, type "help"'; then
    LOG_SAUDE="online"
  else
    LOG_SAUDE="iniciando"
  fi
else
  LOG_SAUDE="pod-ausente"
fi

annotate namespace minecraft-server-prod \
  "minecraft-server.io/conectividade-endereco=${CONECTIVIDADE_ENDERECO:-pendente}" \
  "minecraft-server.io/conectividade-host=${GAME_HOST:-pendente}" \
  "minecraft-server.io/conectividade-loadbalancer=${LB_PROVISIONAMENTO}" \
  "minecraft-server.io/saude-statefulset=${STS_SAUDE}" \
  "minecraft-server.io/saude-tcp-externa=${TCP_SAUDE}" \
  "minecraft-server.io/saude-logs=${LOG_SAUDE}" \
  "minecraft-server.io/atualizado-em=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

annotate statefulset "$STATEFULSET" \
  "minecraft-server.io/saude-statefulset=${STS_SAUDE}" \
  "minecraft-server.io/saude-tcp-externa=${TCP_SAUDE}" \
  "minecraft-server.io/saude-logs=${LOG_SAUDE}"

annotate service "$GAME_SVC" \
  "minecraft-server.io/conectividade-endereco=${CONECTIVIDADE_ENDERECO:-pendente}" \
  "minecraft-server.io/conectividade-host=${GAME_HOST:-pendente}" \
  "minecraft-server.io/conectividade-loadbalancer=${LB_PROVISIONAMENTO}" \
  "minecraft-server.io/saude-tcp-externa=${TCP_SAUDE}" \
  "minecraft-server.io/azure-dns-fqdn-esperado=${DNS_FQDN_ESPERADO}"

if kubectl -n "$NAMESPACE" get pod "$POD" >/dev/null 2>&1; then
  annotate pod "$POD" \
    "minecraft-server.io/conectividade-endereco=${CONECTIVIDADE_ENDERECO:-pendente}" \
    "minecraft-server.io/saude-tcp-externa=${TCP_SAUDE}" \
    "minecraft-server.io/saude-logs=${LOG_SAUDE}"
fi

echo "[OK] Annotations essenciais atualizadas no namespace ${NAMESPACE}."
if [[ -n "$CONECTIVIDADE_ENDERECO" ]]; then
  echo "     Conectar no Minecraft: ${CONECTIVIDADE_ENDERECO}"
fi
