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
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  node_resource_group               = "rg-minecraft-server-nodes-prod"

  default_node_pool {
    name                         = "default"
    vm_size                      = var.vm_size
    vnet_subnet_id               = var.subnet_id
    os_disk_size_gb              = var.os_disk_size_gb
    only_critical_addons_enabled = false
    temporary_name_for_rotation  = "defaulttmp"
    enable_auto_scaling          = var.enable_auto_scaling
    min_count                    = var.enable_auto_scaling ? 1 : null
    max_count                    = var.enable_auto_scaling ? max(var.node_count, 2) : null
    node_count                   = var.enable_auto_scaling ? null : var.node_count
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    network_policy    = "azure"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}
