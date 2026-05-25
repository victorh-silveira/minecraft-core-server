#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
APP_LABEL="app.kubernetes.io/name=mc-server"
FAILED=0

RG_STATUS="Nao verificado"
VNET_STATUS="Nao verificado"
SA_STATUS="Nao verificado"
ACR_STATUS="Nao verificado"
AKS_STATUS="Nao verificado"
K8S_NS_STATUS="Nao verificado"
K8S_STS_STATUS="Nao verificado"
K8S_PVC_STATUS="Nao verificado"
K8S_SVC_STATUS="Nao verificado"
TCP_STATUS="Nao verificado"
LOG_STATUS="Nao verificado"

GAME_HOST=""
MC_VERSION="1.20.6"
MC_TYPE="FABRIC"

pass() {
  echo "[OK] $1"
}

fail() {
  echo "[FALHA] $1"
  FAILED=1
}

warn() {
  echo "[AVISO] $1"
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

step "Verificando recursos na Azure"
if command -v az >/dev/null 2>&1; then
  pass "Azure CLI encontrada"

  RG_STATE="$(az group show --name rg-minecraft-server-prod --query properties.provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$RG_STATE" == "Succeeded" ]]; then
    pass "Grupo de recursos rg-minecraft-server-prod: Succeeded"
    RG_STATUS="Sucesso"
  else
    fail "Grupo de recursos rg-minecraft-server-prod em estado: ${RG_STATE}"
    RG_STATUS="Falhou (${RG_STATE})"
  fi

  VNET_STATE="$(az network vnet show --resource-group rg-minecraft-server-prod --name vnet-minecraft-server-prod-bs --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$VNET_STATE" == "Succeeded" ]]; then
    pass "Rede virtual vnet-minecraft-server-prod-bs: Succeeded"
    VNET_STATUS="Sucesso"
  else
    fail "Rede virtual vnet-minecraft-server-prod-bs em estado: ${VNET_STATE}"
    VNET_STATUS="Falhou (${VNET_STATE})"
  fi

  SA_STATE="$(az storage account show --name stminecraftserverprod001 --resource-group rg-minecraft-server-prod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$SA_STATE" == "Succeeded" ]]; then
    pass "Conta de armazenamento stminecraftserverprod001: Succeeded"
    SA_STATUS="Sucesso"
  else
    fail "Conta de armazenamento stminecraftserverprod001 em estado: ${SA_STATE}"
    SA_STATUS="Falhou (${SA_STATE})"
  fi

  ACR_STATE="$(az acr show --name acrminecraftserverprod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$ACR_STATE" == "Succeeded" ]]; then
    pass "Container Registry acrminecraftserverprod: Succeeded"
    ACR_STATUS="Sucesso"
  else
    fail "Container Registry acrminecraftserverprod em estado: ${ACR_STATE}"
    ACR_STATUS="Falhou (${ACR_STATE})"
  fi

  AKS_STATE="$(az aks show --resource-group rg-minecraft-server-prod --name aks-minecraft-server-prod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$AKS_STATE" == "Succeeded" ]]; then
    pass "Cluster AKS aks-minecraft-server-prod: Succeeded"
    AKS_STATUS="Sucesso"
  else
    fail "Cluster AKS aks-minecraft-server-prod em estado: ${AKS_STATE}"
    AKS_STATUS="Falhou (${AKS_STATE})"
  fi
else
  warn "Azure CLI nao encontrada; pulando validacao de recursos Azure"
  RG_STATUS="Ignorado (sem az CLI)"
  VNET_STATUS="Ignorado (sem az CLI)"
  SA_STATUS="Ignorado (sem az CLI)"
  ACR_STATUS="Ignorado (sem az CLI)"
  AKS_STATUS="Ignorado (sem az CLI)"
fi

step "Verificando namespace ${NAMESPACE}"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  pass "namespace ${NAMESPACE} existe"
  K8S_NS_STATUS="Ativo"
