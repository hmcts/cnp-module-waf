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

variable "appPrivateFqdn" {
  description = "fqdn of app to health check for example rhubarb.service.sandbox.hmcts.net"
}

variable "probePath" {
  description = "health check endpoint for app"
  default     = "/health"
}

variable "team_name" {}

variable "team_contact" {}

variable "destroy_me" {}

variable "vaultURI" {}