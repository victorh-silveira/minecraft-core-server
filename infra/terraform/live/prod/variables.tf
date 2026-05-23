variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version (null = default do Azure)"
  default     = null
}

variable "admin_cidr_list" {
  type        = list(string)
  description = "CIDR blocks allowed for RCON at NSG level (defina em terraform.tfvars)"
  default     = []
}

variable "backup_storage_account_name" {
  type        = string
  description = "Globally unique storage account for world backups"
  default     = "stminecraftprod001"
}

variable "enable_backup_storage" {
  type        = bool
  description = "Create optional backup storage account"
  default     = true
}
