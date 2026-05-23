#!/usr/bin/env bash
set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:-victorh-silveira}"
GITHUB_REPO="${GITHUB_REPO:-minecraft-server}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-28c9f836-6ad3-45a3-8c33-36531a68fe51}"
TENANT_ID="${TENANT_ID:-8d4a2319-f160-4911-aa05-1875d2772226}"
APP_NAME="${APP_NAME:-github-minecraft-server-actions}"
APP_ID="${APP_ID:-}"
TFSTATE_RG="${TFSTATE_RG:-rg-minecraft-server-prod}"
TFSTATE_SA="${TFSTATE_SA:-stminecraftserverprod001}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="${WORKDIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
TMPDIR="${TMPDIR:-${WORKDIR}/.azure-setup-tmp}"

az_tsv() {
  az "$@" -o tsv | tr -d '\r'
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Comando obrigatorio ausente: $1" >&2
    exit 1
  }
}

warn_windows_az() {
  if command -v az >/dev/null 2>&1; then
    if readlink -f "$(command -v az)" 2>/dev/null | grep -qi "/mnt/c/"; then
      echo "Aviso: az do Windows via WSL. Recomendado: sudo apt install azure-cli (Linux nativo no WSL)."
    fi
  fi
}

wait_for_sp() {
  local app_id="$1"
  local attempt
  for attempt in $(seq 1 12); do
    if az ad sp show --id "$app_id" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  return 1
}

ensure_app_and_sp() {
  if [ -z "$APP_ID" ]; then
    APP_ID="$(az_tsv ad app list --display-name "$APP_NAME" --query "[0].appId")"
  fi
  if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
    APP_ID="$(az_tsv ad app create --display-name "$APP_NAME" --query appId)"
    echo "App Registration criado: $APP_ID"
    sleep 10
  else
    echo "App Registration existente: $APP_ID"
  fi

  OBJECT_ID="$(az_tsv ad app show --id "$APP_ID" --query id)"

  if ! az ad sp show --id "$APP_ID" >/dev/null 2>&1; then
    for attempt in $(seq 1 5); do
      if az ad sp create --id "$APP_ID" >/dev/null 2>&1; then
        break
      fi
      echo "Aguardando propagacao do App Registration (tentativa ${attempt}/5)..."
      sleep 10
    done
  fi

  wait_for_sp "$APP_ID"
  SP_OBJECT_ID="$(az_tsv ad sp show --id "$APP_ID" --query id)"
}

create_federated_cred() {
  local name="$1"
  local subject="$2"
  local payload="$TMPDIR/${name}.json"
  mkdir -p "$TMPDIR"
  cat >"$payload" <<JSON
{
  "name": "${name}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${subject}",
  "description": "GitHub Actions ${name}",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
  if az ad app federated-credential show --id "$OBJECT_ID" --federated-credential-id "$name" >/dev/null 2>&1; then
    echo "Federated credential ja existe: $name"
    return 0
  fi
  local param_ref="@${payload}"
  if command -v wslpath >/dev/null 2>&1 && readlink -f "$(command -v az)" 2>/dev/null | grep -qi "/mnt/c/"; then
    param_ref="@$(wslpath -w "$payload")"
  fi
  az ad app federated-credential create --id "$OBJECT_ID" --parameters "${param_ref}"
  echo "Federated credential criada: $name"
}

assign_roles() {
  az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Contributor" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" \
    >/dev/null 2>&1 || echo "Role Contributor ja atribuida ou sem permissao para criar"

  az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "User Access Administrator" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" \
    >/dev/null 2>&1 || echo "Role User Access Administrator ja atribuida ou sem permissao para criar"

  if az storage account show --name "$TFSTATE_SA" --resource-group "$TFSTATE_RG" >/dev/null 2>&1; then
    az role assignment create \
      --assignee-object-id "$SP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Storage Blob Data Contributor" \
      --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${TFSTATE_RG}/providers/Microsoft.Storage/storageAccounts/${TFSTATE_SA}" \
      >/dev/null 2>&1 || echo "Role Storage Blob Data Contributor (SA) ja atribuida"
  else
    echo "Storage account ${TFSTATE_SA} ainda nao existe. Rode deploy-infra ou terraform apply em live/prod."
  fi
}

setup_github() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI nao encontrado. Configure secrets manualmente no GitHub."
    return 0
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "Execute: gh auth login"
    echo "Depois rode novamente este script ou configure secrets manualmente."
    return 0
  fi
  local repo="${GITHUB_ORG}/${GITHUB_REPO}"
  local env_name
  for env_name in production production-infra production-destroy; do
    gh api "repos/${repo}/environments/${env_name}" -X PUT --input - <<< "{}" >/dev/null
    echo "Environment criado ou atualizado: ${env_name}"
  done
  gh secret set AZURE_CLIENT_ID --body "$APP_ID" --repo "$repo"
  gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo "$repo"
  gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID" --repo "$repo"
  if ! gh secret list --repo "$repo" | grep -q "^RCON_PASSWORD"; then
    RCON_PASSWORD="$(openssl rand -base64 32 | tr -d '\n')"
    gh secret set RCON_PASSWORD --body "$RCON_PASSWORD" --repo "$repo"
    echo "RCON_PASSWORD gerada e salva no GitHub Secrets"
  else
    echo "RCON_PASSWORD ja existe no GitHub (nao alterada)"
  fi
  echo "Environments e secrets GitHub configurados."
}

main() {
  require_cmd az
  warn_windows_az
  cd "$WORKDIR"
  mkdir -p "$TMPDIR"
  az account set --subscription "$SUBSCRIPTION_ID"
  ensure_app_and_sp
  create_federated_cred "github-ref-main" "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main"
  create_federated_cred "github-env-production" "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:production"
  create_federated_cred "github-env-production-infra" "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:production-infra"
  create_federated_cred "github-env-production-destroy" "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:production-destroy"
  assign_roles
  setup_github
  echo ""
  echo "=== Resumo ==="
  echo "AZURE_CLIENT_ID=${APP_ID}"
  echo "AZURE_TENANT_ID=${TENANT_ID}"
  echo "AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}"
  echo "APP_OBJECT_ID=${OBJECT_ID}"
  echo "SP_OBJECT_ID=${SP_OBJECT_ID}"
  echo ""
  echo "GitHub: Settings > Actions > General > Workflow permissions > Read and write"
  echo "Ordem: CD Infra (APPLY_INFRA) -> CD (release ou tag vX.Y.Z)"
}

main "$@"