else
  fail "namespace ${NAMESPACE} nao encontrado (aplique: kubectl apply -k infra/kubernetes/overlays/prod)"
  K8S_NS_STATUS="Nao encontrado"
fi

step "Verificando StatefulSet mc-server"
if kubectl -n "$NAMESPACE" get statefulset mc-server >/dev/null 2>&1; then
  READY="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
  DESIRED="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 1)"
  echo "     prontos=${READY:-0}/${DESIRED:-1}"
  if [[ "${READY:-0}" == "${DESIRED:-1}" ]] && [[ "${READY:-0}" != "0" ]]; then
    pass "statefulset pronto"
    K8S_STS_STATUS="Pronto (${READY}/${DESIRED})"
  else
    fail "statefulset nao esta pronto"
    K8S_STS_STATUS="Falhou (${READY}/${DESIRED} prontos)"
  fi

  MC_VERSION="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="VERSION")].value}' 2>/dev/null || echo "1.20.6")"
  MC_TYPE="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="TYPE")].value}' 2>/dev/null || echo "FABRIC")"
else
  fail "statefulset mc-server nao encontrado"
  K8S_STS_STATUS="Nao encontrado"
fi

step "Verificando PVC mc-data"
if kubectl -n "$NAMESPACE" get pvc mc-data >/dev/null 2>&1; then
  PVC_STATUS="$(kubectl -n "$NAMESPACE" get pvc mc-data -o jsonpath='{.status.phase}' 2>/dev/null || echo unknown)"
  echo "     fase=${PVC_STATUS}"
  if [[ "$PVC_STATUS" == "Bound" ]]; then
    pass "PVC vinculado (Bound)"
    K8S_PVC_STATUS="Vinculado (persistente)"
  else
    fail "PVC nao vinculado (fase=${PVC_STATUS})"
    K8S_PVC_STATUS="Falhou (${PVC_STATUS})"
  fi
else
  fail "PVC mc-data nao encontrado"
  K8S_PVC_STATUS="Nao encontrado"
fi

step "Verificando servicos LoadBalancer"
if kubectl -n "$NAMESPACE" get svc mc-server-game >/dev/null 2>&1; then
  GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -z "$GAME_HOST" ]]; then
    GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  fi
  if [[ -n "$GAME_HOST" ]]; then
    pass "mc-server-game exposto em: ${GAME_HOST}"
    K8S_SVC_STATUS="Ativo (LoadBalancer)"
  else
    warn "mc-server-game sem IP externo ainda (provisionamento)"
    K8S_SVC_STATUS="Provisionando IP publico"
  fi
else
  fail "servico mc-server-game nao encontrado"
  K8S_SVC_STATUS="Nao encontrado"
fi

if kubectl -n "$NAMESPACE" get svc mc-server-rcon >/dev/null 2>&1; then
  pass "servico mc-server-rcon existe"
else
  warn "servico mc-server-rcon nao encontrado"
fi

step "Testando porta TCP 25565"
TARGET_HOST="${GAME_HOST:-127.0.0.1}"
if [[ -n "$GAME_HOST" ]] && timeout 3 bash -c "echo > /dev/tcp/${TARGET_HOST}/25565" 2>/dev/null; then
  pass "porta 25565 acessivel em ${TARGET_HOST}"
  TCP_STATUS="Acessivel"
elif [[ -z "$GAME_HOST" ]]; then
  warn "IP do balanceador ausente; pulando teste TCP externo"
  TCP_STATUS="Ignorado (sem IP publico)"
else
  warn "porta 25565 nao respondeu em ${TARGET_HOST}"
  TCP_STATUS="Sem resposta (porta fechada ou servidor iniciando)"
fi

