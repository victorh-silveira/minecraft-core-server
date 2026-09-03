---
name: mcs-senior-cloud-ops
description: >-
  Aplica a barra senior de Cloud Ops (Docker multi-stage/PID1, Compose paridade,
  Kustomize probes, Terraform OIDC, AKS Workload Identity, CI skip-cd e Trivy).
  Use when editing Dockerfile, compose, kubernetes, terraform, GitHub Actions,
  secrets/Key Vault, or when the user mentions DevOps senior, OIDC, PDB, ou
  engineering-senior-bar.
---

# Senior Cloud Ops

## Quando

Mudanca em `infra/**`, `.github/**`, secrets, probes, deploy ou imagem.

## Checklist

1. Docker: cache de camadas, non-root, signal/PID1, Hadolint limpo
2. Compose: healthcheck com start_period; volumes so `app/runtime/*`
3. K8s: startup/readiness/liveness distintos; ConfigMap/Secret; overlay correto
4. Terraform: modulo isolado; state seguro; sem credencial estatica
5. Identidade: OIDC + Workload Identity; tokens so em Key Vault/runtime
6. CI: QA intacto; `[skip-cd]` nao pula lint/test/security
7. Imagem imutavel (SHA); Trivy sem CRITICAL/HIGH com fix
8. Validar: `kubeconform` no `kustomize build`; gates Make no WSL

## Nao fazer

- `latest` em prod; secret no YAML commitado
- Um unico probe para tudo
- Spot em path critico do servidor de jogo sem PDB/plano de queda

## Refs

`docs/engineering-senior-bar.md`, `docs/infra-docker.md`, `docs/architecture.md`, `docs/azure.md`, skills `mcs-infra-stack`, `mcs-ops-runbook`
