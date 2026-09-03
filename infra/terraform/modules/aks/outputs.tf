output "id" {
  value       = azurerm_kubernetes_cluster.this.id
  description = "ID do cluster AKS"
}

output "name" {
  value       = azurerm_kubernetes_cluster.this.name
  description = "Nome do cluster AKS"
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  description = "Kubeconfig bruto do cluster (sensivel)"
  sensitive   = true
}

output "host" {
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  description = "Endpoint da API do Kubernetes (sensivel)"
  sensitive   = true
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  description = "Object ID da identidade do kubelet (Workload Identity / RBAC futuro)"
}

output "oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
  description = "URL do emissor OIDC do cluster (Workload Identity)"
}
