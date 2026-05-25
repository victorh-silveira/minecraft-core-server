#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
APP_LABEL="app.kubernetes.io/name=mc-server"
FAILED=0

# Variáveis de Status para o GitHub Step Summary
RG_STATUS="➖ Não verificado"
VNET_STATUS="➖ Não verificado"
SA_STATUS="➖ Não verificado"
ACR_STATUS="➖ Não verificado"
AKS_STATUS="➖ Não verificado"
K8S_NS_STATUS="➖ Não verificado"
K8S_STS_STATUS="➖ Não verificado"
K8S_PVC_STATUS="➖ Não verificado"
K8S_SVC_STATUS="➖ Não verificado"
TCP_STATUS="➖ Não verificado"
LOG_STATUS="➖ Não verificado"

GAME_HOST=""
MC_VERSION="1.20.6"
MC_TYPE="FABRIC"

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

step "Verificando Recursos na Azure"
if command -v az >/dev/null 2>&1; then
  pass "Azure CLI encontrada"

  # 1. Resource Group
  RG_STATE="$(az group show --name rg-minecraft-server-prod --query properties.provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$RG_STATE" == "Succeeded" ]]; then
    pass "Azure Resource Group rg-minecraft-server-prod: Succeeded"
    RG_STATUS="🟢 Succeeded"
  else
    fail "Azure Resource Group rg-minecraft-server-prod esta em estado: ${RG_STATE}"
    RG_STATUS="🔴 Falhou (${RG_STATE})"
  fi

  # 2. VNet
  VNET_STATE="$(az network vnet show --resource-group rg-minecraft-server-prod --name vnet-minecraft-server-prod-bs --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$VNET_STATE" == "Succeeded" ]]; then
    pass "Azure Virtual Network vnet-minecraft-server-prod-bs: Succeeded"
    VNET_STATUS="🟢 Succeeded"
  else
    fail "Azure Virtual Network vnet-minecraft-server-prod-bs esta em estado: ${VNET_STATE}"
    VNET_STATUS="🔴 Falhou (${VNET_STATE})"
  fi

  # 3. Storage Account
  SA_STATE="$(az storage account show --name stminecraftserverprod001 --resource-group rg-minecraft-server-prod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$SA_STATE" == "Succeeded" ]]; then
    pass "Azure Storage Account stminecraftserverprod001: Succeeded"
    SA_STATUS="🟢 Succeeded"
  else
    fail "Azure Storage Account stminecraftserverprod001 esta em estado: ${SA_STATE}"
    SA_STATUS="🔴 Falhou (${SA_STATE})"
  fi

  # 4. ACR
  ACR_STATE="$(az acr show --name acrminecraftserverprod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$ACR_STATE" == "Succeeded" ]]; then
    pass "Azure Container Registry acrminecraftserverprod: Succeeded"
    ACR_STATUS="🟢 Succeeded"
  else
    fail "Azure Container Registry acrminecraftserverprod esta em estado: ${ACR_STATE}"
    ACR_STATUS="🔴 Falhou (${ACR_STATE})"
  fi

  # 5. AKS
  AKS_STATE="$(az aks show --resource-group rg-minecraft-server-prod --name aks-minecraft-server-prod --query provisioningState -o tsv 2>/dev/null || echo "NotFound")"
  if [[ "$AKS_STATE" == "Succeeded" ]]; then
    pass "Azure Kubernetes Service aks-minecraft-server-prod: Succeeded"
    AKS_STATUS="🟢 Succeeded"
  else
    fail "Azure Kubernetes Service aks-minecraft-server-prod esta em estado: ${AKS_STATE}"
    AKS_STATUS="🔴 Falhou (${AKS_STATE})"
  fi
else
  warn "Azure CLI nao encontrada; pulando validacao de recursos Azure"
  RG_STATUS="🟡 Ignorado (Sem az CLI)"
  VNET_STATUS="🟡 Ignorado (Sem az CLI)"
  SA_STATUS="🟡 Ignorado (Sem az CLI)"
  ACR_STATUS="🟡 Ignorado (Sem az CLI)"
  AKS_STATUS="🟡 Ignorado (Sem az CLI)"
