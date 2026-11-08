---
name: mcs-precommit
description: >-
  Executa, diagnostica e corrige falhas nos hooks de pre-commit e commitlint locais.
  Garante que todo commit respeite a esteira de verificacoes em lote antes de ser persistido.
  Use when git commit fails, pre-commit hooks report errors, or testing pre-commit batch runs.
---

# Habilidade: mcs-precommit

Procedimento para resolucao de falhas em hooks de pre-commit e conformidade com commitlint.

## Diagnostico e Execucao

1. Execucao de Verificacao em Lote:
   - Para rodar toda a suite de hooks em todos os arquivos rastreados via WSL:
     ```bash
     make app-pre-commit-run
     ```
   - Essa esteira aciona os estagios `lint`, `security`, `test`, `validate` e `build` de forma orquestrada.

2. Resolucao de Falhas de Formatacao e Estilo:
   - Se o hook do Ruff falhar, aplique a autocorrecao e formatacao:
     ```bash
     ruff check --fix app/src app/tests app/scripts run.py
     ruff format app/src app/tests app/scripts run.py
     ```

3. Resolucao de Falhas de Commitlint:
   - O commitlint exige o formato: `tipo(escopo): assunto em letras minusculas` seguido de linha em branco e corpo explicativo.
   - Os escopos permitidos estao em `linters/commitlint.config.mjs`:
     `all`, `application`, `config`, `deps`, `docker`, `domain`, `infra`, `llm`, `mods`, `presentation`, `release`, `repo`, `runtime`, `scripts`, `test`, `tools`.
   - Limite do corpo do commit: Nenhuma linha do corpo do commit deve ultrapassar 100 caracteres.
