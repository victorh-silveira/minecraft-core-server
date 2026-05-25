output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Nome da conta de armazenamento"
}

output "tfstate_container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "Nome do container de estado do Terraform"
}

output "backups_container_name" {
  value       = azurerm_storage_container.world_backups.name
  description = "Nome do container de backups do mundo"
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.this.primary_blob_endpoint
  description = "Endpoint primario de Blob Storage"
}
