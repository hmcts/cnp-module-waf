variable "product" {
  type = "string"
}

variable "location" {
  type    = "string"
  default = "UK South"
}

variable "vnetname" {
  type = "string"
}

variable "subnet_id" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "backendaddress" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "common_tags" {
  type = "map"
  default = {
    "Team Name" = "pleaseTagMe"
  }
}
