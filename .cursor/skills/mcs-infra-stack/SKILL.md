---
name: mcs-infra-stack
description: >-
  Trabalha Docker Compose local e volumes app/runtime, Dockerfile templates e
  alinhamento com AKS/Terraform do servidor Fabric. Use when editing
  docker-compose, Dockerfile, bind mounts, infra/kubernetes, or when the user
  mentions app/runtime, /data/world, or make docker-build-up.
---

# Infra stack

## Local

1. `infra/docker/.env` a partir do `.env.example`
2. Volumes: `app/runtime/{world,configs,mods,plugins,logs,database}` → `/data/*`
3. `make docker-sync-mods` antes de `make docker-build-up`
4. Validar com `make docker-test`

## Cloud

- Overlay: `infra/kubernetes/overlays/prod`
- Stack: `infra/terraform/live/prod`
- Nao misturar paths antigos (`app/src/domain/world-data`, etc.)

## Docs

`docs/infra-docker.md`, `docs/architecture.md`, `docs/azure.md`, rule `mcs-infra` + `mcs-runtime-data`
