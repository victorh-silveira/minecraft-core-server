output "id" {
  value       = azurerm_container_registry.this.id
  description = "ID do Azure Container Registry"
}

output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "Servidor de login do ACR (FQDN para docker push/pull)"
}

output "name" {
  value       = azurerm_container_registry.this.name
  description = "Nome do Azure Container Registry"
}
