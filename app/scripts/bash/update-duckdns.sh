#!/usr/bin/env bash
set -euo pipefail

DUCKDNS_TOKEN="${DUCKDNS_TOKEN:-}"
DUCKDNS_DOMAIN="${DUCKDNS_DOMAIN:-}"
NAMESPACE="${NAMESPACE:-minecraft-server-prod}"

if [[ -z "$DUCKDNS_TOKEN" || -z "$DUCKDNS_DOMAIN" ]]; then
  echo "Defina DUCKDNS_TOKEN e DUCKDNS_DOMAIN (ex: meuservidor.duckdns.org)."
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl nao encontrado."
  exit 1
fi

IP="$(kubectl -n "$NAMESPACE" get svc mc-server-game -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [[ -z "$IP" ]]; then
  echo "LoadBalancer sem IP externo."
  exit 1
fi

SUBDOMAIN="${DUCKDNS_DOMAIN%%.duckdns.org}"
RESPONSE="$(curl -fsS "https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=${IP}")"

if [[ "$RESPONSE" == "OK" ]]; then
  echo "DuckDNS atualizado: ${DUCKDNS_DOMAIN} -> ${IP}"
  exit 0
fi

echo "Falha ao atualizar DuckDNS: ${RESPONSE}"
exit 1
