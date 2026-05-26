#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${ROOT}"

RG_NAME="${TFSTATE_RG:-rg-minecraft-server-prod}"
LOCATION="${AZURE_LOCATION:-brazilsouth}"
SA_NAME="${TFSTATE_SA:-stminecraftserverprod001}"
TFSTATE_CONTAINER="${TFSTATE_CONTAINER:-tfstate}"
BACKUP_CONTAINER="${BACKUP_CONTAINER:-world-backups}"

if ! command -v az >/dev/null 2>&1; then
  echo "[ERRO] Azure CLI nao encontrado"
  exit 1
fi

echo ">>> Garantindo resource group ${RG_NAME}..."
if ! az group show --name "${RG_NAME}" >/dev/null 2>&1; then
  az group create --name "${RG_NAME}" --location "${LOCATION}" --output none
  echo "Resource group criado."
else
  echo "Resource group ja existe."
fi

echo ">>> Garantindo storage account ${SA_NAME}..."
if ! az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" >/dev/null 2>&1; then
  az storage account create \
    --name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output none
  echo "Storage account criada."
else
  echo "Storage account ja existe."
fi

echo ">>> Garantindo containers de blob..."
az storage container create \
  --name "${TFSTATE_CONTAINER}" \
  --account-name "${SA_NAME}" \
  --auth-mode login \
  --output none 2>/dev/null || true
az storage container create \
  --name "${BACKUP_CONTAINER}" \
  --account-name "${SA_NAME}" \
  --auth-mode login \
  --output none 2>/dev/null || true

echo "[SUCESSO] Backend Terraform pronto (${SA_NAME}/${TFSTATE_CONTAINER})."
