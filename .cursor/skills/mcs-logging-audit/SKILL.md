---
name: mcs-logging-audit
description: >-
  Audita e corrige logging semantico do sync de mods (log_event, eventos
  mods.sync.*, redact de URL/segredos, ausencia de logs no use case). Use when
  logs dump JSON/HTTP bodies, secrets appear in INFO, or the user mentions
  log_event or engineering-logging.
---

# Logging audit

## Checklist

1. Use case / domain nao chamam logger
2. CLI emite `mods.sync.run.started|finished|failed`
3. Detalhe por mod em DEBUG (`skipped_cached`, `downloaded`, `failed`)
4. `redact_url` e marcadores de segredo ativos
5. `urllib3`/`requests` em WARNING+
6. Testes de presentation/infrastructure cobrem redact

## Docs

`docs/engineering-logging.md`, rule `mcs-logging`
