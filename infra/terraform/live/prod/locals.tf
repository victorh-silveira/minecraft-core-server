locals {
  project       = "minecraft-server"
  environment   = "prod"
  region_suffix = "bs"

  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terraform"
  }

  resource_group_name        = "rg-${local.project}-${local.environment}"
  vnet_name                  = "vnet-${local.project}-${local.environment}-${local.region_suffix}"
  aks_subnet_name            = "snet-aks-${local.project}-${local.environment}-${local.region_suffix}"
  aks_cluster_name           = "aks-${local.project}-${local.environment}"
  dns_prefix                 = "minecraftserver${local.environment}"
  storage_account_name       = "st${replace(local.project, "-", "")}${local.environment}001"
  game_dns_label             = replace("${local.project}${local.environment}", "-", "")
  container_image_repository = "ghcr.io/victorh-silveira/minecraft-core-server"
}
