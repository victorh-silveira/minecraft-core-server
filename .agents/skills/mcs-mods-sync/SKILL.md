---
name: mcs-mods-sync
description: >-
  Altera, valida e soluciona problemas no processo de sincronizacao de mods Forge.
  Gerencia o manifesto JSON, resolucao de dependencias no Modrinth, validacao de hashes SHA-256
  e integracao com a CLI. Use when editing mods-manifest.json, mod resolvers, or LocalJarStore.
---

# Habilidade: mcs-mods-sync

Guia operacional para gerenciar o manifesto de mods e validar o fluxo de download e verificacao criptografica.

## Procedimento de Sincronizacao

1. Edicao do Manifesto:
   - Abra `app/runtime/mods/mods-manifest.json`.
   - Adicione ou atualize os dados do mod (garantindo `project_id`, `version_id`, `filename` e `sha256`).
   - Verifique que o ID do mod e unico no array.

2. Validacao do Schema do Manifesto:
   - Execute o portao de validacao JSON no terminal WSL:
     ```bash
     python app/scripts/operations/clean_workspace.py --area python --stage lint
     ```
   - O validador confirma a estrutura JSON, unicidade de IDs e presenca de campos mandatorios.

3. Execucao da Sincronizacao via CLI:
   - Dispare o comando de sync:
     ```bash
     python run.py sync-mods
     ```
   - Acompanhe a resolucao no Modrinth, o download dos arquivos `.jar` e a confirmacao de integridade via SHA-256.

4. Verificacao no Disco:
   - Inspecione se os arquivos foram salvos corretamente em `app/runtime/mods/`:
     ```bash
     ls -la app/runtime/mods/
     ```
   - Certifique-se de que nenhum arquivo `.jar` foi adicionado ao stage do git (`git status`).
