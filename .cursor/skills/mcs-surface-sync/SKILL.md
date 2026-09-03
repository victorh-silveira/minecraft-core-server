---
name: mcs-surface-sync
description: >-
  Fecha mudancas sincronizando docs/rules/skills/AGENTS/matriz, rodando gates no
  WSL e removendo sujeira local. Use when finishing a feature, docs/infra update,
  or when the user mentions sync de superficie, fechar PR, atualizar agents, ou
  checklist pos-mudanca.
---

# Surface sync

## Checklist

1. Escopo — arquivos e superficies em `docs/agent-coverage.md`
2. Docs — atualizar `.md` cujo significado operacional mudou
3. Rules — alinhar `.cursor/rules/*.mdc` se contrato/gate mudou
4. Skills — alinhar `.cursor/skills/*/SKILL.md` se procedimento mudou
5. Indices — `AGENTS.md` + linha em `agent-coverage.md` (+ `.cursor/agents/` se subagente mudou)
6. Contrato — `prompt-model.md` se padrao DDD/QA/DX cross-repo mudou
7. Anti-sujeira — sem `_tmp*`, refs stale, imports mortos
8. Higiene pontual — skill `mcs-repo-hygiene` se houver morto no diff
9. Gates — WSL: `make app-lint` + `make app-test` + `make app-security`
10. Commits PT-BR; escopo `llm` se so superficie de agentes

## Docs

`docs/engineering-surface-sync.md`, `docs/agent-coverage.md`, `AGENTS.md`, `prompt-model.md`
