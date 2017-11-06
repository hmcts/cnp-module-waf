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

variable "subnetname" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "backend_port" {
  default = "443"
}

variable "backend_protocol" {
  default = "https"
}
