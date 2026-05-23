variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "brazilsouth"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for Terraform remote state"
  default     = "rg-minecraft-tfstate-bs"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for Terraform state (globally unique)"
  default     = "stminecraftprodtf001"
}

variable "container_name" {
  type        = string
  description = "Blob container name for state files"
  default     = "tfstate"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to bootstrap resources"
  default = {
    project    = "minecraft"
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}
