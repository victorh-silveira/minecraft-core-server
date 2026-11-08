---
name: mcs-senior-cloud-ops
description: >-
  Aplica as diretrizes de Cloud Ops e DevOps senior em contêineres, Kustomize, Terraform
  e Azure AKS. Assegura identidade federada (OIDC), politicas de probes e seguranca Trivy.
  Use when deploying to AKS, managing Azure Terraform modules, or updating GitHub Actions.
---

# Habilidade: mcs-senior-cloud-ops

Guia avancado para execucao de operacoes de infraestrutura e seguranca cloud.

## Procedimento de Operacao Cloud

1. Modificacao de Modulos Terraform:
   - Altere ou crie modulos em `infra/terraform/modules/`.
   - Formate e valide o codigo:
     ```bash
     terraform fmt -check infra/terraform/
     tflint --init --config=linters/.tflint.hcl
     tflint --config=linters/.tflint.hcl infra/terraform/live/prod
     ```
   - Execute o smoke test do Terraform:
     ```bash
     cd infra/terraform/modules/label && terraform test
     ```

2. Validacao de Manifestos Kubernetes:
   - Aplique as alteracoes em `infra/kubernetes/base/` ou `overlays/prod/`.
   - Renderize e valide via Kubeconform:
     ```bash
     kustomize build infra/kubernetes/overlays/prod | kubeconform -strict -summary
     ```

3. Auditoria de Seguranca de Infraestrutura:
   - Execute a suite de seguranca cloud:
     ```bash
     trivy config infra/docker
     trivy config infra/kubernetes
     tfsec infra/terraform
     ```
   - Confirme que zero misconfigurations de severidade alta ou critica foram introduzidas.
