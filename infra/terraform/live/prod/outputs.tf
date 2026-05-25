output "resource_group_name" {
  value = module.resource_group.name
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
  value = module.storage.storage_account_name
}

output "tfstate_container_name" {
  value = module.storage.tfstate_container_name
}

output "backups_container_name" {
  value = module.storage.backups_container_name
}

output "backend_config" {
  value = {
    resource_group_name  = module.resource_group.name
    storage_account_name = module.storage.storage_account_name
    container_name       = module.storage.tfstate_container_name
    key                  = "minecraft/prod.terraform.tfstate"
  }
}
output "game_dns_label" {
  value = var.game_dns_label != "" ? var.game_dns_label : local.game_dns_label
}
