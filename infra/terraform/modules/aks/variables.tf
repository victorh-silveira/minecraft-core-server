variable "cluster_name" {
  type        = string
  description = "Nome do cluster AKS"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos Azure"
}

variable "location" {
  type        = string
  description = "Regiao Azure dos recursos"
}

variable "dns_prefix" {
  type        = string
  description = "Prefixo DNS do cluster AKS"
}

variable "subnet_id" {
  type        = string
  description = "ID da sub-rede onde o AKS sera implantado"
}

variable "kubernetes_version" {
  type        = string
  description = "Versao do Kubernetes (null usa a padrao do Azure)"
  default     = null
}

variable "sku_tier" {
  type        = string
  description = "Tier de cobranca do AKS (Free, Standard)"
  default     = "Free"
}

variable "node_count" {
  type        = number
  description = "Quantidade de nos no pool padrao"
  default     = 1
}

variable "vm_size" {
  type        = string
  description = "Tamanho da VM dos nos do pool"
  default     = "Standard_B2ats_v2"
}

variable "os_disk_size_gb" {
  type        = number
  description = "Tamanho do disco OS dos nos em GB"
  default     = 30
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Habilita auto-scaling no pool de nos"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos do modulo"
  default     = {}
}
