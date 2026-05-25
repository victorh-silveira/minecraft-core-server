resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_prefix
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${var.aks_subnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# tfsec:ignore:azure-network-no-public-ingress
resource "azurerm_network_security_rule" "minecraft" {
  name                        = "permitir-minecraft-tcp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25565"
  source_address_prefix       = length(var.game_cidr_list) > 0 ? null : "*"
  source_address_prefixes     = length(var.game_cidr_list) > 0 ? var.game_cidr_list : null
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

resource "azurerm_network_security_rule" "rcon" {
  count                       = length(var.admin_cidr_list) > 0 ? 1 : 0
  name                        = "permitir-rcon-tcp-admin"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25575"
  source_address_prefixes     = var.admin_cidr_list
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# tfsec:ignore:azure-network-no-public-egress
resource "azurerm_network_security_rule" "allow_outbound" {
  name                        = "permitir-saida"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}
