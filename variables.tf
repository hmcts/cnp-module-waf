variable "subscription" {
  default = "testing"
  type    = "string"
}

variable "product" {
  default = "testing"
  type    = "string"
}

variable "location" {
  type    = "string"
  default = "UK South"
}

variable "env" {
  default = "sandbox"
  type    = "string"
}

variable "ilbIp" {
  type = "string"
}

# variable "backendaddress" {
#   type = "string"
# }

variable "resourcegroupname" {
  type = "string"
}

# variable "appPrivateFqdn" {
#   description = "fqdn of app to health check for example rhubarb.service.sandbox.hmcts.net"
# }

# variable "probePath" {
#   description = "health check endpoint for app"
#   default     = "/health"
# }

variable "team_name" {}

variable "team_contact" {}

variable "destroy_me" {}

# variable "vaultURI" {}

variable "size" {
  default = "WAF_Medium"
}

variable "tier" {
  default = "WAF"
}

variable "capacity" {
  default = "2"
}

variable "gatewayIpConfigurations" {
  type = "list"
}

variable "frontendIPConfigurations" {
  type = "list"
}

variable "frontEndPorts" {
  type = "list"
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
  type = "list"
}

variable "requestRoutingRules" {
  type = "list"
}

variable "probes" {
  default = [
    {
      name               = "default-http-probe"
      protocol           = "Http"
      path               = "/health"
      interval           = 30
      timeout            = 30
      unhealthyThreshold = 3

      # Can be used if backed is resolvable in DNS
      pickHostNameFromBackendHttpSettings = "true"
      backendHttpSettings                 = "backend-80-nocookies"
    },
  ]
}
