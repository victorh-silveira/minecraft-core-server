# GitHub Actions

## Workflows

| Workflow | Gatilho | Jobs |
|----------|---------|------|
| [ci.yml](workflows/ci.yml) | push `main`, manual | `linter`, `validate`, `release` |
| [cd.yml](workflows/cd.yml) | release ou manual (`deploy-app` / `deploy-infra`) | `deploy-app`, `deploy-infra`, `post-deploy` |
| [destroy.yml](workflows/destroy.yml) | **somente manual** | `destroy` |

## Actions

```text
.github/actions/
├── shared/
│   └── azure-login/          OIDC ou SP JSON
├── ci/
│   ├── lint-code/
│   ├── lint-infra/           + actionlint
│   ├── test/
│   ├── security/
│   ├── validate-docker/
│   ├── validate-kubernetes/
│   ├── validate-terraform/
│   ├── sync-tags/
│   └── release/
├── cd/
│   ├── deploy-app/
│   ├── deploy-infra/
│   └── post-deploy/
└── destroy/
    └── azure/                plan destroy + destroy
```

## Secrets

| Secret | Uso |
|--------|-----|
| `AZURE_CLIENT_ID` | OIDC (recomendado) |
| `AZURE_TENANT_ID` | OIDC / Terraform |
| `AZURE_SUBSCRIPTION_ID` | OIDC / Terraform |
| `AZURE_CREDENTIALS` | Fallback JSON do service principal |
| `RCON_PASSWORD` | Secret `mc-rcon` no AKS (CD app) |
| `GITHUB_TOKEN` | CI release e Gitleaks (automatico) |

### OIDC (recomendado)

1. App registration no Entra ID com federated credential para `repo:ORG/REPO:ref:refs/heads/main` e ambiente `production`.
2. Role Contributor (ou mais restrita) na subscription.
3. Preencha `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
4. Deixe `AZURE_CREDENTIALS` vazio ou omita; `azure-login` usa OIDC quando `AZURE_CLIENT_ID` esta definido.

## Environments

| Environment | Workflow | Protecao recomendada |
|-------------|----------|----------------------|
| `production` | CD app | Required reviewers |
| `production-infra` | CD (`deploy-infra`) | Required reviewers + confirm `APPLY_INFRA` |
| `production-destroy` | Destroy | Required reviewers + confirm `DESTROY` |

## Fluxo recomendado

1. **Primeira vez:** `CD` manual, modo `deploy-infra`, confirmar `APPLY_INFRA` (AKS, ACR, rede).
2. **Cada release:** CI gera tag; `CD` publica imagem e faz rollout no AKS.
3. **RCON:** `kubectl port-forward -n mc-prod svc/mc-server-rcon 25575:25575` (ClusterIP, sem LB extra).
4. **Destroy:** Actions > Destroy > `DESTROY`; revise artifact `terraform-destroy-plan-*` antes de aprovar o environment.

O state remoto em `stminecraftprodtf001` (bootstrap) nao e destruido pelo workflow. PVC com `Retain` pode deixar discos orfaos; consulte [docs/operations.md](../docs/operations.md).
