locals {
  project       = "minecraft-server"
  environment   = "prod"
  region        = "brazilsouth"
  region_suffix = "bs"

  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terraform"
  }

  resource_group_name = "rg-${local.project}-${local.environment}"
  vnet_name           = "vnet-${local.project}-${local.environment}-${local.region_suffix}"
  aks_subnet_name     = "snet-aks-${local.project}-${local.environment}-${local.region_suffix}"
  aks_cluster_name    = "aks-${local.project}-${local.environment}"
  acr_name            = "acr${replace(local.project, "-", "")}${local.environment}"
  dns_prefix          = "minecraftserver${local.environment}"
}
