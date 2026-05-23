#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
APP_LABEL="app.kubernetes.io/name=mc-server"
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

step "Verificando kubectl e contexto"
if command -v kubectl >/dev/null 2>&1; then
  pass "kubectl encontrado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  fail "kubectl nao encontrado no PATH"
  exit 1
fi

CURRENT_CTX="$(kubectl config current-context 2>/dev/null || true)"
if [[ -n "$CURRENT_CTX" ]]; then
  pass "contexto atual: ${CURRENT_CTX}"
else
  fail "nenhum contexto kubectl configurado"
fi

step "Verificando namespace ${NAMESPACE}"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  pass "namespace ${NAMESPACE} existe"
else
  fail "namespace ${NAMESPACE} nao encontrado (aplique: kubectl apply -k infra/kubernetes/overlays/prod)"
fi

step "Verificando StatefulSet mc-server"
if kubectl -n "$NAMESPACE" get statefulset mc-server >/dev/null 2>&1; then
  READY="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
  DESIRED="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 1)"
  echo "     ready=${READY:-0}/${DESIRED:-1}"
  if [[ "${READY:-0}" == "${DESIRED:-1}" ]] && [[ "${READY:-0}" != "0" ]]; then
    pass "statefulset pronto"
  else
    fail "statefulset nao esta ready"
  fi
else
  fail "statefulset mc-server nao encontrado"
fi

step "Verificando PVC mc-data"
if kubectl -n "$NAMESPACE" get pvc mc-data >/dev/null 2>&1; then
  PVC_STATUS="$(kubectl -n "$NAMESPACE" get pvc mc-data -o jsonpath='{.status.phase}' 2>/dev/null || echo unknown)"
  echo "     phase=${PVC_STATUS}"
  if [[ "$PVC_STATUS" == "Bound" ]]; then
    pass "PVC bound"
  else
    fail "PVC nao bound (phase=${PVC_STATUS})"
  fi
else
  fail "PVC mc-data nao encontrado"
fi

step "Verificando Services LoadBalancer"
GAME_HOST=""
if kubectl -n "$NAMESPACE" get svc mc-server-game >/dev/null 2>&1; then
  GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -z "$GAME_HOST" ]]; then
    GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  fi
  if [[ -n "$GAME_HOST" ]]; then
    if echo "$GAME_HOST" | grep -q '[a-zA-Z]'; then
      pass "mc-server-game: conecte em ${GAME_HOST}"
    else
      pass "mc-server-game LB: ${GAME_HOST}:25565"
    fi
  else
    warn "mc-server-game sem IP externo ainda (provisioning)"
  fi
else
  fail "service mc-server-game nao encontrado"
fi

if kubectl -n "$NAMESPACE" get svc mc-server-rcon >/dev/null 2>&1; then
  pass "service mc-server-rcon existe"
else
  warn "service mc-server-rcon nao encontrado"
fi

step "Testando porta TCP 25565"
TARGET_HOST="${GAME_HOST:-127.0.0.1}"
if [[ -n "$GAME_HOST" ]] && timeout 3 bash -c "echo > /dev/tcp/${TARGET_HOST}/25565" 2>/dev/null; then
  pass "porta 25565 acessivel em ${TARGET_HOST}"
elif [[ -z "$GAME_HOST" ]]; then
  warn "LB IP ausente; pulando teste TCP externo"
else
  warn "porta 25565 nao respondeu em ${TARGET_HOST}"
fi

step "Ultimas linhas de log do pod"
POD="$(kubectl -n "$NAMESPACE" get pods -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$POD" ]]; then
  kubectl -n "$NAMESPACE" logs "$POD" --tail=15 2>/dev/null | sed 's/^/     /'
  if kubectl -n "$NAMESPACE" logs "$POD" --tail=80 2>/dev/null | grep -q "Done (.*)! For help, type \"help\""; then
    pass "servidor reportou startup completo nos logs"
  else
    warn "mensagem Done! nao encontrada nos ultimos logs"
  fi
else
  warn "pod nao encontrado"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "[SUCESSO] Testes AKS concluidos sem falhas criticas."
  exit 0
fi

echo "[ERRO] Um ou mais testes criticos falharam."
exit 1
