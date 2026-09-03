---
name: mcs-ops-runbook
description: >-
  Operacao do servidor Fabric (Make docker/k8s, backup de mundo, RCON,
  annotations, troubleshooting). Use when the user mentions docker-logs,
  k8s-deploy, backup world, whitelist, RCON, or operations checklist.
---

# Ops runbook

## Local

- Subir: `make app-setup` → `make docker-up`
- Logs: `make docker-logs`; shell: `make docker-sh`
- Backup mundo: `app/runtime/world` com servidor parado

## AKS

- `make k8s-apply` / `make k8s-annotate` / `make k8s-test`
- Migrar mundo: `kubectl cp` de `app/runtime/world`
- RCON via port-forward do Service ClusterIP

## Docs

`docs/operations.md`, `docs/access-and-hostname.md`, rule `mcs-scripts`
