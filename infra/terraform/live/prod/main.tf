locals {
  project       = "minecraft"
  environment   = "prod"
  region        = "brazilsouth"
  region_suffix = "bs"
  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terraform"
  }
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = "rg-${local.project}-${local.environment}-${local.region_suffix}"
  location = local.region
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = module.resource_group.name
  location            = local.region
  vnet_name           = "vnet-${local.project}-${local.environment}"
  aks_subnet_name     = "snet-aks-${local.environment}"
  vnet_address_space  = ["10.10.0.0/16"]
  aks_subnet_prefix   = ["10.10.0.0/22"]
  admin_cidr_list     = var.admin_cidr_list
  tags                = local.tags
}

module "acr" {
  source              = "../../modules/acr"
  name                = "acrminecraft${local.environment}"
  resource_group_name = module.resource_group.name
  location            = local.region
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = "aks-${local.project}-${local.environment}"
  resource_group_name = module.resource_group.name
  location            = local.region
  dns_prefix          = "mc-${local.environment}"
  subnet_id           = module.network.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  node_count          = 1
  vm_size             = "Standard_B2s"
  os_disk_size_gb     = 64
  enable_auto_scaling = false
  acr_id              = module.acr.id
  tags                = local.tags
}

module "storage_backup" {
  count                = var.enable_backup_storage ? 1 : 0
  source               = "../../modules/storage-backup"
  storage_account_name = var.backup_storage_account_name
  resource_group_name  = module.resource_group.name
  location             = local.region
  container_name       = "world-backups"
  tags                 = local.tags
}