step "Ultimas linhas de log do pod"
POD="$(kubectl -n "$NAMESPACE" get pods -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$POD" ]]; then
  kubectl -n "$NAMESPACE" logs "$POD" --tail=15 2>/dev/null | sed 's/^/     /'
  if kubectl -n "$NAMESPACE" logs "$POD" --tail=80 2>/dev/null | grep -q "Done (.*)! For help, type \"help\""; then
    pass "servidor reportou inicializacao completa nos logs"
    LOG_STATUS="Online (Done!)"
  else
    warn "mensagem Done! nao encontrada nos ultimos logs"
    LOG_STATUS="Iniciando (Done! ainda nao encontrado)"
  fi
else
  warn "pod nao encontrado"
  LOG_STATUS="Pod nao encontrado"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Servidor Minecraft - Status de implantacao e diagnostico"
    echo ""
    echo "### 1. Conexao no cliente Minecraft"
    if [[ -n "$GAME_HOST" ]]; then
      echo "Use no multiplayer:"
      echo ""
      echo "* **Host/IP:** \`${GAME_HOST}\`"
      echo "* **Porta:** \`25565\`"
      echo "* **Versao:** \`${MC_VERSION}\` (\`${MC_TYPE}\`)"
      echo ""
      echo "> Conexao direta ou adicionar servidor: \`${GAME_HOST}:25565\`"
    else
      echo "**Atencao:** o IP publico do LoadBalancer ainda esta sendo provisionado pela Azure."
    fi
    echo ""
    echo "### 2. Recursos Azure"
    echo ""
    echo "| Recurso | Nome | Status |"
    echo "|---|---|---|"
    echo "| Grupo de recursos | \`rg-minecraft-server-prod\` | ${RG_STATUS} |"
    echo "| Rede virtual | \`vnet-minecraft-server-prod-bs\` | ${VNET_STATUS} |"
    echo "| Conta de armazenamento | \`stminecraftserverprod001\` | ${SA_STATUS} |"
    echo "| Container Registry | \`acrminecraftserverprod\` | ${ACR_STATUS} |"
    echo "| Kubernetes (AKS) | \`aks-minecraft-server-prod\` | ${AKS_STATUS} |"
    echo ""
    echo "### 3. Kubernetes e Minecraft"
    echo ""
    echo "| Recurso | Detalhe | Status |"
    echo "|---|---|---|"
    echo "| Namespace | \`${NAMESPACE}\` | ${K8S_NS_STATUS} |"
    echo "| StatefulSet | \`mc-server\` | ${K8S_STS_STATUS} |"
    echo "| PVC | \`mc-data\` | ${K8S_PVC_STATUS} |"
    echo "| Servico de jogo | \`mc-server-game\` | ${K8S_SVC_STATUS} |"
    echo "| TCP externa | porta \`25565\` | ${TCP_STATUS} |"
    echo "| Logs de inicializacao | container | ${LOG_STATUS} |"
    echo ""
    echo "---"
    echo "*Relatorio gerado em $(date -d 'today' '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date).*"
  } >> "$GITHUB_STEP_SUMMARY"

  if [[ -n "$GAME_HOST" ]]; then
    echo "::notice title=Conexao Minecraft::Conecte em ${GAME_HOST}:25565 (versao ${MC_VERSION} - ${MC_TYPE})"
  fi
  if [[ "$FAILED" -eq 0 ]]; then
    echo "::notice title=Pos-deploy::Todos os recursos estao ativos e acessiveis."
  else
    echo "::warning title=Pos-deploy::Um ou mais recursos criticos falharam na validacao."
  fi
fi

if command -v kubectl >/dev/null 2>&1; then
  bash "$(dirname "${BASH_SOURCE[0]}")/atualizar-annotations-k8s.sh" || warn "nao foi possivel atualizar annotations Kubernetes"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "[SUCESSO] Testes AKS concluidos sem falhas criticas."
  exit 0
fi

echo "[ERRO] Um ou mais testes criticos falharam."
exit 1
