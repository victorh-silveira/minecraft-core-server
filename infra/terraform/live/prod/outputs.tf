output "resource_group_name" {
  value       = data.azurerm_resource_group.this.name
  description = "Nome do grupo de recursos Azure da stack de producao"
}

output "aks_cluster_name" {
  value       = module.aks.name
  description = "Nome do cluster AKS"
}

output "container_image_repository" {
  value       = local.container_image_repository
  description = "Repositorio de imagem no GHCR (tier gratuito)"
}

output "vnet_id" {
  value       = module.network.vnet_id
  description = "ID da rede virtual"
}

output "aks_subnet_id" {
  value       = module.network.aks_subnet_id
  description = "ID da sub-rede do AKS"
}

output "storage_account_name" {
  value       = local.storage_account_name
  description = "Nome da conta de armazenamento para tfstate"
}

output "tfstate_container_name" {
  value       = "tfstate"
  description = "Nome do container Blob para estado do Terraform"
}

output "backend_config" {
  value = {
    resource_group_name  = data.azurerm_resource_group.this.name
    storage_account_name = local.storage_account_name
    container_name       = "tfstate"
    key                  = "minecraft/prod.terraform.tfstate"
  }
  description = "Configuracao do backend remoto do Terraform (azurerm)"
}

output "game_dns_label" {
  value       = var.game_dns_label != "" ? var.game_dns_label : local.game_dns_label
  description = "Label DNS do IP publico do jogo (FQDN Azure)"
}