fi

step "Verificando namespace ${NAMESPACE}"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  pass "namespace ${NAMESPACE} existe"
  K8S_NS_STATUS="🟢 Ativo"
else
  fail "namespace ${NAMESPACE} nao encontrado (aplique: kubectl apply -k infra/kubernetes/overlays/prod)"
  K8S_NS_STATUS="🔴 Não encontrado"
fi

step "Verificando StatefulSet mc-server"
if kubectl -n "$NAMESPACE" get statefulset mc-server >/dev/null 2>&1; then
  READY="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
  DESIRED="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 1)"
  echo "     ready=${READY:-0}/${DESIRED:-1}"
  if [[ "${READY:-0}" == "${DESIRED:-1}" ]] && [[ "${READY:-0}" != "0" ]]; then
    pass "statefulset pronto"
    K8S_STS_STATUS="🟢 Pronto (${READY}/${DESIRED})"
  else
    fail "statefulset nao esta ready"
    K8S_STS_STATUS="🔴 Falhou (${READY}/${DESIRED} prontos)"
  fi

  # Buscar versão e tipo configurados dinamicamente
  MC_VERSION="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="VERSION")].value}' 2>/dev/null || echo "1.20.6")"
  MC_TYPE="$(kubectl -n "$NAMESPACE" get statefulset mc-server -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="TYPE")].value}' 2>/dev/null || echo "FABRIC")"
else
  fail "statefulset mc-server nao encontrado"
  K8S_STS_STATUS="🔴 Não encontrado"
fi

step "Verificando PVC mc-data"
if kubectl -n "$NAMESPACE" get pvc mc-data >/dev/null 2>&1; then
  PVC_STATUS="$(kubectl -n "$NAMESPACE" get pvc mc-data -o jsonpath='{.status.phase}' 2>/dev/null || echo unknown)"
  echo "     phase=${PVC_STATUS}"
  if [[ "$PVC_STATUS" == "Bound" ]]; then
    pass "PVC bound"
    K8S_PVC_STATUS="🟢 Bound (Persistente)"
  else
    fail "PVC nao bound (phase=${PVC_STATUS})"
    K8S_PVC_STATUS="🔴 ${PVC_STATUS}"
  fi
else
  fail "PVC mc-data nao encontrado"
  K8S_PVC_STATUS="🔴 Não encontrado"
fi

step "Verificando Services LoadBalancer"
if kubectl -n "$NAMESPACE" get svc mc-server-game >/dev/null 2>&1; then
  GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -z "$GAME_HOST" ]]; then
    GAME_HOST="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  fi
  if [[ -n "$GAME_HOST" ]]; then
    pass "mc-server-game exposto em: ${GAME_HOST}"
    K8S_SVC_STATUS="🟢 Ativo (LoadBalancer)"
  else
    warn "mc-server-game sem IP externo ainda (provisioning)"
    K8S_SVC_STATUS="🟡 Provisionando IP público..."
  fi
else
  fail "service mc-server-game nao encontrado"
  K8S_SVC_STATUS="🔴 Não encontrado"
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
  TCP_STATUS="🟢 Acessível"
elif [[ -z "$GAME_HOST" ]]; then
  warn "LB IP ausente; pulando teste TCP externo"
  TCP_STATUS="🟡 Ignorado (Sem IP Público)"
else
  warn "porta 25565 nao respondeu em ${TARGET_HOST}"
  TCP_STATUS="🔴 Sem resposta (Porta Fechada/Servidor Iniciando)"
fi

step "Ultimas linhas de log do pod"
POD="$(kubectl -n "$NAMESPACE" get pods -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$POD" ]]; then
  kubectl -n "$NAMESPACE" logs "$POD" --tail=15 2>/dev/null | sed 's/^/     /'
  if kubectl -n "$NAMESPACE" logs "$POD" --tail=80 2>/dev/null | grep -q "Done (.*)! For help, type \"help\""; then
    pass "servidor reportou startup completo nos logs"
    LOG_STATUS="🟢 Online (Done!)"
  else
    warn "mensagem Done! nao encontrada nos ultimos logs"
    LOG_STATUS="🟡 Iniciando (Done! não encontrado ainda)"
  fi
