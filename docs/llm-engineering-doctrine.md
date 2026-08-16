# Doutrina de engenharia com LLM

O LLM e **copiloto de engenharia e auditoria** neste repositorio. Nao e o processo do servidor Minecraft, nao decide politica de jogo e nao substitui gates de qualidade.

## Papel

| E | Nao e |
|---|-------|
| Ajuda a projetar/adaptar codigo hexagonal | Runtime do Fabric / itzg |
| Sugere testes TDD e corrige cobertura | Desculpa para baixar `fail-under` |
| Atualiza docs/rules/skills alinhados ao codigo | Fonte de verdade acima do codigo e do Make |
| Audita imports, logging e higiene | Gerador de stack OTRS/WireMock/MariaDB |

Entrada operacional: [`AGENTS.md`](../AGENTS.md). Matriz: [`agent-coverage.md`](agent-coverage.md). Contrato: [`prompt-model.md`](../prompt-model.md).

## Invariantes

1. `domain` e `application` nao importam `infrastructure` nem `presentation`.
2. Validacao no dominio; composition root so em `presentation`.
3. Domain e use case nao emitem logs; `log_event` na presentation/adapters.
4. Dados do servidor ficam em `app/runtime/`, nunca em `app/src/`.
5. Cobertura 100% branch nas quatro camadas; arquivos `.py` ≤ 300 linhas.
6. Terminal e scripts: **WSL Linux** apenas.
7. Sem comentarios no codigo; docs e commits em PT-BR; sem emojis.
8. Docker/AKS/Terraform existem porque o dominio precisa deles — nao copiar stacks alheias.

## Anti-padroes

- HTTP client, SQL ou framework web em `domain` / `application`
- `print` no sync; dump de manifesto/body HTTP em INFO
- Composition root espalhado fora de `presentation`
- Commitar `.env`, tokens ou JARs de mods
- Atualizar so codigo e deixar `AGENTS.md` / rules / skills mentindo o SSOT
- Afrouxar Ruff/mypy/vulture/coverage “temporariamente” para passar o hook

## Fechamento

Antes do commit final de uma mudanca material: skill `mcs-surface-sync` + [`engineering-surface-sync.md`](engineering-surface-sync.md).
