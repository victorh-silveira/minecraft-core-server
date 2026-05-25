output "id" {
  value       = azurerm_public_ip.this.id
  description = "ID do IP publico"
}

output "name" {
  value       = azurerm_public_ip.this.name
  description = "Nome do IP publico"
}

output "ip_address" {
  value       = azurerm_public_ip.this.ip_address
  description = "Endereco IPv4 alocado"
}

output "fqdn" {
  value       = azurerm_public_ip.this.fqdn
  description = "FQDN do label DNS Azure"
}
