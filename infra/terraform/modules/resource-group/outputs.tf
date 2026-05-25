output "name" {
  value       = azurerm_resource_group.this.name
  description = "Nome do grupo de recursos"
}

output "location" {
  value       = azurerm_resource_group.this.location
  description = "Regiao Azure do grupo de recursos"
}

output "id" {
  value       = azurerm_resource_group.this.id
  description = "ID do grupo de recursos"
}
