# Logging semantico

API unica: `log_event(logger, level, event, **fields)` em `infrastructure.logging.events`.

A CLI configura o logger em `presentation.logging.setup`. Domain e use case nao emitem logs.

## Eventos

| Evento | Nivel | Quando |
|--------|-------|--------|
| `mods.sync.run.started` | INFO | inicio da execucao |
| `mods.sync.run.finished` | INFO | sucesso (contagens skipped/downloaded) |
| `mods.sync.run.failed` | ERROR | manifesto ausente, payload invalido ou falhas de sync |
| `mods.sync.mod.skipped_cached` | DEBUG | JAR local com hash valido |
| `mods.sync.mod.downloaded` | DEBUG | JAR baixado |
| `mods.sync.mod.failed` | ERROR | falha por mod |

Caminho feliz: duas linhas INFO (`started` e `finished`). Detalhe por mod fica em DEBUG.

## Anti-poluicao

- Nao logar JSON do manifesto nem body HTTP em INFO.
- URLs com query string viram `?***`.
- Campos com `password`, `token`, `secret` ou `api_key` viram `***`.
- `exc_info` apenas em DEBUG quando o campo `error` esta presente.
- Loggers `urllib3` e `requests` em WARNING.

## Exemplo (INFO)

```text
INFO event=mods.sync.run.started manifest=app/runtime/mods/mods-manifest.json mods_dir=app/runtime/mods
INFO event=mods.sync.run.finished downloaded=1 skipped=0
```
