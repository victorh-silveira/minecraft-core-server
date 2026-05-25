# tfsec:ignore:azure-container-limit-authorized-ips
# tfsec:ignore:azure-container-logging
resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.cluster_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sku_tier
  tags                              = var.tags
  role_based_access_control_enabled = true
  node_resource_group               = "rg-minecraft-server-nodes-prod"

  default_node_pool {
    name                         = "default"
    vm_size                      = var.vm_size
    vnet_subnet_id               = var.subnet_id
    node_count                   = var.node_count
    os_disk_size_gb              = var.os_disk_size_gb
    only_critical_addons_enabled = false
    temporary_name_for_rotation  = "defaulttmp"
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    network_policy    = "azure"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
