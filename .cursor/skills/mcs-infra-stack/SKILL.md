---
name: mcs-infra-stack
description: >-
  Trabalha Docker Compose local e volumes app/runtime, Dockerfile templates e
  alinhamento com AKS/Terraform do servidor Forge. Use when editing
  docker-compose, Dockerfile, bind mounts, infra/kubernetes, or when the user
  mentions app/runtime, /data/world, or make docker-up.
---

# Infra stack

## Local

1. `infra/docker/.env` a partir do `.env.example`
2. Volume: `app/runtime` → `/data`, preservando operacoes atomicas de migracao do mundo
3. `make docker-up` (valida manifesto vazio + build + up)
4. Validar com `make docker-smoke`: status Minecraft local, LAN, IP WAN via JSON ipify e DNS/WAN
5. Configurar `SMOKE_LAN_HOST`, `SMOKE_WAN_PORT`, `SMOKE_DNS_HOST`, `SMOKE_STARTUP_TIMEOUT_SEC` e `SMOKE_EXPECTED_MOTD` no `.env`
6. Manter `MINECRAFT_MAX_MEMORY` abaixo de `DOCKER_MEMORY_LIMIT`, com no minimo 25% para memoria nativa
7. Usar uma replica por world; escalar verticalmente com `DOCKER_CPU_LIMIT` e limites de memoria
8. Manter root filesystem somente leitura, `/data` gravavel e `/tmp` volátil limitado
9. Validar instalacao Forge limpa antes de remover ferramentas herdadas da imagem

## Cloud

- Overlay: `infra/kubernetes/overlays/prod`
- Stack: `infra/terraform/live/prod`
- Nao misturar paths antigos (`app/src/domain/world-data`, etc.)

## Docs

`docs/infra-docker.md`, `docs/architecture.md`, `docs/azure.md`, rule `mcs-infra` + `mcs-runtime-data`
