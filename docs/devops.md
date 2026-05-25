# DevOps

Docker local, qualidade de codigo, Terraform, Kubernetes e pipelines GitHub Actions.

## Dockerfile

[`infra/docker/Dockerfile`](../infra/docker/Dockerfile)

| Pratica | Implementacao |
|---------|---------------|
| BuildKit | `# syntax=docker/dockerfile:1.7` |
| Labels OCI | titulo, versao, revision em PT |
| Usuario | `USER minecraft` |
| Healthcheck | `mc-health`, start-period 180s |
| Volumes | world, mods, plugins, logs, database |
| JVM | `USE_AIKAR_FLAGS`, `SYNC_CHUNK_WRITES` |

Templates em `/templates/` na imagem; bind mounts de `app/src/` prevalecem em runtime local.

## Docker Compose

[`infra/docker/docker-compose.yml`](../infra/docker/docker-compose.yml)

| Recurso | Detalhe |
|---------|---------|
| Projeto | `minecraft-server` |
| Rede | `minecraft-core-network` |
| Logging | json-file 10m x 5, compress |
| Seguranca | `no-new-privileges`, limites mem/pids |
| RCON | `127.0.0.1:RCON_PORT` no host |

## Makefile

| Comando | Descricao |
|---------|-----------|
| `docker-build-up` | Sync mods, build, sobe servidor |
| `docker-test` | `test-docker.sh` |
| `ci-lint` | pre-commit |
| `ci-test` | pytest + cobertura 100% |
| `ci-validate` | testes + security + test-docker |
| `terraform-fmt` / `terraform-validate` / `terraform-plan` | Terraform live/prod |
| `k8s-apply` | Kustomize prod + annotations |
| `k8s-annotate` | `atualizar-annotations-k8s.sh` |
| `k8s-test` | `test-aks.sh` |
| `pre-commit-install` | hooks + commit-msg |

## Terraform e Kubernetes

| Caminho | Proposito |
|---------|-----------|
| `infra/terraform/live/prod` | Stack Azure producao |
| `infra/kubernetes/base` | Manifestos base |
| `infra/kubernetes/overlays/prod` | Patches prod + annotations |

```bash
make k8s-apply
make k8s-annotate
bash app/scripts/bash/test-aks.sh
```

Linters: [linters/README.md](../linters/README.md).

## Pre-commit

```powershell
pip install -r app/requirements-dev.txt
make pre-commit-install
pre-commit run --all-files
```

Hooks: `Codigo |`, `Infra |`, `Docker |`, `Workflows |`, `Commit |` (ver `.pre-commit-config.yaml`).

## Quality gate

[`app/scripts/python/clean_workspace.py`](../app/scripts/python/clean_workspace.py)

| Stage | Ferramentas |
|-------|-------------|
| lint | Ruff, Vulture, Pylint, limite 300 linhas |
| test | pytest + coverage 100% em `infrastructure.mods` |
| security | Bandit, pip-audit |
| clean | caches |

## Release semantica

[`app/tools/releaserc.mjs`](../app/tools/releaserc.mjs) — gera `docs/CHANGELOG.md` e tag Git na branch `main`.

## CI/CD

Detalhe de secrets: [.github/README.md](../.github/README.md).

### CI — `ci.yml`

| Job | Conteudo |
|-----|----------|
| `CI - Linter` | Ruff, Terraform fmt, Hadolint, actionlint, YAML |
| `CI - Validacao` | pytest, Bandit, pip-audit, Gitleaks, Docker config, kubeconform, tflint, tfsec |
| `CD - Deploy Infra (GitOps)` | `terraform apply` se TF mudou ou AKS ausente |
| `CI - Versao semantica` | sync tags + semantic-release |

### CD — `cd.yml`

| Job | Gatilho |
|-----|---------|
| `CD - Deploy Infra` | Manual + `APPLY_INFRA` |
| `CD - Deploy App` | Release publicada ou manual + `image_tag` |
| `CD - Pos-deploy` | Apos deploy-app: annotations + `test-aks.sh` + probe TCP |

Fluxo tipico: push `main` -> CI valida -> infra se necessario -> release -> CD build/push ACR -> rollout AKS -> annotations -> testes.

Tag `latest` proibida no CD.

### Destroy — `destroy.yml`

Manual, confirmar `DESTROY`. Remove namespace K8s, depois `terraform destroy`. PVC Retain pode deixar discos orfaos.

## Scripts operacionais

| Script | Funcao |
|--------|--------|
| `test-aks.sh` | Diagnostico Azure + K8s + TCP + logs |
| `atualizar-annotations-k8s.sh` | Metadados conectividade/saude |
| `test-docker.sh` | Validacao Compose local |
| `setup-github-azure.sh` | Federated credentials OIDC |
| `update-duckdns.sh` | DDNS opcional |

## Scorecard

| Item | Status |
|------|--------|
| Dockerfile / Compose | OK |
| Makefile | OK |
| Pre-commit + CI | OK |
| Terraform + AKS | OK |
| Backup CronJob + WI | OK |
| Annotations operacionais | OK |
| Key Vault / Docker Secrets | Pendente |
| Metricas Prometheus | Pendente |
