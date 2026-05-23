# Linters

Configuracoes centralizadas de qualidade estatica.

| Arquivo | Uso |
|---------|-----|
| `.tflint.hcl` | Terraform (tflint) |
| `.tfsec.yml` | Terraform (tfsec) |
| (raiz) `.pre-commit-config.yaml` | Hooks pre-commit (`Area \| Acao`) |

Nomes dos hooks: `Codigo | ...`, `Infra | ...`, `Docker | ...`, `Arquivo | ...`, `Commit | ...`.

Instalacao:

```bash
make pre-commit-install
```

Execucao manual:

```bash
pre-commit run --all-files
```
