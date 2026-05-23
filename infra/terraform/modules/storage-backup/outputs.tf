output "storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "container_name" {
  value = azurerm_storage_container.world_backup.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.backup.primary_blob_endpoint
}
