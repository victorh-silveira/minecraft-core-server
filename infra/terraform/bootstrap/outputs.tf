output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Terraform state resource group"
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Terraform state storage account"
}

output "container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "Terraform state blob container"
}

output "backend_config" {
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "minecraft/prod.terraform.tfstate"
  }
  description = "Backend block values for terraform/live/prod"
}
