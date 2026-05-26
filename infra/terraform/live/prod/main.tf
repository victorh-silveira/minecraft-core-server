data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  vnet_name           = local.vnet_name
  aks_subnet_name     = local.aks_subnet_name
  vnet_address_space  = ["10.10.0.0/16"]
  aks_subnet_prefix   = ["10.10.0.0/22"]
  admin_cidr_list     = var.admin_cidr_list
  game_cidr_list      = var.game_cidr_list
  tags                = local.tags
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = local.aks_cluster_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  dns_prefix          = local.dns_prefix
  subnet_id           = module.network.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  node_count          = 1
  vm_size             = var.node_vm_size
  os_disk_size_gb     = var.node_os_disk_size_gb
  enable_auto_scaling = false
  tags                = local.tags
}
