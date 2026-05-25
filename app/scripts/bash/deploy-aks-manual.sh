#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

IMAGE_TAG="${IMAGE_TAG:-v1.10.0}"
IMAGE="acrminecraftserverprod.azurecr.io/minecraft-core-server:${IMAGE_TAG}"
NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
RCON_PASSWORD="${RCON_PASSWORD:-deploy-test-local}"
WHITELIST_RAW="${MINECRAFT_WHITELIST:-AnonymousNoobz}"
WHITELIST="$(bash app/scripts/bash/resolve-whitelist.sh "${WHITELIST_RAW}")"

kubectl apply -f infra/kubernetes/base/namespace.yaml

kubectl -n "${NAMESPACE}" create secret generic mc-rcon \
  --from-literal=RCON_PASSWORD="${RCON_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "${NAMESPACE}" create secret generic mc-access \
  --from-literal=WHITELIST="${WHITELIST}" \
  --dry-run=client -o yaml | kubectl apply -f -

BACKUP_CLIENT_ID="$(az identity show \
  -g rg-minecraft-server-prod \
  -n id-mc-world-backup-prod \
  --query clientId -o tsv 2>/dev/null || true)"

MANIFEST="$(kubectl kustomize infra/kubernetes/overlays/prod \
  | sed "s|acrminecraftserverprod.azurecr.io/minecraft-core-server:placeholder|${IMAGE}|g")"

if [[ -n "${BACKUP_CLIENT_ID}" ]]; then
  MANIFEST="$(printf '%s' "${MANIFEST}" \
    | sed "s|BACKUP_AZURE_CLIENT_ID_PLACEHOLDER|${BACKUP_CLIENT_ID}|g")"
fi

printf '%s' "${MANIFEST}" | kubectl apply -f -

kubectl -n "${NAMESPACE}" delete pod mc-server-0 --ignore-not-found --wait=false
kubectl -n "${NAMESPACE}" rollout status statefulset/mc-server --timeout=1200s

bash app/scripts/bash/atualizar-annotations-k8s.sh
bash app/scripts/bash/publicar-annotations-github.sh live
