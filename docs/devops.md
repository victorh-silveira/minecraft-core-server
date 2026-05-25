# DevOps

## Dockerfile

Local: [`Dockerfile`](../infra/docker/Dockerfile)

| Pratica | Implementacao |
|---------|---------------|
| BuildKit | `# syntax=docker/dockerfile:1.7` |
| Labels OCI | title, version, revision, vendor, base image |
| Non-root | `USER minecraft` apos setup |
| COPY seguro | `--chown=minecraft:minecraft` |
| Healthcheck | `mc-health` (start-period 180s) |
| Volumes declarados | world, mods, plugins, logs |
| EXPOSE | 25565/tcp, 25575/tcp |

Templates em `/templates/` servem como fallback na imagem; em runtime os **bind mounts** de `app/src/` prevalecem.

---

## Docker Compose

Local: [`docker-compose.yml`](../infra/docker/docker-compose.yml)

| Recurso | Detalhe |
|---------|---------|
| Projeto | `name: minecraft-server` |
| Rede | `minecraft-core-network` (bridge) |
| Logging | json-file, 10m x 5 arquivos, compress |
| Seguranca | `no-new-privileges:true` |
| Recursos | `mem_limit`, `pids_limit` |
| Graceful stop | `stop_grace_period: 60s` |
| Init | `init: true` (reaping de processos zombie) |
| Healthcheck | Compose + Dockerfile |

### Bind mounts long-form

Volumes com `create_host_path: true` e `read_only: true` em configs.

---

## `.dockerignore`

Categorias alinhadas ao `.gitignore`:

- Git, segredos, caches Python, Node, IDEs
- Docs, tests, scripts (nao necessarios no build context)
- Dados persistentes e JARs

Contexto de build minimo: configs + manifesto.

---

## Makefile

Prefixo obrigatorio: **`docker-*`**

| Comando | Descricao |
|---------|-----------|
| `docker-help` | Lista comandos (padrao) |
| `docker-build-up` | Sync mods, build e sobe o servidor |
| `docker-up` | Sobe com build e recreate |
| `docker-down` | Para e remove containers/rede |
| `docker-restart` | Reinicia o servico |
| `docker-sync-mods` | Roda `python -m infrastructure.mods` |
| `ci-lint` | Pre-commit leve (Ruff + TF fmt/validate) |
| `ci-test` | Pytest + cobertura 100% |
| `ci-validate` | Testes + security + test-docker |
| `terraform-plan` | Plan em `live/prod` (requer tfvars + Azure) |
| `docker-logs` | Logs em tempo real |
| `docker-sh` | Shell no container |
| `docker-clean` | Remove containers e imagens locais |
| `docker-test` | Valida Docker local (`test-docker.sh`) |
| `docker-nuke` | Limpeza total do Docker no WSL (com confirmacao) |

---

## Terraform e Azure AKS

Guia completo: [azure.md](azure.md)

| Caminho | Proposito |
|---------|-----------|
| `infra/terraform/modules/` | RG, VNet, ACR, AKS, storage |
| `infra/terraform/live/prod/` | Stack de producao (`brazilsouth`) |
| `infra/kubernetes/base/` | Manifestos K8s base |
| `infra/kubernetes/overlays/prod/` | Overlay de producao (kustomize) |

Ferramentas de qualidade:

```bash
terraform fmt -recursive infra/terraform/
tflint --init && tflint --recursive --config linters/.tflint.hcl
tfsec --config-file linters/.tfsec.yml .
```

Configuracao: [`linters/.tflint.hcl`](../linters/.tflint.hcl), [`linters/.tfsec.yml`](../linters/.tfsec.yml)

Pre-commit inclui hooks `terraform_fmt`, `terraform_validate`, `terraform_tflint`, `terraform_tfsec`.

Deploy Kubernetes:

```bash
kubectl apply -k infra/kubernetes/overlays/prod
bash app/scripts/bash/test-aks.sh
```

---

## Pre-commit

Instalacao:

```powershell
pip install -r app/requirements-dev.txt
make pre-commit-install
```

Execucao manual:

```powershell
pre-commit run --all-files
```

