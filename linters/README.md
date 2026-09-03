# Linters e quality gates

Configuracao centralizada de analise estatica para codigo Python, Terraform, Docker, Kubernetes e workflows GitHub Actions.

## Arquivos de configuracao

| Arquivo | Ferramenta | Escopo |
|---------|------------|--------|
| [`linters/.terraform-version`](.terraform-version) | Terraform CLI | Versao alinhada entre CI GitHub Actions, local (WSL) e bootstrap em `.tools/` |
| [`linters/.tflint.hcl`](.tflint.hcl) | [TFLint](https://github.com/terraform-linters/tflint) | Terraform em `infra/terraform/` (preset recommended + ruleset azurerm) |
| [`linters/.tfsec.yml`](.tfsec.yml) | [tfsec](https://github.com/aquasecurity/tfsec) | Seguranca Terraform; severidade minima MEDIUM; exclude `AZU-0001` |
| [`app/pyproject.toml`](../app/pyproject.toml) | [Ruff](https://docs.astral.sh/ruff/) / mypy / coverage | Lint, tipos e testes Python (`app/src`, scripts, tests) |
| [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) | pre-commit | Hooks locais antes do commit |
| [`linters/commitlint.config.mjs`](commitlint.config.mjs) | commitlint | Mensagens de commit (hook `commit-msg`) |

## Pre-commit (local)

Instalacao:

```bash
pip install -r app/requirements-dev.txt
make pre-commit-install
```

Antes de commit ou push (formatacao automatica + lint + validate infra). No Windows, use **WSL** (nao PowerShell nem Git Bash direto para Terraform):

```bash
wsl
cd ~/minecraft-server
make ci-pre-push
```

Ou a partir do PowerShell (delega ao WSL):

```powershell
wsl make -C /mnt/c/Users/<voce>/Desktop/minecraft-server ci-pre-push
```

Ou por etapa:

```bash
make ci-fmt
make ci-lint
make ci-validate-infra
make ci-infra
```

Execucao completa (pre-commit):

```bash
make ci-lint
pre-commit run --all-files
```

### Hooks por area

| Area | Hook | O que valida |
|------|------|--------------|
| Codigo | Lint Python (Ruff) | `app/src`, `app/tests` — com `--fix` |
| Codigo | Formatar Python (Ruff) | Formatacao |
| Codigo | Validar JSON | `app/runtime/mods/mods-manifest.json` |
| Infra | Formatar Terraform | `ci-infra-local.sh fmt` (versao em `linters/.terraform-version`, padrao 1.15.4) |
| Infra | Validar Terraform | `ci-infra-local.sh validate` (tflint, tfsec, `terraform validate` em `live/prod`) |
| Infra | Validar sintaxe YAML | `infra/kubernetes/`, `.github/workflows/` |
| Docker | Lint Dockerfile | Hadolint em `infra/docker/Dockerfile` (base pinada por digest; sem ignore DL3006) |
| Workflows | Lint GitHub Actions | actionlint |
| Arquivo | Newline no fim | Arquivos texto (exceto `app/runtime/world`) |
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
make app-lint
make app-test
make app-security
```

Infra isolada (`app/scripts/bash/ci-infra-local.sh`): `fmt`, `lint`, `validate`, `all`. Usa `terraform` do PATH no WSL; se ausente, baixa a versao de `linters/.terraform-version` em `.tools/`.

Ferramentas de infra rodam apenas em Linux/WSL (`run-in-linux-env.sh` redireciona hosts Windows). Nao instale Terraform no PowerShell; use WSL ou `.tools/` criado pelo script no WSL.

No WSL com repo em `/mnt/c/`, `terraform validate` pode alterar `.terraform.lock.hcl`; o script restaura o arquivo ao final. Prefira clonar em `~/` no WSL.

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
ruff check src tests scripts
ruff format src tests scripts
```

Testes com cobertura minima 100% branch nas camadas da app (`make app-test`).

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
| `app/runtime/world` | Dados de jogo; excluido de hooks de arquivo |
| Valores dinamicos de annotations | 14 chaves essenciais; `atualizar-annotations-k8s.sh` em runtime |
| Conteudo de secrets K8s | Nao versionados |

Documentacao de annotations: [docs/annotations.md](../docs/annotations.md).

## Referencias

- [docs/engineering-python.md](../docs/engineering-python.md) — qualidade Python
- [docs/devops.md](../docs/devops.md) — Makefile e pipelines
