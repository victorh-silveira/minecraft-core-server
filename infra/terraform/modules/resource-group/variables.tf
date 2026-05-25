variable "name" {
  type        = string
  description = "Nome do grupo de recursos"
}

variable "location" {
  type        = string
  description = "Regiao Azure do grupo de recursos"
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas ao grupo de recursos"
  default     = {}
}
