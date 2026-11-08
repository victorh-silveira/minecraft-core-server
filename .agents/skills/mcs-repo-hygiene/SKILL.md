---
name: mcs-repo-hygiene
description: >-
  Audita e remove codigo morto, variaveis nao utilizadas, dependencias orfas e arquivos
  temporarios com base em evidencias estaticas. Use when cleaning unused code, removing
  obsolete modules, or addressing Vulture and dead code findings.
---

# Habilidade: mcs-repo-hygiene

Procedimento de limpeza e higienizacao de codigo e arquivos no repositorio.

## Procedimento de Limpeza

1. Inspecao com Vulture:
   - Execute o analisador de codigo morto no terminal WSL:
     ```bash
     vulture app/src app/scripts/operations run.py
     ```
   - Avalie cada achado com confianca acima de 70%.

2. Confirmacao de Referencias:
   - Antes de remover qualquer funcao ou classe, execute uma busca global para confirmar se nao e referenciada dinamicamente:
     ```bash
     git grep "nome_do_simbolo"
     ```

3. Exclusao Segura:
   - Remova o codigo morto e execute os testes unitarios para garantir que nao houve regressao:
     ```bash
     make app-test
     ```

4. Limpeza de Caches Locais:
   - Acione a limpeza de diretorios temporarios pelo orquestrador:
     ```bash
     python app/scripts/operations/clean_workspace.py --stage clean
     ```
