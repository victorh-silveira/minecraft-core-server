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

output "backup_storage_account_name" {
  value = var.enable_backup_storage ? module.storage_backup[0].storage_account_name : null
}

output "backup_container_name" {
  value = var.enable_backup_storage ? module.storage_backup[0].container_name : null
}
