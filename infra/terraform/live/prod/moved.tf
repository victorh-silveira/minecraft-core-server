moved {
  from = module.storage_backup[0].azurerm_storage_account.backup
  to   = module.storage.azurerm_storage_account.this
}

moved {
  from = module.storage_backup[0].azurerm_storage_container.world_backup
  to   = module.storage.azurerm_storage_container.world_backups
}
