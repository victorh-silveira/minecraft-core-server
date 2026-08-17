variable "name" {
  type = string
}

locals {
  normalized = lower(trimspace(var.name))
}

output "normalized" {
  value = local.normalized
}
