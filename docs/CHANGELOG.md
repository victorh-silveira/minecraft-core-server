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
