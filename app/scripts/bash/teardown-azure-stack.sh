#!/usr/bin/env bash
set -euo pipefail

RG_MAIN="${TFSTATE_RG:-rg-minecraft-server-prod}"
RG_NODES="${AKS_NODES_RG:-rg-minecraft-server-nodes-prod}"

if ! command -v az >/dev/null 2>&1; then
  echo "[ERRO] Azure CLI nao encontrado"
  exit 1
fi

echo ">>> Removendo resource group de nodes (se existir)..."
if az group show --name "${RG_NODES}" >/dev/null 2>&1; then
  az group delete --name "${RG_NODES}" --yes --no-wait
  echo "Delete de ${RG_NODES} iniciado."
else
  echo "${RG_NODES} nao encontrado."
fi

echo ">>> Removendo resource group principal (RG, storage, tfstate)..."
if az group show --name "${RG_MAIN}" >/dev/null 2>&1; then
  az group delete --name "${RG_MAIN}" --yes
  echo "Delete de ${RG_MAIN} concluido."
else
  echo "${RG_MAIN} nao encontrado."
fi

echo "[SUCESSO] Stack Azure removida."
