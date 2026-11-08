---
name: mcs-surface-sync
description: >-
  Fecha tarefas materiais sincronizando documentacao tecnica, regras, skills, matriz de agentes
  e executando a esteira de verificacao no WSL antes do commit. Use when finishing a feature,
  closing a task, or preparing a PR.
---

# Habilidade: mcs-surface-sync

Procedimento mandatorio para fechamento de mudancas e sincronizacao de superficies do repositorio.

## Procedimento de Fechamento

1. Mapeamento de Superficies Afetadas:
   - Consulte `docs/agent-coverage.md` para identificar quais documentos, regras e skills correspondem aos arquivos alterados no diff.

2. Sincronizacao de Documentacao e Regras:
   - Se um comportamento ou contrato de dominio mudou, atualize o documento em `docs/`.
   - Se uma nova regra de governanca ou procedimento de agente foi alterado, atualize o arquivo correspondente em `.agents/rules/*.mdc` ou `.agents/skills/*/SKILL.md`.
   - Atualize `AGENTS.md` e a matriz em `docs/agent-coverage.md`.

3. Execucao de Teste Automatizado da Matriz:
   - Execute o teste de integridade da matriz no terminal WSL:
     ```bash
     pytest app/tests/unit/infrastructure/test_agent_coverage_matrix.py
     ```

4. Execucao dos Portoes de Qualidade:
   - Execute a suite completa de verificacoes:
     ```bash
     make app-lint
     make app-validate
     make app-security
     make app-test
     ```

5. Formatacao da Mensagem de Commit:
   - Prepare o commit respeitando Conventional Commits em PT-BR:
     `tipo(escopo): descricao concisa`
     (seguido de linha em branco e corpo detalhado com linhas <= 100 caracteres).
   - Use o escopo `llm` quando a alteracao for restrita ao harness de IA.
