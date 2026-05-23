# Bootstrap do Terraform State

Execucao unica para criar o backend remoto (Resource Group + Storage Account + container Blob).

## Pre-requisitos

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) com `az login`
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6

## Passos

```bash
cd infra/terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com `subscription_id` e `tenant_id` da sua assinatura.

```bash
terraform init
terraform plan
terraform apply
```

Anote os valores de `terraform output backend_config`.

## Migrar state do ambiente prod

```bash
cd ../live/prod
cp terraform.tfvars.example terraform.tfvars
```

Configure `providers.tf` com os mesmos nomes do bootstrap e execute:

```bash
terraform init -migrate-state
```

Confirme a migracao quando solicitado.

## Autenticacao do backend

O backend em `live/prod` usa `use_azuread_auth = true`. Garanta que o principal (usuario ou service principal do CI) possui as roles **Storage Blob Data Contributor** na storage account de state.
