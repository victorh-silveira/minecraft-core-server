output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_name" {
  value = module.acr.name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "aks_subnet_id" {
  value = module.network.aks_subnet_id
}

output "storage_account_name" {
  value = local.storage_account_name
}

output "tfstate_container_name" {
  value = "tfstate"
}

output "backups_container_name" {
  value = "world-backups"
}

output "backend_config" {
  value = {
    resource_group_name  = data.azurerm_resource_group.this.name
    storage_account_name = local.storage_account_name
    container_name       = "tfstate"
    key                  = "minecraft/prod.terraform.tfstate"
  }
}
output "game_dns_label" {
  value = var.game_dns_label != "" ? var.game_dns_label : local.game_dns_label
}
