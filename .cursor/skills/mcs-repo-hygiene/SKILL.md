---
name: mcs-repo-hygiene
description: >-
  Remove codigo ou pastas mortas com evidencia (vulture, coverage, grep),
  preservando app/runtime e artefatos versionados do jogo. Use when cleaning
  legacy paths, dead modules, or when the user mentions higiene or codigo morto.
---

# Repo hygiene

## Passos

1. Provar morte (vulture / coverage miss / grep sem refs)
2. Remover o minimo
3. Atualizar docs/matriz se superficie sumiu
4. `make app-lint` + `make app-test`
5. Nunca apagar `app/runtime/world` como limpeza

## Docs

`docs/engineering-repo-hygiene.md`, rule `mcs-repo-hygiene`
