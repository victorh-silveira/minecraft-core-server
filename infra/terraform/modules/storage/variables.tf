variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tfstate_container_name" {
  type    = string
  default = "tfstate"
}

variable "backups_container_name" {
  type    = string
  default = "world-backups"
}

variable "tags" {
  type    = map(string)
  default = {}
}