else
  warn "pod nao encontrado"
  LOG_STATUS="🔴 Pod não encontrado"
fi

# Gerar GitHub Step Summary em Markdown e emitir Notices para o GitHub Actions
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## 🎮 Minecraft Server - Status de Implantação e Diagnóstico"
    echo ""
    echo "### 🌐 1. Conexão do seu Minecraft"
    if [[ -n "$GAME_HOST" ]]; then
      echo "Para jogar, utilize as informações abaixo no seu cliente Minecraft:"
      echo ""
      echo "* **Endereço do Servidor (IP/Host):** \`${GAME_HOST}\`"
      echo "* **Porta:** \`25565\`"
      echo "* **Versão Desejada:** \`${MC_VERSION}\` (\`${MC_TYPE}\` Edition)"
      echo ""
      echo "> [!TIP]"
      echo "> No menu multiplayer do seu Minecraft, clique em **Direct Connection** (Conexão Direta) ou **Add Server** e insira: \`${GAME_HOST}:25565\`"
    else
      echo "⚠️ **Atenção:** O IP público do LoadBalancer ainda está sendo provisionado pela Azure. Tente novamente em alguns instantes."
    fi
    echo ""
    echo "### ☁️ 2. Validação de Recursos da Azure"
    echo ""
    echo "| Recurso Azure | Nome do Recurso | Status de Provisionamento |"
    echo "|---|---|---|"
    echo "| **Resource Group** | \`rg-minecraft-server-prod\` | ${RG_STATUS} |"
    echo "| **Virtual Network** | \`vnet-minecraft-server-prod-bs\` | ${VNET_STATUS} |"
    echo "| **Storage Account** | \`stminecraftserverprod001\` | ${SA_STATUS} |"
    echo "| **Container Registry** | \`acrminecraftserverprod\` | ${ACR_STATUS} |"
    echo "| **Kubernetes Service (AKS)** | \`aks-minecraft-server-prod\` | ${AKS_STATUS} |"
    echo ""
    echo "### ☸️ 3. Estabilidade do Kubernetes & Minecraft"
    echo ""
    echo "| Recurso Kubernetes | Detalhe | Estado de Estabilidade |"
    echo "|---|---|---|"
    echo "| **Namespace** | \`${NAMESPACE}\` | ${K8S_NS_STATUS} |"
    echo "| **StatefulSet (Pod)** | \`mc-server\` | ${K8S_STS_STATUS} |"
    echo "| **Persistent Volume (PVC)** | \`mc-data\` | ${K8S_PVC_STATUS} |"
    echo "| **Serviço de Jogo (Game LB)** | \`mc-server-game\` | ${K8S_SVC_STATUS} |"
    echo "| **Conectividade TCP Externa** | Porta \`25565\` | ${TCP_STATUS} |"
    echo "| **Logs de Inicialização** | Container Log | ${LOG_STATUS} |"
    echo ""
    echo "---"
    echo "*Relatório gerado automaticamente pelo script de teste pós-deploy às $(date -d 'today' '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date).* :robot:"
  } >> "$GITHUB_STEP_SUMMARY"

  # Emitir GitHub Actions Notices/Warnings no fluxo principal
  if [[ -n "$GAME_HOST" ]]; then
    echo "::notice title=Minecraft Server Conexão::🎮 Conecte em: ${GAME_HOST}:25565 (Versao: ${MC_VERSION} - ${MC_TYPE})"
  fi
  if [[ "$FAILED" -eq 0 ]]; then
    echo "::notice title=Pós-Deploy Status::🟢 Todos os recursos estão ativos, estáveis e acessíveis!"
  else
    echo "::warning title=Pós-Deploy Falha::⚠️ Um ou mais recursos críticos falharam nas validações de estabilidade."
  fi
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "[SUCESSO] Testes AKS concluidos sem falhas criticas."
  exit 0
fi

echo "[ERRO] Um ou mais testes criticos falharam."
exit 1
