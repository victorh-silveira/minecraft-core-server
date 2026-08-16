# Surface sync (fechamento de mudanca)

Checklist obrigatorio antes do commit/push final apos mudanca material em codigo, infra, docs ou superficie Cursor.

## Passos

1. Listar arquivos tocados e superficies impactadas em [`agent-coverage.md`](agent-coverage.md).
2. Atualizar docs de engenharia/ops cujo significado operacional mudou.
3. Se contrato/camada/gate mudou, alinhar `.cursor/rules/*.mdc`.
4. Se o procedimento do agente mudou, alinhar `.cursor/skills/*/SKILL.md`.
5. Atualizar [`AGENTS.md`](../AGENTS.md) (tabela de leitura) e a linha correspondente em `agent-coverage.md`.
6. Se o padrao DDD/QA/DX cross-repo mudou, atualizar [`prompt-model.md`](../prompt-model.md).
7. Remover sujeira local (`_tmp*`, caches acidentais); grep por refs stale.
8. Morto comprovado: seguir [`engineering-repo-hygiene.md`](engineering-repo-hygiene.md).
9. Rodar no **WSL**: `make app-lint`, `make app-test`, `make app-security` (ou `pre-commit run --all-files`).
10. Commits Conventional Commits PT-BR; escopo `llm` se so superficie de agentes.

## Nunca

- Commitar so codigo com doutrina/rules/skills desatualizadas
- Pular gates ou baixar cobertura / limite de linhas
- Apagar skill/doc indexado na matriz sem atualizar `agent-coverage` + `AGENTS.md`
- Apagar conteudo de `app/runtime/world` no processo de “higiene”

Skill: `mcs-surface-sync`. Companion: `mcs-precommit`, `mcs-repo-hygiene`.
