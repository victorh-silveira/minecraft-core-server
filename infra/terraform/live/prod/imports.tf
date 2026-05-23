import {
  to = module.storage.azurerm_storage_container.tfstate
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}/blobServices/default/containers/tfstate"
}
