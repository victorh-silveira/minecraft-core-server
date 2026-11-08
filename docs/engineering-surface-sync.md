# Sincronizacao de Superficie (Surface Sync)

Checklist e protocolo mandatorio a ser executado antes da finalizacao e persistencia de qualquer alteracao relevante em codigo, infraestrutura, documentacao ou harness de agentes.

## 1. Etapas do Protocolo de Sincronizacao

1. Mapeamento de Impacto: Identifique todas as superficies tocadas no diff consultando a matriz em [`agent-coverage.md`](agent-coverage.md).
2. Atualizacao Documental: Atualize os documentos tecnicos cujo significado operacional ou especificacao tenha sido alterado pela mudanca.
3. Alinhamento de Regras de Governanca: Caso contratos, limites de qualidade ou regras de camada tenham mudado, atualize as regras correspondentes em [`.agents/rules/*.mdc`](../.agents/rules/).
4. Alinhamento de Habilidades Operacionais: Caso procedimentos de execucao ou rotinas tenham mudado, atualize as habilidades em [`.agents/skills/*/SKILL.md`](../.agents/skills/).
5. Atualizacao dos Indices Mestres: Atualize a tabela de roteamento de [`AGENTS.md`](../AGENTS.md), as entradas em `docs/agent-coverage.md` e os subagentes em `.agents/agents/` se houver alteracao de personas.
6. Contrato Geral de Engenharia: Atualize [`prompt-model.md`](../prompt-model.md) se os padroes de scaffold, camadas ou DX forem modificados.
7. Higiene Ativa: Remova quaisquer arquivos temporarios, caches locais ou referencias orfas geradas durante o desenvolvimento.
8. Execucao de Gates no WSL Linux:
   ```bash
   make app-lint
   make app-validate
   make app-security
   make app-test
   ```
9. Validacao da Matriz Automatizada:
   ```bash
   pytest app/tests/unit/infrastructure/test_agent_coverage_matrix.py
   ```
10. Mensagem de Commit Padronizada: Formate a mensagem segundo o padrao Conventional Commits em PT-BR, utilizando o escopo `llm` se a mudanca for exclusiva do harness de agentes.

## 2. Proibicoes Expressas

- Nunca commitar codigo sem atualizar a respectiva documentacao, regras de agentes e skills operacionais.
- Nunca commitar alteracoes com testes pendentes ou falhas nos gates de qualidade.
