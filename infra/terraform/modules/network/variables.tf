variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "aks_subnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "aks_subnet_prefix" {
  type = list(string)
}

variable "admin_cidr_list" {
  type        = list(string)
  description = "CIDR blocks allowed to reach RCON on nodes"
  default     = ["203.0.113.10/32"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
