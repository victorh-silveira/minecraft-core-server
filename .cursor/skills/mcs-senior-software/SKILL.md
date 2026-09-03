---
name: mcs-senior-software
description: >-
  Aplica a barra senior de Software Engineer no Python hexagonal e sync de mods
  (DIP, DTO/mapper, resiliencia HTTP, tipagem, TDD por camada). Use when
  implementing or reviewing domain/application/adapters, SyncModsUseCase,
  concurrency, backoff, hash checks, or when the user mentions engenheiro
  senior, DIP, ou engineering-senior-bar.
---

# Senior Software Engineer

## Quando

Mudanca em `app/src/**`, sync de mods, tipagem, concorrencia ou resiliencia HTTP.

## Checklist

1. Camada correta? Domain puro; ports na application; HTTP/FS so em infrastructure
2. Composition root so em `presentation`
3. Adapters mapeiam DTO → dominio (sem vazar schema Modrinth/CurseForge)
4. Hash validado pos-download; falha em mismatch
5. 429/5xx: backoff com jitter no adapter (nao no use case)
6. Logs: `log_event` fora do use case; sem body/secrets
7. TDD: domain → application (fakes) → adapters → presentation
8. `make app-lint` + `make app-validate` + `make app-test` no WSL

## Nao fazer

- Introduzir Redis/OTEL/httpx/S3 sem necessidade do dominio e sem testes
- Logs ou `requests` no use case
- `# type: ignore` para silenciar mypy

## Refs

`docs/engineering-senior-bar.md`, `docs/arquitetura.md`, skills `mcs-hexagonal-tdd`, `mcs-mods-sync`, `mcs-logging-audit`
