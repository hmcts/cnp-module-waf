# moj-module-waf
A module that lets you create an Application Gatewatway with WAF.

## Usage

To use this module you require a cert for the https listener. The cert must be uploaded to the infra vault for the subscription being deployed to (infra-vault-$subscription). Once the cert exists in the vault, we use a terraform data resource to read it and pass into the app gateway module for example:

data "azurerm_key_vault_secret" "cert" {
  name      = "S{var.certificateName}"
  vault_uri = "https://infra-vault-${var.subscription}.vault.azure.net/"
}

module "appGw" {
  source             = "git@github.com:hmcts/moj-module-waf?"
  env                = "${var.env}"
  subscription       = "${var.subscription}"
  location           = "${var.location}"
  wafName            = "${var.product}-shared-waf"
  resourcegroupname  = "${azurerm_resource_group.shared_resource_group.name}"
  team_name          = "${var.team_name}"
  team_contact       = "${var.team_contact}"
  destroy_me         = "${var.destroy_me}"
  ilbIp              = "${var.ilbIp}"

  gatewayIpConfigurations = [
    {
      name     = "internalNetwork"
      subnetId = "${data.azurerm_subnet.subnet_a.id}"
    },
  ]

   sslCertificates = [
    {
      name     = "${var.certificateName}"
      data     = "${data.azurerm_key_vault_secret.cert.value}"
      password = "" 
    }
  ]

   httpListeners = [
    {
      name                    = "${var.product}-http-listener"
      FrontendIPConfiguration = "appGatewayFrontendIP"
      FrontendPort            = "frontendPort80"
      Protocol                = "Http"
      SslCertificate          = ""
      hostName                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
    },
    {
      name                    = "${var.product}-https-listener"
      FrontendIPConfiguration = "appGatewayFrontendIP"
      FrontendPort            = "frontendPort443"
      Protocol                = "Https"
      SslCertificate          = "STAR-platform-hmcts-net"
      hostName                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
    },
  ]

   backendAddressPools = [
    {
      name = "${var.product}-frontend-${var.env}"

      backendAddresses = [
        {
          ipAddress = "${var.ilbIp}" 
        },
      ]
    },
  ]

   backendHttpSettingsCollection = [
    {
      name                           = "backend-80-nocookies"
      port                           = 80
      Protocol                       = "Http"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "http-probe"
      PickHostNameFromBackendAddress = "False"
      HostName                       = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
    },
    {
      name                           = "backend-443-nocookies"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = "ilbCert"
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "True"
      Host                           = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"

    }
  ]

   requestRoutingRules = [
    {
      name                = "${var.product}-http"
      RuleType            = "Basic"
      httpListener        = "${var.product}-http-listener"
      backendAddressPool  = "${var.product}-frontend-${var.env}"
      backendHttpSettings = "backend-80-nocookies"
    },
    {
      name                = "${var.product}-https"
      RuleType            = "Basic"
      httpListener        = "${var.product}-https-listener"
      backendAddressPool  = "${var.product}-frontend-${var.env}"
      backendHttpSettings = "backend-443-nocookies"
    }
  ]

    probes = [
     {
      name                                = "http-probe"
      protocol                            = "Http"
      path                                = "/health"
      interval                            = 30
      timeout                             = 30
      unhealthyThreshold                  = 3      
      pickHostNameFromBackendHttpSettings = "false"
      backendHttpSettings                 = "backend-80-nocookies"
      host                                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
     },
     {
      name                                = "https-probe"
      protocol                            = "Https"
      path                                = "/health"
      interval                            = 30
      timeout                             = 30
      unhealthyThreshold                  = 3
      host                                = "${var.product}.${var.env}.platform.hmts.net"
      pickHostNameFromBackendHttpSettings = "false"
      backendHttpSettings                 = "backend-443-nocookies"
      host                                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
     }
   ]
}





