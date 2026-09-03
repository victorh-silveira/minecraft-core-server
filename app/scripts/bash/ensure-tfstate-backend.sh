#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${ROOT}"

RG_NAME="${TFSTATE_RG:-rg-minecraft-server-prod}"
LOCATION="${AZURE_LOCATION:-brazilsouth}"
SA_NAME="${TFSTATE_SA:-stminecraftserverprod001}"
TFSTATE_CONTAINER="${TFSTATE_CONTAINER:-tfstate}"

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

echo ">>> Habilitando versionamento e soft-delete de blob..."
az storage account blob-service-properties update \
  --account-name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 14 \
  --output none

echo ">>> Garantindo container ${TFSTATE_CONTAINER}..."
az storage container create \
  --name "${TFSTATE_CONTAINER}" \
  --account-name "${SA_NAME}" \
  --auth-mode login \
  --output none

echo "[SUCESSO] Backend Terraform pronto (${SA_NAME}/${TFSTATE_CONTAINER}) com versioning e soft-delete."
