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

variable "backendaddress" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "backend_port" {
  default = "80"
}

variable "backend_protocol" {
  default = "http"
}

variable "certificatePfxBase64" {}

variable "certificatePrefixName" {}

variable "certificatePfxPassword" {}
