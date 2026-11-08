---
name: mcs-python-deps
description: >-
  Adiciona, atualiza e sincroniza dependencias Python do projeto em pyproject.toml e requirements.
  Audita vulnerabilidades com pip-audit e garante integridade do ambiente virtual WSL.
  Use when modifying requirements, installing Python libraries, or running pip-audit.
---

# Habilidade: mcs-python-deps

Instrucoes para gerenciamento seguro de dependencias do ecossistema Python.

## Procedimento de Adicao / Atualizacao

1. Edicao Declarativa:
   - Abra `app/pyproject.toml`.
   - Adicione o pacote em `[project.dependencies]` (producao) ou em `[project.optional-dependencies.dev]` (desenvolvimento).
   - Espelhe exatamente a mesma especificacao em `app/requirements.txt` ou `app/requirements-dev.txt`.

2. Reinstalacao e Sincronizacao do Ambiente:
   - No terminal WSL, execute o alvo de instalacao:
     ```bash
     make app-install
     ```
   - O script `ensure-dev-env.sh` detecta a alteracao pelo hash SHA-256 e instala os novos pacotes no `.venv`.

3. Auditoria de Seguranca:
   - Execute o scanner de vulnerabilidades:
     ```bash
     make app-security
     ```
   - Certifique-se de que o `pip-audit` retorne "No known vulnerabilities found". Em caso de vulnerabilidade, escolha uma versao corrigida.
