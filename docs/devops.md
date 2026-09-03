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

Templates em `/templates/` na imagem; bind mounts de `app/runtime/` prevalecem em runtime local.

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
| `app-lint` / `app-validate` / `app-test` / `app-security` | Matriz QA (orquestrador) |
| `docker-up` | Sync mods, build, sobe servidor |
| `docker-smoke` | `test-docker.sh` (smoke live) |
| `ci-lint` | pre-commit (matriz) |
| `ci-test` | alias de `app-test` |
| `ci-validate` | testes + security + docker-smoke |
| `ci-fmt` / `ci-validate-infra` / `terraform-plan` | Terraform live/prod |
| `k8s-apply` | Alias seguro de deploy; exige `IMAGE_DIGEST` |
| `k8s-annotate` | `atualizar-annotations-k8s.sh` |
| `k8s-test` | `test-aks.sh` |
| `app-setup` | deps + hooks + commit-msg |
| `app-install` | cria `.venv` e instala requirements-dev |

## Terraform e Kubernetes

| Caminho | Proposito |
|---------|-----------|
| `infra/terraform/live/prod` | Stack Azure producao |
| `infra/kubernetes/base` | Manifestos base |
| `infra/kubernetes/overlays/prod` | Patches prod + annotations |

```bash
IMAGE_DIGEST=sha256:... RCON_PASSWORD=... make k8s-deploy
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

Hooks: `Commit | Lint` primeiro, depois `Python |` / `Docker |` / `Kubernetes |` / `Terraform |` / `GitHub |` / `Scripts |` e `Stack | Limpeza`.

## Quality gate

[`app/scripts/operations/clean_workspace.py`](../app/scripts/operations/clean_workspace.py)

| Area | Lint / Seguranca / Testes / Validate / Build |
|------|-----------------------------------------------|
| Python | Ruff + manifesto JSON; Bandit/pip-audit; pytest cov 100%; mypy; compileall |
| Docker | Hadolint; Trivy config; smoke; compose config; compose build no CI |
| Kubernetes | YAML; Trivy; smoke; kubeconform; kustomize build |
| Terraform | fmt/tflint; tfsec; terraform test; validate; init |
| GitHub | parse; sem credencial estatica; jobs CI; actionlint; actions locais |
| Scripts | bash -n; shellcheck; Makefile; shebang |

Detalhe da barra senior: [engineering-senior-bar.md](engineering-senior-bar.md).

| Stage | Ferramentas |
|-------|-------------|
| lint | Ruff, mypy strict, Vulture, Pylint, limite 300 linhas, imports hexagonais |
| test | pytest + coverage 100% branch nas quatro camadas |
| security | Bandit, pip-audit |
| clean | caches, `.tools`, `__pycache__` |

## Release semantica

[`linters/releaserc.mjs`](../linters/releaserc.mjs) — gera `docs/CHANGELOG.md` e tag Git na branch `main`.

## CI/CD

Detalhe de secrets: [.github/README.md](../.github/README.md).

### CI/CD — `ci.yml`

| Job | Conteudo |
|-----|----------|
| `CI - Python` ... `CI - Scripts` | Matriz crash-first por area (paralelo entre jobs) |
| `CD - Deploy Infra` | `terraform apply` condicional + environment `production-infra` |
| `CI - Release` | sync tags + semantic-release apos gates |
| `CD - Deploy App` | build/push GHCR, Trivy image, rollout AKS por digest, environment `production` |
| `CD - Pos-deploy` | annotations, `test-aks.sh`, probe TCP 25565 |
| `CI/CD - Resumo` | tabela de status no GitHub Summary |

PR em `main`: jobs CI por area (Python, Docker, Kubernetes, Terraform, GitHub, Scripts).

### CD manual — `cd.yml`

| Modo | Jobs |
|------|------|
| `deploy-infra` | Terraform apply (`APPLY_INFRA`) |
| `deploy-app` | Imagem + rollout (informar `image_tag`) |
| `deploy-app-and-verify` | deploy-app + pos-deploy |

Fluxo automatico: push `main` -> CI -> infra (se necessario) -> release -> deploy -> pos-deploy.

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
| Dockerfile / Compose | OK (base pinada por digest; STOPSIGNAL) |
| Makefile | OK |
| Pre-commit + CI | OK (OIDC; `[skip-cd]` so CD; Trivy image no deploy) |
| Terraform + AKS | OK (Free tier, pool unico documentado) |
| Backup CronJob + WI/KV | Desativado / futuro (ver architecture.md) |
| Annotations operacionais | OK |
| Key Vault / Docker Secrets | Pendente (WI habilitado; secrets via GitHub Secrets) |
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

### SOLID (sync de mods)

| Principio | Aplicacao |
|-----------|-----------|
| S | Use case, resolvers e store com responsabilidade unica |
| O | Novas sources via `ModResolver` no composition root |
| I | Ports em `application/ports` |
| D | Testes da application usam fakes dos ports |

Cobertura **100% branch** nas camadas da app (`make app-test`).

### Commits

Formato `tipo(escopo): assunto` com corpo obrigatorio (`linters/commitlint.config.mjs`). Escopos: `domain`, `application`, `presentation`, `mods`, `runtime`, `docker`, `infra`, `scripts`, `config`, `test`.

## Roadmap

Historico de releases: [CHANGELOG.md](CHANGELOG.md).

| Prioridade | Item |
|------------|------|
| 1 | Unificar `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` entre `.env` e `server.properties` |
| 2 | Segredos em Azure Key Vault + CSI / External Secrets (WI ja ligado no AKS) |
| 3 | Profiles Compose `dev` / `staging` |
| 4 | Metricas Prometheus (avaliar RAM no node unico) |
| 5 | Reativar backup (CronJob + container `world-backups`) se sair do Free tier |
| 6 | Segregar system/user node pools no AKS (SKU pago; Free permanece pool unico) |
| 7 | Lifecycle policy no blob quando houver `world-backups` |
| 8 | HA / segundo node AKS |

### Atualizar mods

1. Branch `feature/atualizar-mods`
2. Editar `mods-manifest.json` + `make docker-sync-mods`
3. Testar local (`make docker-smoke`) e AKS (`make k8s-test`)
4. Merge apos validacao in-game
