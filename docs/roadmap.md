# Roadmap e gaps conhecidos

Documento derivado da revisao arquitetural do projeto. Prioridades para evolucao em direcao a Clean Architecture, DRY, SOLID, DDD e DevOps completos.

## Scorecard atual

| Pilar | Nota | Resumo |
|-------|------|--------|
| Clean Architecture | 7/10 | Pastas corretas; codigo em `app/scripts/python/` |
| DRY | 6/10 | `.env` bom; config duplicada properties/env |
| SOLID | 6/10 | Script testado; sem abstracoes |
| DDD | 6/10 | Estrutural sim; tatico nao |
| DevOps | 8/10 | Docker/Makefile/pre-commit fortes; sem CI |

---

## Prioridade 1 — Configuracao unica (DRY)

**Problema:** `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` em `.env` **e** `server.properties`.

**Acao:** Adotar Opcao A ou B descrita em [configuration.md](configuration.md).

**Criterio de done:** Uma unica fonte de verdade documentada; teste manual de boot OK.

---

## Prioridade 2 — Sincronizar `.env` local

**Problema:** `.env` pode ficar desatualizado vs `.env.example`.

**Acao:**

- Comparar chaves entre arquivos
- Adicionar secao Docker Build no `.env` real
- Script ou check no `docker-env-check` (futuro)

---

## Prioridade 3 — CI/CD minimo

**Problema:** Quality gates so locais (pre-commit).

**Acao:** GitHub Actions com:

- `pip install -r app/requirements-dev.txt`
- `cd app && python -m infrastructure.mods`
- `clean_workspace.py --stage lint|test|security`
- `docker compose config`

**Arquivo sugerido:** `.github/workflows/ci.yml`

---

## Prioridade 4 — Pin de versao da imagem base

**Problema:** `DOCKER_BASE_IMAGE=itzg/minecraft-server:latest` e instavel.

**Acao:** Fixar tag testada (ex.: digest ou tag `java21-2024.x`).

**Criterio de done:** `.env.example` documenta tag pinada; rebuild reproduzivel.

---

## Prioridade 5 — Reorganizar `sync_mods` (Clean Architecture)

**Status:** Concluido.

Modulos em `app/src/infrastructure/mods/` com `ModResolver`, entrypoints `python -m infrastructure.mods` e `app/scripts/python/sync_mods.py`.

---

## Prioridade 6 — SOLID (providers)

**Problema:** Acoplamento direto a `requests` e paths globais.

**Acao:**

- Interface `ModProvider` com `resolve()` e `download()`
- Injecao de `ManifestPath`, `ModsDir`, `HttpClient` nos testes

---

## Prioridade 7 — Ambientes (Compose profiles)

**Problema:** Um unico `docker-compose.yml` para dev/prod.

**Acao:**

- `docker-compose.override.yml` (local, gitignored) ou
- Profiles `dev` / `prod` com limites de recurso distintos

---

## Prioridade 8 — Segredos

**Problema:** `RCON_PASSWORD` apenas em `.env` plano.

**Acao (producao):**

- Docker Secrets ou vault externo
- Documentar rotacao de senha

---

## Prioridade 9 — Observabilidade

**Problema:** Sem metricas exportadas.

**Acao futura:**

- Plugin Prometheus para Minecraft ou sidecar
- Alertas em healthcheck failing

---

## Prioridade 10 — Backup automatizado

**Problema:** Backup manual via PowerShell.

**Acao:**

- Script `scripts/powershell/backup_world.ps1` ou job agendado
- Retencao N dias documentada

---

## Itens concluidos neste ciclo

- [x] Estrutura `src/` Clean Architecture
- [x] Docker Compose parametrizado (DRY)
- [x] Dockerfile + `.dockerignore` categorizado
- [x] Makefile `docker-*`
- [x] Pre-commit (lint, test, security)
- [x] Testes 100% em `infrastructure.mods`
- [x] Documentacao `README.md` e `docs/`
- [x] Lockfile de mods + sync idempotente

---

## Ramificacao de mods (processo)

1. Branch `feature/atualizar-mods`
2. Alterar manifesto
3. Testar container isolado
4. Merge em `main` apos validacao

Este fluxo e **governanca**, nao automacao — CI pode reforcar no futuro.
