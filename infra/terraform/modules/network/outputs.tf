output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "ID da rede virtual"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks.id
  description = "ID da sub-rede do AKS"
}

output "nsg_id" {
  value       = azurerm_network_security_group.aks.id
  description = "ID do Network Security Group da sub-rede AKS"
}
