variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos Azure"
}

variable "location" {
  type        = string
  description = "Regiao Azure dos recursos"
}

variable "vnet_name" {
  type        = string
  description = "Nome da rede virtual"
}

variable "aks_subnet_name" {
  type        = string
  description = "Nome da sub-rede do AKS"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Espaco de enderecos da VNet (CIDR)"
}

variable "aks_subnet_prefix" {
  type        = list(string)
  description = "Prefixos CIDR da sub-rede do AKS"
}

variable "admin_cidr_list" {
  type        = list(string)
  description = "Blocos CIDR permitidos para acesso RCON nos nos"
  default     = []
}

variable "game_cidr_list" {
  type        = list(string)
  description = "Blocos CIDR permitidos para Minecraft TCP 25565 (vazio = qualquer origem)"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos do modulo"
  default     = {}
}
