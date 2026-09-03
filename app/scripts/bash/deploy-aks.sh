#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

IMAGE_DIGEST="${IMAGE_DIGEST:?Defina IMAGE_DIGEST=sha256:...}"
if [[ "${IMAGE_DIGEST}" != sha256:* ]]; then
  echo "[ERRO] IMAGE_DIGEST deve comecar com sha256:"
  exit 1
fi
IMAGE="ghcr.io/victorh-silveira/minecraft-core-server@${IMAGE_DIGEST}"
NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
RCON_PASSWORD="${RCON_PASSWORD:?Defina RCON_PASSWORD}"
WHITELIST_RAW="${MINECRAFT_WHITELIST:-AnonymousNoobz}"
WHITELIST="$(bash app/scripts/bash/resolve-whitelist.sh "${WHITELIST_RAW}")"

kubectl apply -f infra/kubernetes/base/namespace.yaml

kubectl -n "${NAMESPACE}" create secret generic mc-rcon \
  --from-literal=RCON_PASSWORD="${RCON_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "${NAMESPACE}" create secret generic mc-access \
  --from-literal=WHITELIST="${WHITELIST}" \
  --dry-run=client -o yaml | kubectl apply -f -

MANIFEST="$(kubectl kustomize infra/kubernetes/overlays/prod \
  | sed "s|ghcr.io/victorh-silveira/minecraft-core-server:placeholder|${IMAGE}|g")"

printf '%s' "${MANIFEST}" | kubectl apply -f -
kubectl -n "${NAMESPACE}" delete pod mc-server-0 --ignore-not-found --wait=false
kubectl -n "${NAMESPACE}" rollout status statefulset/mc-server --timeout=1200s
bash app/scripts/bash/atualizar-annotations-k8s.sh
