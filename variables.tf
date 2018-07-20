variable "subscription" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "env" {
  type = "string"
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
