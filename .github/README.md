# GitHub Actions

Pipelines de integracao, entrega e destroy da stack Minecraft Server na Azure.

## Workflows

| Workflow | Nome | Gatilho | Jobs |
|----------|------|---------|------|
| [ci.yml](workflows/ci.yml) | CI - Integracao Continua | push `main`, manual | Linter, Validacao, Deploy Infra GitOps, Versao semantica |
| [cd.yml](workflows/cd.yml) | CD - Entrega Continua | release, manual | Deploy Infra, Deploy App, Pos-deploy |
| [destroy.yml](workflows/destroy.yml) | Destroy - Remocao Azure | manual | Destroy Azure |

## Composite actions

```text
.github/actions/
├── shared/azure-login/       OIDC ou service principal
├── ci/
│   ├── lint-code/            Ruff, Vulture, Pylint
│   ├── lint-infra/           Terraform fmt, Hadolint, actionlint, YAML
│   ├── test/                 pytest + coverage
│   ├── security/             Bandit, pip-audit, Gitleaks
│   ├── validate-docker/
│   ├── validate-kubernetes/  kubeconform overlay prod
│   ├── validate-terraform/   tflint, tfsec, validate
│   ├── sync-tags/
│   └── release/              semantic-release
├── cd/
│   ├── deploy-infra/         terraform apply live/prod
│   ├── deploy-app/           build ACR, secrets, kubectl, annotations
│   └── post-deploy/          annotations + test-aks + TCP
└── destroy/azure/            namespace + terraform destroy
```

## Secrets

| Secret | Uso |
|--------|-----|
| `AZURE_CLIENT_ID` | OIDC (recomendado) |
| `AZURE_TENANT_ID` | Azure / Terraform ARM |
| `AZURE_SUBSCRIPTION_ID` | Azure / Terraform ARM |
| `AZURE_CREDENTIALS` | Fallback JSON service principal |
| `RCON_PASSWORD` | Secret `mc-rcon` no AKS |
| `MINECRAFT_WHITELIST` | Secret `mc-access` (nicks separados por virgula) |
| `GITHUB_TOKEN` | Release e Gitleaks (automatico) |

### OIDC

1. App registration com federated credentials (`repo:ORG/REPO:ref:refs/heads/main`, environments `production`, `production-infra`, `production-destroy`).
2. Role Contributor (ou custom) na subscription.
3. Preencher `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
4. Script auxiliar: `app/scripts/bash/setup-github-azure.sh`.

## Environments

| Environment | Uso | Protecao |
|-------------|-----|----------|
| `production` | CD deploy-app | Reviewers recomendados |
| `production-infra` | CD/CI deploy infra | Reviewers + `APPLY_INFRA` |
| `production-destroy` | Destroy | Reviewers + `DESTROY` |

## Fluxo recomendado

### Primeira vez

1. `setup-github-azure.sh` (OIDC + federated credentials).
2. Secrets `RCON_PASSWORD`, `MINECRAFT_WHITELIST`, Azure OIDC.
3. Workflow **CD** manual, modo `deploy-infra`, confirmar `APPLY_INFRA`.
4. Workflow **CD** modo `deploy-app` com `image_tag` ou aguardar release.

### Ciclo GitOps (main)

1. Push `main` -> CI valida codigo e infra.
2. Se `infra/terraform/**` mudou (ou AKS ausente) -> `terraform apply`.
3. Release semantica -> tag e CHANGELOG.
4. Release publicada -> CD build/push imagem -> rollout AKS -> `atualizar-annotations-k8s.sh` -> `test-aks.sh`.

### Operacao

- **Conectar:** annotation `minecraft-server.io/conectividade-endereco` no Service `mc-server-game`.
- **RCON:** `kubectl port-forward -n minecraft-server-prod svc/mc-server-rcon 25575:25575`.
- **Destroy:** workflow Destroy, token `DESTROY`, revisar artefato `terraform-destroy-plan-*`.

### Storage apos destroy

- Container `tfstate` em `stminecraftserverprod001` **nao** e removido pelo destroy.
- PVC `Retain` pode deixar discos gerenciados; excluir no portal Azure se necessario.

Documentacao: [docs/azure.md](../docs/azure.md), [docs/operations.md](../docs/operations.md).
