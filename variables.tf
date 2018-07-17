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
  default = [
    {
      name   = "internalNetwork"
      vNetRG = "RG-VN-MAN-UKS-1"
      vNet   = "VN-MAN-UKS-1"
      subnet = "SN-VN-MAN-UKS-1-APPGATEWAY"
    },
  ]
}

variable "frontendIPConfigurations" {
  default = [
    {
      name         = "appGatewayFrontendIP"
      publicIpName = "pip-agw-sand-pub-1"
    },
  ]
}

variable "frontEndPorts" {
  default = [
    {
      name = "frontendPort80"
      port = 80
    },
    {
      name = "frontendPort443"
      port = 443
    },
  ]
}

variable "sslCertificates" {
  default = [
    {
      name     = "test-frontend-cert"
      data     = "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"
      password = "Azure123456!"
    },
  ]
}

variable "httpListeners" {
  default = [
    {
      name                    = "rhubarb-fe-http-listener"
      FrontendIPConfiguration = "appGatewayFrontendIP"
      FrontendPort            = "frontendPort80"
      Protocol                = "Http"
      SslCertificate          = ""
      hostName                = "rhubarb.test.com"
    },
    {
      name                    = "rhubarb-fe-https-listener"
      FrontendIPConfiguration = "appGatewayFrontendIP"
      FrontendPort            = "frontendPort443"
      Protocol                = "Https"
      SslCertificate          = "test-frontend-cert"
      hostName                = "rhubarb.test.com"
    },
  ]
}

variable "backendAddressPools" {
  default = [
    {
      name = "rhubarb-frontend"

      backendAddresses = [
        {
          fqdn = "rhubarb-frontend-prod.service.core-compute-prod.internal"
        },
      ]
    },
  ]
}

variable "backendHttpSettingsCollection" {
  default = [
    {
      name                           = "backend-80-nocookies"
      port                           = 80
      Protocol                       = "Http"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "default-http-probe"
      PickHostNameFromBackendAddress = "True"
    },
  ]
}

variable "requestRoutingRules" {
  default = [
    {
      name                = "rhubarb-fe-http"
      RuleType            = "Basic"
      httpListener        = "rhubarb-fe-http-listener"
      backendAddressPool  = "rhubarb-frontend"
      backendHttpSettings = "backend-80-nocookies"
    },
    {
      name                = "rhubarb-fe-https"
      RuleType            = "Basic"
      httpListener        = "rhubarb-fe-https-listener"
      backendAddressPool  = "rhubarb-frontend"
      backendHttpSettings = "backend-80-nocookies"
    },
  ]
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
