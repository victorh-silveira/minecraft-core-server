#!/usr/bin/env bash
set -euo pipefail

APP_ID="${APP_ID:-b96f9725-baa9-4f08-a302-3a4e4849f564}"
ORG="${GITHUB_ORG:-victorh-silveira}"
REPO="${GITHUB_REPO:-minecraft-core-server}"
TMPDIR="${TMPDIR:-/tmp}"

update_cred() {
  local id="$1"
  local subject="$2"
  local payload="${TMPDIR}/fed-${id}.json"
  cat >"${payload}" <<JSON
{
  "name": "${id}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${subject}",
  "description": "GitHub Actions ${id}",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
  local param_ref="@${payload}"
  if command -v wslpath >/dev/null 2>&1 && readlink -f "$(command -v az)" 2>/dev/null | grep -qi "/mnt/c/"; then
    param_ref="@$(wslpath -w "${payload}")"
  fi
  az ad app federated-credential update --id "${APP_ID}" --federated-credential-id "${id}" --parameters "${param_ref}"
  echo "Atualizado: ${id} -> ${subject}"
}

update_cred "github-ref-main" "repo:${ORG}/${REPO}:ref:refs/heads/main"
update_cred "github-env-production" "repo:${ORG}/${REPO}:environment:production"
update_cred "github-env-production-infra" "repo:${ORG}/${REPO}:environment:production-infra"
update_cred "github-env-production-destroy" "repo:${ORG}/${REPO}:environment:production-destroy"

az ad app federated-credential list --id "${APP_ID}" --query "[].{name:name,subject:subject}" -o table
