variable "name" {
  type        = string
  description = "Nome do Azure Container Registry"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos Azure"
}

variable "location" {
  type        = string
  description = "Regiao Azure dos recursos"
}

variable "sku" {
  type        = string
  description = "SKU do registro de container (Basic, Standard, Premium)"
  default     = "Basic"
}

variable "admin_enabled" {
  type        = bool
  description = "Habilita usuario administrador no ACR"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos do modulo"
  default     = {}
}
