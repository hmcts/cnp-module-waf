variable "subscription" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "team_name" {}

variable "team_contact" {}

variable "destroy_me" {}

variable "size" {
  default = "WAF_Medium"
}

variable "tier" {
  default = "WAF"
}

variable "wafName" {}

variable "wafEnabled" {
  default = "true"
}

variable "wafMode" {
  default = "Prevention"
}

variable "wafRuleSetType" {
  default = "OWASP"
}

variable "wafRuleSetVersion" {
  default = "3.0"
}

variable "sslPolicy" {
  default = "AppGwSslPolicy20170401S"
}

variable "capacity" {
  default = "2"
}

variable "authenticationCertificates" {
  type    = "list"
  default = []
}

variable "gatewayIpConfigurations" {
  type = "list"
}

variable "frontendIPConfigurations" {
  type    = "list"
  default = []
}

variable "frontEndPorts" {
  type    = "list"
  default = []
}

variable "sslCertificates" {
  type = "list"
}

variable "httpListeners" {
  type = "list"
}

variable "backendAddressPools" {
  type = "list"
}

variable "backendHttpSettingsCollection" {
  type    = "list"
  default = []
}

variable "requestRoutingRules" {
  type = "list"
}

variable "probes" {
  type    = "list"
  default = []
}
