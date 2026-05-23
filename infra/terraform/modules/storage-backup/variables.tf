variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_name" {
  type    = string
  default = "world-backups"
}

variable "tags" {
  type    = map(string)
  default = {}
}
