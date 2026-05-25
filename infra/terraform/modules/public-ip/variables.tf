variable "name" {
  type        = string
  description = "Nome do IP publico"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos Azure"
}

variable "location" {
  type        = string
  description = "Regiao Azure dos recursos"
}

variable "domain_name_label" {
  type        = string
  description = "Label DNS gratuito Azure (unico na regiao)"
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos do modulo"
  default     = {}
}
