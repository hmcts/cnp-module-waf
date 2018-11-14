variable "product" {
  type = "string"
}

variable "location" {
  type    = "string"
  default = "UK South"
}

variable "vnet_name" {
  type = "string"
}

variable "subnet_id" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "backend_address" {
  type = "string"
}

variable "resource_group_name" {
  type = "string"
}

variable "common_tags" {
  type = "map"
  default = {
    "Team Name" = "pleaseTagMe"
  }
}
