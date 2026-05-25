data "azurerm_storage_account" "backups" {
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "world_backup" {
  name                = "id-mc-world-backup-${local.environment}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "world_backup" {
  name      = "fic-mc-world-backup-${local.environment}"
  audience  = ["api://AzureADTokenExchange"]
  issuer    = module.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.world_backup.id
  subject   = "system:serviceaccount:minecraft-server-prod:mc-world-backup"
}

resource "azurerm_role_assignment" "world_backup_blob" {
  scope                = data.azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.world_backup.principal_id
}
