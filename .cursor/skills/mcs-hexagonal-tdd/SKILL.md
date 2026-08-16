---
name: mcs-hexagonal-tdd
description: >-
  Implementa mudancas no codigo Python hexagonal com TDD por camada (domain →
  application com fakes → adapters → presentation). Use when adding entities,
  use cases, ports, adapters, CLI wiring, or when the user mentions DDD,
  hexagonal, ports, SyncModsUseCase, or coverage por camada.
---

# Hexagonal TDD

## Ordem

1. Domain: entidade/VO/service + testes em `tests/unit/domain/`
2. Application: port + use case com fakes + `tests/unit/application/`
3. Infrastructure: adapter HTTP/FS/JSON + `tests/unit/infrastructure/`
4. Presentation: composition root + logs + `tests/unit/presentation/`
5. Integracao HTTP mock se tocar transporte externo
6. `make app-lint` + `make app-test`

## Regras

- Domain/application sem infrastructure/presentation
- Use case sem logs e sem `requests`
- Composition root so em `presentation`
- Arquivo ≤ 300 linhas; cov 100% branch

## Docs

`docs/arquitetura.md`, `docs/structure.md`, rules `mcs-hexagonal`, `mcs-domain-pure`, `mcs-testing`
