variable "storage_account_name" {
  type        = string
  description = "Nome da conta de armazenamento Azure"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos Azure"
}

variable "location" {
  type        = string
  description = "Regiao Azure dos recursos"
}

variable "tfstate_container_name" {
  type        = string
  description = "Nome do container Blob para estado do Terraform"
  default     = "tfstate"
}

variable "backups_container_name" {
  type        = string
  description = "Nome do container Blob para backups do mundo"
  default     = "world-backups"
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos do modulo"
  default     = {}
}
