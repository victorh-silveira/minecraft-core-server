## [1.11.1](https://github.com/victorh-silveira/minecraft-server/compare/v1.11.0...v1.11.1) (2026-05-25)

### Correcoes de Bug

* **deploy:** converter whitelist para UUID offline em modo offline ([b308873](https://github.com/victorh-silveira/minecraft-server/commit/b308873012427bde0fee9f2880f44df6fde32fda))

## [1.11.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.10.0...v1.11.0) (2026-05-25)

### Funcionalidades

* **ci:** pipeline completo com deploy e pos-deploy no push main ([9dd445d](https://github.com/victorh-silveira/minecraft-server/commit/9dd445d61440271ce958bf8c7d106b70be512bf6))

## [1.10.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.9.0...v1.10.0) (2026-05-25)

### Funcionalidades

* **server:** desativar online-mode e autenticacao Mojang ([f5656c0](https://github.com/victorh-silveira/minecraft-server/commit/f5656c0cbe16d7b58185f2abbb2b54273fd423aa))

### Refatoracoes Tecnicas

* **infra:** reduzir annotations a 14 informacoes essenciais ([a174d79](https://github.com/victorh-silveira/minecraft-server/commit/a174d7905c874a11624bd161b47df4ef1a23574e))

## [1.9.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.8.0...v1.9.0) (2026-05-25)

### Funcionalidades

* **ci:** publicar annotations minecraft-server.io no Summary do GitHub ([3d307c5](https://github.com/victorh-silveira/minecraft-server/commit/3d307c50277741415c37299279e97b997f2d65ce))

## [1.8.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.7.0...v1.8.0) (2026-05-25)

### Funcionalidades

* **ci:** CI local via WSL e Terraform 1.15.4 ([754a591](https://github.com/victorh-silveira/minecraft-server/commit/754a5910a9535b7062acd1bc6540054092ccf171))

## [1.7.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.6.0...v1.7.0) (2026-05-25)

### Funcionalidades

* **infra:** backup AKS, annotations e documentacao PT-BR ([d1410e1](https://github.com/victorh-silveira/minecraft-server/commit/d1410e18876bb8ce0d574054341d2d11e2fb30ad))

### Correcoes de Bug

* **infra:** alinhar backup_identity.tf ao terraform fmt ([c547d2b](https://github.com/victorh-silveira/minecraft-server/commit/c547d2b6f9f69b4cdc386c1c8bb87fccbd080829))
* **infra:** alinhar versao AKS 1.34 e evitar downgrade no apply ([f089cee](https://github.com/victorh-silveira/minecraft-server/commit/f089cee59dd5133c3273c213654fb64fd35f8e97))
* **infra:** aplicar terraform fmt 1.9 no backup_identity.tf ([3e23d2e](https://github.com/victorh-silveira/minecraft-server/commit/3e23d2ee9ca9464bd387ea5697386a93d274a458))

## [1.6.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.5.0...v1.6.0) (2026-05-25)

### Funcionalidades

* **infra:** customizar nome do resource group de nodes do AKS para evitar MC_ padrao ([e65b078](https://github.com/victorh-silveira/minecraft-server/commit/e65b0787aefcd2b51e4657da0b5eafb4518e5d2c))

## [1.5.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.4.1...v1.5.0) (2026-05-25)

### Funcionalidades

* **test:** gerar relatorio de pos-deploy e conexao no github step summary ([4ada391](https://github.com/victorh-silveira/minecraft-server/commit/4ada391494fb1c944ee8ed564fca47249b50cdc2))

## [1.4.1](https://github.com/victorh-silveira/minecraft-server/compare/v1.4.0...v1.4.1) (2026-05-25)

### Correcoes de Bug

* **azure:** melhorar logs e diagnosticos de atribuicao de roles no script de setup ([30d444f](https://github.com/victorh-silveira/minecraft-server/commit/30d444f51803278e4d728d9e13cc383495aa2668))
* **ci:** verificar dinamicamente a existencia da infra para evitar skips incorretos ([0d0c4be](https://github.com/victorh-silveira/minecraft-server/commit/0d0c4be8f300b25b7330964b4bcce97f46c2eaaf))

## [1.4.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.3.0...v1.4.0) (2026-05-25)

### Funcionalidades

* **cd:** adicionar validacao holistica de recursos azure no pos-deploy ([60a2ab4](https://github.com/victorh-silveira/minecraft-server/commit/60a2ab4bffc18cf0491ffa694e943937ae19a0c2))
* **infra:** permitir forcar deploy de infraestrutura via commit message [force-infra] ([94f49b9](https://github.com/victorh-silveira/minecraft-server/commit/94f49b9aaa87accd6a1f0d60e5e68e6ab35f328d))

## [1.3.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.6...v1.3.0) (2026-05-25)

### Funcionalidades

* **infra:** automatizar pipeline de cd para fluxo gitops completo ([1aafb02](https://github.com/victorh-silveira/minecraft-server/commit/1aafb0256493679075185daff8bb506ac815873d))
* **infra:** desacoplar backend do terraform para suportar destroy e rebuild continuo ([1622d24](https://github.com/victorh-silveira/minecraft-server/commit/1622d24dba3b07419a4816f05632adb52a01cb9e))
* **infra:** unificar gitops, migrar para aks nativo e hardening de seguranca ([11387d8](https://github.com/victorh-silveira/minecraft-server/commit/11387d8f2e5927c7e753e0583eeba19dd5573817))

### Correcoes de Bug

* **infra:** alinhar formatacao do terraform e adicionar actionlint no precommit ([c7ae40b](https://github.com/victorh-silveira/minecraft-server/commit/c7ae40b66ad051bc2ddea4ec6ddcb2e4421440ae))
* **infra:** corrigir alertas tfsec e sincronizar precommit com cicd ([a96b4ae](https://github.com/victorh-silveira/minecraft-server/commit/a96b4ae28eb32f4e4211d7af893449cc7aeee9ef))
* **infra:** corrigir alinhamento do terraform e namespace no patch do kustomize ([df00819](https://github.com/victorh-silveira/minecraft-server/commit/df008192e8749a98fbad52bf943afd8fb4077d4c))
* **infra:** importar container tfstate existente na SA prod ([f28b841](https://github.com/victorh-silveira/minecraft-server/commit/f28b841ac060dee5dff1287bce31b7d07133a2cb))
* **infra:** remover moved ciclico no modulo storage ([5d22bbf](https://github.com/victorh-silveira/minecraft-server/commit/5d22bbf80b230f91dfe71e26fddc4f87306892c9))

### Melhorias de Performance

* **ci:** otimizar deploy-infra com caminhos filtrados ([4a0be6b](https://github.com/victorh-silveira/minecraft-server/commit/4a0be6bd5142afd941856d7385063d22e44e3b5b))

### Refatoracoes Tecnicas

* **infra:** consolidar tfstate e backup em um RG e storage account ([776c542](https://github.com/victorh-silveira/minecraft-server/commit/776c542030556c570996967e010d1f415a157b52))
* **infra:** padronizar nomenclatura minecraft-server-prod ([568698c](https://github.com/victorh-silveira/minecraft-server/commit/568698c4246ffa3e009b14d03d9120e4aa5b3d06))

## [1.2.6](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.5...v1.2.6) (2026-05-23)

### Correcoes de Bug

* **cd:** aumentar timeout do deploy-app para 45 minutos ([a0fe2f9](https://github.com/victorh-silveira/minecraft-server/commit/a0fe2f931ab6c45063cc652b9b5af0e5913ce6ab))

## [1.2.5](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.4...v1.2.5) (2026-05-23)

### Correcoes de Bug

* **cd:** imagem correta no apply e server.properties gravavel ([d5a06e7](https://github.com/victorh-silveira/minecraft-server/commit/d5a06e7fd79df3c86ddbde72682cf1fd84842942))

## [1.2.4](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.3...v1.2.4) (2026-05-23)

### Correcoes de Bug

* **cd:** criar namespace antes do secret RCON no deploy-app ([c1c88cc](https://github.com/victorh-silveira/minecraft-server/commit/c1c88cca2c745fca3fc7298a694c2e707a8d1ade))

## [1.2.3](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.2...v1.2.3) (2026-05-23)

### Correcoes de Bug

* **azure:** incluir User Access Administrator no setup do SP ([d878cb0](https://github.com/victorh-silveira/minecraft-server/commit/d878cb0f6b4a8c922e8694ad20d03b6a552c0637))

## [1.2.2](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.1...v1.2.2) (2026-05-23)

### Correcoes de Bug

* **terraform:** VM D2s_v6 em brazilsouth e regra RCON condicional ([4972af7](https://github.com/victorh-silveira/minecraft-server/commit/4972af7b96d4a71855ba3c21d72c5e56d17f1a7d))

## [1.2.1](https://github.com/victorh-silveira/minecraft-server/compare/v1.2.0...v1.2.1) (2026-05-23)

### Correcoes de Bug

* **cd:** exportar ARM_USE_OIDC para Terraform com login OIDC ([a7a7af4](https://github.com/victorh-silveira/minecraft-server/commit/a7a7af47ca9fef092bc4285b605b6f851e589720))

## [1.2.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.1.0...v1.2.0) (2026-05-23)

### Funcionalidades

* **devops:** monorepo, CI/CD Azure e pipeline de qualidade ([c40fbbf](https://github.com/victorh-silveira/minecraft-server/commit/c40fbbf0ac7616694fdb6f3997fdb7395bc81f72))

### Correcoes de Bug

* **ci:** corrigir teste download_jar e hadolint DL3006 ([4d1ad1b](https://github.com/victorh-silveira/minecraft-server/commit/4d1ad1b4b1df6a88e063b17ca7ba86e2fd18dfda))
* **ci:** corrigir Vulture e instalacao do tfsec ([e1e17de](https://github.com/victorh-silveira/minecraft-server/commit/e1e17def88b74e5de2f0712d650ae61ae444b7ef))
* **ci:** executar tflint com chdir nos modulos raiz ([aaf7989](https://github.com/victorh-silveira/minecraft-server/commit/aaf7989961d7b1e9557c8b33eea9ac287a78bf4c))
* **ci:** inicializar tflint com config em linters/ ([50f01d5](https://github.com/victorh-silveira/minecraft-server/commit/50f01d595a5cfd3e3096b82cac4f9ea91b7ab868))
* **ci:** limitar tflint aos modulos raiz do Terraform ([d2e2321](https://github.com/victorh-silveira/minecraft-server/commit/d2e23217c1ea290c778201c9b57696944b77fe0e))

### Refatoracoes Tecnicas

* **ci:** unificar CD app e infra em cd.yml ([437330a](https://github.com/victorh-silveira/minecraft-server/commit/437330a5ed32e087c9f7ad5c5fa040adb1caeb2a))

### Documentacao

* **changelog:** mover CHANGELOG para docs/ ([2797259](https://github.com/victorh-silveira/minecraft-server/commit/2797259d7fc7d25c29e643114b39aaa8f003e9f3))

## [1.1.0](https://github.com/victorh-silveira/minecraft-server/compare/v1.0.0...v1.1.0) (2026-05-23)

### Funcionalidades

* **devops:** reorganizar scripts e adicionar testes Docker no WSL ([ba12e27](https://github.com/victorh-silveira/minecraft-server/commit/ba12e27a7d568ddd8aabf92b55de2a8a0bb79ba1))

## 1.0.0 (2026-05-23)

### Funcionalidades

* **all:** bootstrap do servidor Minecraft Fabric com Docker e CI ([a8520e2](https://github.com/victorh-silveira/minecraft-server/commit/a8520e2c2197c9ddd4eb0e6fcd97ec590169b5f9))

### Correcoes de Bug

* **docker:** remover deploy.resources conflitante com pids_limit no CI ([e57dd64](https://github.com/victorh-silveira/minecraft-server/commit/e57dd6439f67f18c5eb48b62f7e51a28b0a58b01))
