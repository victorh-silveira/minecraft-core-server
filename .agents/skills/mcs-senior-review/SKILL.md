---
name: mcs-senior-review
description: >-
  Executa auditoria senior e revisao de codigo/infraestrutura contra as diretrizes do MCS
  (arquitetura hexagonal, pureza do dominio, TDD 100%, seguranca Trivy/Gitleaks e commitlint).
  Use when asked to review changes, audit pull requests, or inspect code quality.
---

# Habilidade: mcs-senior-review

Roteiro de revisao tecnica aprofundada para validacao de PRs e alteracoes materiais no repositorio.

## Fases de Revisao

1. Analise de Fronteiras Arquiteturais:
   - Inspecione a separacao das camadas:
     - `domain`: Pureza estrita, sem bibliotecas externas, sem chamadas de I/O.
     - `application`: Use cases orquestrando logica pura apoiados por ports abstratos.
     - `infrastructure`: Adaptadores concretos com conversao DTO para entidade e resiliencia de conexao.
     - `presentation`: Composition root e parsing de argumentos CLI.

2. Verificacao de Limites e Metricas:
   - Verifique que nenhum arquivo Python ultrapassa 300 linhas de codigo.
   - Verifique a ausencia de comentarios no codigo e ausencia de emojis em qualquer arquivo.
   - Confirme 100% de cobertura branch sob `make app-test`.

3. Auditoria de Seguranca e Gates:
   - Execute no terminal WSL:
     ```bash
     make app-lint
     make app-validate
     make app-security
     make app-test
     ```
   - Confirme aprovacao completa de todos os gates.

4. Verificacao da Superficie de Agentes:
   - Garanta que qualquer alteracao que impacte regras, skills ou docs esteja refletida em `docs/agent-coverage.md`.
   - Execute o teste automatizado da matriz:
     ```bash
     pytest app/tests/unit/infrastructure/test_agent_coverage_matrix.py
     ```
