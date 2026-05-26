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
| `ci-fmt` / `ci-validate-infra` / `terraform-plan` | Terraform live/prod |
| `k8s-apply` | Kustomize prod + annotations |
| `k8s-annotate` | `atualizar-annotations-k8s.sh` |
| `k8s-test` | `test-aks.sh` |
| `pre-commit-install` | hooks + commit-msg |
| `dev-deps` | cria `.venv` e instala requirements-dev |

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

```bash
make dev-deps
make pre-commit-install
make ci-lint
```

O Makefile cria `.venv` na raiz e instala `app/requirements-dev.txt` automaticamente nos alvos Python.

Hooks: `Codigo |`, `Infra |`, `Docker |`, `Workflows |`, `Commit |` (ver `.pre-commit-config.yaml`).

## Quality gate

[`app/scripts/python/clean_workspace.py`](../app/scripts/python/clean_workspace.py)

| Stage | Ferramentas |
|-------|-------------|
| lint | Ruff, Vulture, Pylint, limite 300 linhas |
| test | pytest + coverage 100% em `infrastructure.mods` |
| security | Bandit, pip-audit |
| clean | caches, `.tools`, `__pycache__`, pastas vazias obsoletas |

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
| `deploy-aks.sh` | Deploy manual no AKS (`make k8s-deploy`) |
| `resolve-whitelist.sh` | Converte nicks em UUID offline (modo offline) |
| `test-aks.sh` | Diagnostico Azure + K8s + TCP + logs |
| `atualizar-annotations-k8s.sh` | Metadados conectividade/saude |
| `test-docker.sh` | Validacao Compose local |
| `setup-github-azure.sh` | Federated credentials OIDC |
| `ci-infra-local.sh` | fmt/lint/validate Terraform local |

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

## Principios de codigo

### DRY

| Area | Mecanismo |
|------|-----------|
| Parametros infra local | `infra/docker/.env` + `.env.example` |
| Compose | Anchors YAML reutilizaveis |
| Comandos | Makefile (`docker-*`, `k8s-*`, `ci-*`) |
| Mods | `mods-manifest.json` (sem JARs no Git) |
| Quality gate | `clean_workspace.py` |
| Metadados K8s | patches + `atualizar-annotations-k8s.sh` |

Duplicidade conhecida: config do jogo em `.env`/StatefulSet **e** `server.properties` — ver [configuration.md](configuration.md).

### SOLID (`app/src/infrastructure/mods/`)

| Principio | Comentario |
|-----------|------------|
| S | Funcoes focadas; `sync_mod` coeso |
| O | Novas sources via registro de resolvers |
| I | `ModResolver` Protocol em `providers.py` |
| D | Testes com monkeypatch de paths |

Cobertura **100%** em `infrastructure.mods` (`make ci-test`).

### Commits

Formato `tipo(escopo): assunto` com corpo obrigatorio (`app/tools/commitlint.config.mjs`). Escopos: `docker`, `mods`, `infra`, `scripts`, `config`, `test`, etc.

## Roadmap

Historico de releases: [CHANGELOG.md](CHANGELOG.md).

| Prioridade | Item |
|------------|------|
| 1 | Unificar `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` entre `.env` e `server.properties` |
| 2 | Pin da imagem base `itzg/minecraft-server` (tag ou digest fixo) |
| 3 | Expandir injecao de dependencias em `infrastructure.mods` |
| 4 | Segredos em Azure Key Vault + CSI / External Secrets |
| 5 | Profiles Compose `dev` / `staging` |
| 6 | Metricas Prometheus (avaliar RAM no node unico) |
| 7 | Lifecycle policy no blob `world-backups` |
| 8 | HA / segundo node AKS |

### Atualizar mods

1. Branch `feature/atualizar-mods`
2. Editar `mods-manifest.json` + `make docker-sync-mods`
3. Testar local (`make docker-test`) e AKS (`make k8s-test`)
4. Merge apos validacao in-game
