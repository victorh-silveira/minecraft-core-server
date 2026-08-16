---
name: mcs-mods-sync
description: >-
  Altera ou diagnostica o sync de mods Fabric (manifesto JSON, Modrinth,
  CurseForge, SHA-256, CLI run.py, make docker-sync-mods). Use when editing
  mods-manifest, resolvers, LocalJarStore, SyncModsUseCase, or when jars fail
  to download or hash-check.
---

# Mods sync

## Passos

1. Conferir `app/runtime/mods/mods-manifest.json` (id, version, source, slug/url, sha256)
2. Rodar `make docker-sync-mods` ou `python run.py` no WSL
3. Falha de resolve: source, slug, versao Minecraft/loader
4. Falha de hash: atualizar sha256 no manifesto ou redownload
5. Testes: unit application/infrastructure + integration Modrinth transport
6. JARs nao entram no Git

## Docs

`docs/arquitetura.md`, `docs/configuration.md`, rule `mcs-mods-sync`
