variable "subscription_id" {
  type        = string
  description = "ID da assinatura Azure"
}

variable "tenant_id" {
  type        = string
  description = "ID do locatario Azure"
}

variable "kubernetes_version" {
  type        = string
  description = "Versao do Kubernetes no AKS (deve ser >= a versao atual do cluster; Azure nao permite downgrade)"
  default     = "1.34"
}

variable "admin_cidr_list" {
  type        = list(string)
  description = "CIDRs admin: RCON no NSG e, se nao vazio, allowlist da API do AKS"
  default     = []
}

variable "game_cidr_list" {
  type        = list(string)
  description = "Blocos CIDR permitidos para Minecraft na porta 25565 no NSG (vazio = internet; use whitelist no servidor)"
  default     = []
}

variable "game_dns_label" {
  type        = string
  description = "Label DNS gratuito Azure (unico na regiao). Vazio usa minecraftserverprod."
  default     = ""
}

variable "node_vm_size" {
  type        = string
  description = "SKU do no AKS (B2ats_v2 alinha com cota gratuita de VM B-series na conta Azure)"
  default     = "Standard_B2ats_v2"
}

variable "node_os_disk_size_gb" {
  type        = number
  description = "Disco OS do no em GB (minimo 30 no AKS)"
  default     = 30
}