Hooks locais seguem o padrao `Area | Acao` (ver `.pre-commit-config.yaml`). Testes, seguranca e kubeconform rodam no CI.

---

## Quality gate (`clean_workspace.py`)

| Stage | Ferramentas |
|-------|-------------|
| lint | Ruff check/format, Vulture, Pylint duplicate-code, limite 300 linhas |
| test | pytest + coverage 100% em `app/src/infrastructure/mods/` |
| security | Bandit (app/scripts/python/), pip-audit (app/requirements.txt) |
| clean | Remove `__pycache__`, `.pytest_cache`, `.ruff_cache`, etc. |

---

## Semantic Release

Config: [`tools/releaserc.mjs`](../tools/releaserc.mjs)

```bash
npx semantic-release --extends ./tools/releaserc.mjs
```

Gera `docs/CHANGELOG.md` e tagueia versoes a partir de Conventional Commits.

Branches elegiveis: `main`.

---

## CI/CD

Documentacao completa: [`.github/README.md`](../.github/README.md)

### CI ([`ci.yml`](../.github/workflows/ci.yml))

| Job | Actions | Descrição |
|-----|---------|-----------|
| `linter` | `ci/lint-code`, `ci/lint-infra` (+ actionlint) | Lint de código e infra |
| `validate` | `ci/test`, `ci/security`, `ci/validate-docker`, `ci/validate-kubernetes`, `ci/validate-terraform` | Testes, análise de segurança e validações |
| `deploy-infra` | `cd/deploy-infra` | Deploy automático de Terraform no push da `main` (GitOps de infra) |
| `release` | `ci/sync-tags`, `ci/release` | Semantic release gerando nova versão/tag Git |

### CD ([`cd.yml`](../.github/workflows/cd.yml))

| Job | Actions | Gatilho |
|-----|---------|---------|
| `deploy-infra` | `cd/deploy-infra` | Apenas manual (`mode=deploy-infra`) |
| `deploy-app` | `cd/deploy-app` | Automático na release publicada ou manual (`mode=deploy-app`) |
| `post-deploy` | `cd/post-deploy` | após `deploy-app` |

O fluxo é 100% automatizado no modelo GitOps. Pushes na branch `main` passam por validação, aplicam a infraestrutura atualizada via Terraform no job `deploy-infra` (com injeção automática de `APPLY_INFRA`) e disparam a release. O evento de release publicada por sua vez aciona automaticamente o deploy da aplicação (`deploy-app`), que instala a imagem com a tag da versão semântica correspondente no AKS nativo.

Manual: escolha `deploy-app` (informe `image_tag`) ou `deploy-infra` (informe `APPLY_INFRA`). Tag `latest` é proibida para garantir rollback seguro.

### Destroy ([`destroy.yml`](../.github/workflows/destroy.yml))

| Job | Action |
|-----|--------|
| `destroy` | `destroy/azure` (Kubernetes cleanup + plan destroy + destroy) |

O fluxo de destroy é robusto e limpa **toda** a infraestrutura de forma 100% nativa. Antes de invocar o `terraform destroy`, ele conecta no AKS e executa `kubectl delete namespace minecraft-server-prod` para deletar graciosamente os LoadBalancers (liberando IPs públicos da Azure) e PVCs (que, configurados com `reclaimPolicy: Delete`, eliminam automaticamente os Discos Gerenciados associados). A trava de deleção do Resource Group no Terraform está desativada (`prevent_deletion_if_contains_resources = false`).

**Somente manual.** Confirmar digitando `DESTROY`.

---

## Scorecard DevOps

| Item | Status |
|------|--------|
| Dockerfile production-ready | OK |
| Compose hardened | OK |
| Makefile | OK |
| Pre-commit | OK |
| Testes automatizados | OK |
| CI/CD | OK |
| Terraform + AKS (IaC) | OK |
| Pin de versao base (nao `latest` no CD) | OK |
| Secret RCON via GitHub Secret no CD | OK |
| OIDC Azure | OK (com fallback SP JSON) |
| Docker Secrets / Key Vault nativo | Pendente |
