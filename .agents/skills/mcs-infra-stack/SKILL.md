---
name: mcs-infra-stack
description: >-
  Opera o ciclo de vida local do servidor Forge via Docker Compose, gerencia volumes
  em app/runtime, mantem o Dockerfile e alinha a infraestrutura local com o Kubernetes (AKS).
  Use when editing docker-compose.yml, Dockerfile, bind mounts, or running make docker-up.
---

# Habilidade: mcs-infra-stack

Procedimento operacional para gestao da stack Docker local e manipulacao segura dos volumes de dados de jogo.

## Procedimento Passo a Passo

1. Configuracao de Variaveis:
   - Certifique-se de que `infra/docker/.env` existe baseado em `infra/docker/.env.example`:
     ```bash
     cp infra/docker/.env.example infra/docker/.env
     ```
   - Confirme a definicao de `FORGE_VERSION=66.0.6` e `SERVER_PORT=25565`.

2. Inicializacao do Servidor Local:
   - Execute a inicializacao e acompanhe os logs no terminal WSL:
     ```bash
     make docker-up
     make docker-logs
     ```
   - Verifique se o servidor Forge iniciou completamente e aguarda conexoes na porta configurada.

3. Validacao Estatica e Smoke Tests:
   - Execute o smoke test automatizado do Compose:
     ```bash
     make docker-smoke
     ```
   - Verifique a sintaxe e seguranca do Dockerfile com Hadolint:
     ```bash
     hadolint infra/docker/Dockerfile
     ```

4. Paridade com Kubernetes:
   - Certifique-se de que qualquer nova variavel de ambiente ou parametro adicionado ao `docker-compose.yml` seja espelhado no ConfigMap correspondente em `infra/kubernetes/base/configmap.yaml`.
