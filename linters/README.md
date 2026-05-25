# Linters e quality gates

Configuracao centralizada de analise estatica para codigo Python, Terraform, Docker, Kubernetes e workflows GitHub Actions.

## Arquivos de configuracao

| Arquivo | Ferramenta | Escopo |
|---------|------------|--------|
| [`linters/.tflint.hcl`](.tflint.hcl) | [TFLint](https://github.com/terraform-linters/tflint) | Terraform em `infra/terraform/` (preset recommended + ruleset azurerm) |
| [`linters/.tfsec.yml`](.tfsec.yml) | [tfsec](https://github.com/aquasecurity/tfsec) | Seguranca Terraform; severidade minima MEDIUM; exclude `AZU-0001` |
| [`app/pyproject.toml`](../app/pyproject.toml) | [Ruff](https://docs.astral.sh/ruff/) | Lint e format Python (`app/src/infrastructure/mods`, scripts, tests) |
| [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) | pre-commit | Hooks locais antes do commit |
| [`app/tools/commitlint.config.mjs`](../app/tools/commitlint.config.mjs) | commitlint | Mensagens de commit (hook `commit-msg`) |

## Pre-commit (local)

Instalacao:

```bash
pip install -r app/requirements-dev.txt
make pre-commit-install
```

Execucao completa:

```bash
make ci-lint
pre-commit run --all-files
```

### Hooks por area

| Area | Hook | O que valida |
|------|------|--------------|
| Codigo | Lint Python (Ruff) | `app/src/infrastructure/mods`, `app/tests` — com `--fix` |
| Codigo | Formatar Python (Ruff) | Formatacao |
| Codigo | Validar JSON | `app/src/interface/mods/mods-manifest.json` |
| Infra | Formatar Terraform | `terraform fmt -check -recursive infra/terraform` |
| Infra | Validar Terraform | `terraform validate` em `live/prod` |
| Infra | TFLint | `.tflint.hcl`, severidade error |
| Infra | TFSec | `.tfsec.yml` no repositorio |
| Infra | Validar sintaxe YAML | `infra/kubernetes/`, `.github/workflows/` |
| Docker | Lint Dockerfile | Hadolint em `infra/docker/Dockerfile` (ignore DL3006) |
| Workflows | Lint GitHub Actions | actionlint |
| Arquivo | Newline no fim | Arquivos texto (exceto world-data) |
| Arquivo | Remover espacos no fim | Trailing whitespace |
| Commit | Validar Conventional Commits | `commit-msg` |

## CI (GitHub Actions)

Workflow [`ci.yml`](../.github/workflows/ci.yml):

| Job | Ferramentas |
|-----|-------------|
| CI - Linter | Ruff/Vulture/Pylint via `lint-code`; Terraform fmt, Hadolint, actionlint, YAML via `lint-infra` |
| CI - Validacao | pytest + coverage 100%; Bandit, pip-audit, Gitleaks; `docker compose config`; kubeconform overlay prod; tflint, tfsec, `terraform validate` |

Script unificado local (espelha parte do CI):

```bash
make ci-test
cd app && python scripts/python/clean_workspace.py --stage lint
cd app && python scripts/python/clean_workspace.py --stage security
```

## TFLint

Inicializar plugins (primeira vez):

```bash
tflint --init --config=linters/.tflint.hcl
```

Executar em live/prod:

```bash
cd infra/terraform/live/prod
tflint --config=../../../linters/.tflint.hcl --minimum-failure-severity=error
```

CI percorre `infra/terraform/live/prod` com o mesmo config.

## tfsec

```bash
tfsec --config-file linters/.tfsec.yml .
```

Escaneia `infra/terraform` conforme bloco `terraform.directories` do YAML.

## Ruff (Python)

Config principal: `app/pyproject.toml` (line-length 120, target py313).

```bash
cd app
ruff check src/infrastructure/mods tests scripts/python
ruff format src/infrastructure/mods tests scripts/python
```

Testes com cobertura minima 100% em `infrastructure.mods` (gate do CI).

## kubeconform (Kubernetes)

Somente no CI (`validate-kubernetes`):

```bash
kubectl kustomize infra/kubernetes/overlays/prod | \
  kubeconform -kubernetes-version 1.29.0 -summary -ignore-missing-schemas
```

Valida manifests gerados pelo overlay de producao (inclui patches de annotations).

## Hadolint (Docker)

```bash
docker run --rm -i hadolint/hadolint < infra/docker/Dockerfile
```

Pre-commit usa `hadolint-docker` com `failure-threshold: warning`.

## actionlint

Valida workflows em `.github/workflows/` (sintaxe, expressoes, versões de actions).

## O que nao e lintado automaticamente

| Item | Motivo |
|------|--------|
| `app/src/domain/world-data` | Dados de jogo; excluido de hooks de arquivo |
| Valores dinamicos de annotations | Atualizados por `atualizar-annotations-k8s.sh` em runtime |
| Conteudo de secrets K8s | Nao versionados |

Documentacao de annotations: [docs/annotations.md](../docs/annotations.md).

## Referencias

- [docs/devops.md](../docs/devops.md) — Makefile e pipelines
- [docs/principles.md](../docs/principles.md) — DRY, SOLID, commits
