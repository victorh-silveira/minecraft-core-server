# Higienizacao do repositorio

Remover apenas o que estiver **morto com evidencia**. Nao confundir limpeza com destruicao de dados de jogo.

## Evidencia minima

- Vulture / coverage / imports sem uso apontam o simbolo, **ou**
- Nenhum referencia em `app/src`, `app/tests`, `Makefile`, CI, docs e scripts (grep), **ou**
- Path legado ja migrado (ex.: dados movidos para `app/runtime/`) e docs atualizados

## Permitido

- `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, `.coverage` via `make app-clean`
- Modulos Python substituidos pela arquitetura hexagonal
- Docs/rules/skills obsoletos **depois** de atualizar a matriz

## Proibido sem decisao explicita

- Apagar ou “limpar” `app/runtime/world` (mundo do jogador)
- Remover `mods-manifest.json`, `server.properties` versionados, ou templates Docker
- Deletar adapters/ports ainda referenciados pelo composition root
- Remover skill/rule ainda listada em [`agent-coverage.md`](agent-coverage.md)

## Fluxo

1. Provar morte (comando ou grep).
2. Remover o minimo necessario.
3. Atualizar docs/matriz se a superficie sumiu.
4. `make app-lint` + `make app-test`.

Skill: `mcs-repo-hygiene`.
