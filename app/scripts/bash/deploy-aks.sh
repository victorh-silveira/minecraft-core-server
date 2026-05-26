#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

IMAGE_TAG="${IMAGE_TAG:-$(git describe --tags --abbrev=0 2>/dev/null || echo v1.0.0)}"
IMAGE="ghcr.io/victorh-silveira/minecraft-core-server:${IMAGE_TAG}"
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
