# Azure AKS - Infraestrutura e Deploy

Guia de infraestrutura como codigo (Terraform) e manifestos Kubernetes para executar o servidor Minecraft no Microsoft Azure (`brazilsouth`).

## Arquitetura

```mermaid
flowchart TB
  subgraph azure [Azure Brazil South]
    rg[rg-minecraft-prod-bs]
    vnet[vnet-minecraft-prod]
    aks[aks-minecraft-prod]
    acr[acrminecraftprod]
    st_tf[stminecraftprodtf001]
    st_bk[stminecraftprod001]
  end
  subgraph k8s [Namespace mc-prod]
    sts[StatefulSet mc-server]
    pvc[PVC mc-data 32Gi]
    svcG[Service LB :25565]
    svcR[Service LB :25575]
  end
  acr --> sts
  pvc --> sts
  sts --> svcG
  sts --> svcR
```

## Estrutura do repositorio

```text
infra/terraform/
  bootstrap/
  modules/
  live/prod/

infra/kubernetes/
  base/
  overlays/prod/
```

## Pre-requisitos

- Azure CLI (`az login`)
- Terraform >= 1.6
- kubectl
- kustomize (incluso no kubectl)
- Permissoes: Contributor na subscription + Storage Blob Data Contributor no state

## 1. Bootstrap do state

```bash
cd infra/terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edite `subscription_id` e `tenant_id`, depois:

```bash
terraform init
terraform apply
```

Detalhes: [infra/terraform/bootstrap/README.md](../infra/terraform/bootstrap/README.md)

## 2. Deploy da infraestrutura

```bash
cd infra/terraform/live/prod
cp terraform.tfvars.example terraform.tfvars
```

Ajuste `admin_cidr_list` com seu IP publico (`curl -s ifconfig.me`/32).

```bash
terraform init
terraform plan
terraform apply
```

Obtenha credenciais do cluster:

```bash
az aks get-credentials --resource-group rg-minecraft-prod-bs --name aks-minecraft-prod
```

## 3. Imagem no ACR

```bash
ACR=$(terraform -chdir=infra/terraform/live/prod output -raw acr_login_server)
az acr login --name acrminecraftprod
docker build -t "${ACR}/minecraft-core-server:v1.0.0" .
docker push "${ACR}/minecraft-core-server:v1.0.0"
```

## 4. Deploy Kubernetes

Altere a senha RCON antes do apply:

```bash
kubectl create namespace mc-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl -n mc-prod create secret generic mc-rcon \
  --from-literal=RCON_PASSWORD='sua-senha-forte' \
  --dry-run=client -o yaml | kubectl apply -f -
```

Consulte `infra/kubernetes/base/secret-rcon.yaml.example` (nao commitar senha real).

```bash
kubectl apply -k infra/kubernetes/overlays/prod
```

## 5. Migracao do mundo

Copie dados locais para o pod:

```bash
POD=$(kubectl -n mc-prod get pod -l app.kubernetes.io/name=mc-server -o jsonpath='{.items[0].metadata.name}')
kubectl -n mc-prod cp app/src/domain/world-data/. "${POD}:/data/world/"
```

## 6. Validacao

```bash
bash app/scripts/bash/test-aks.sh
```

IP do jogo:

```bash
kubectl -n mc-prod get svc mc-server-game
```

## Custos estimados (prod minimo)

| Recurso | SKU | Nota |
|---------|-----|------|
| AKS control plane | Free tier | Sem cobranca de gerenciamento |
| Node pool | 1x Standard_B2s | Principal custo fixo |
| Disco PVC | StandardSSD 32Gi | Mundo + mods + logs |
| Load Balancer | Standard | 1-2 IPs publicos |
| ACR | Basic | Armazenamento de imagem |

Use creditos Azure iniciais para homologacao. Spot nodes apenas em ambientes nao-prod.

## Seguranca

- RCON restrito por `loadBalancerSourceRanges` e NSG (`admin_cidr_list`)
- Preferivel: RCON via `kubectl port-forward svc/mc-server-rcon 25575:25575` sem LB publico
- Rotacione `mc-rcon` e use Azure Key Vault + External Secrets em evolucao futura

## Qualidade (Terraform)

```bash
terraform fmt -recursive infra/terraform/
tflint --init && tflint --recursive --config linters/.tflint.hcl
tfsec --config-file linters/.tfsec.yml .
```

Hooks pre-commit e job CI `Terraform - Validate` executam as mesmas checagens.
