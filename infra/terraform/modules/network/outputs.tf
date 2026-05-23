output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "nsg_id" {
  value = azurerm_network_security_group.aks.id
}
