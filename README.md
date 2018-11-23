# cnp-module-waf
A module that lets you create an Application Gatewatway with WAF.

## Usage

To use this module you require a cert for the https listener. The cert (`certificate_name`) must be uploaded to the infra vault for the subscription being deployed to (infra-vault-$subscription). Once the cert exists in the vault, we use a terraform data resource to read it and pass into the app gateway module for example:

```
locals {
  backend_name = "${var.product}-frontend-${var.env}"
  backend_hostname = "${local.backend_name}.service.${var.env}.platform.hmcts.net"
}

data "azurerm_subnet" "app_gateway_subnet" {
  name                 = "core-infra-subnet-appGw-${var.env}"
  virtual_network_name = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
}

data "azurerm_key_vault_secret" "cert" {
  name      = "${var.certificate_name}"
  vault_uri = "https://infra-vault-${var.subscription}.vault.azure.net/"
}

module "waf" {
  source             = "git@github.com:hmcts/cnp-module-waf?ref=v1.0.0"
  env                = "${var.env}"
  subscription       = "${var.subscription}"
  location           = "${var.location}"
  wafName            = "${var.product}-shared-waf"
  resourcegroupname  = "${azurerm_resource_group.shared_resource_group.name}"
  common_tags        = "${var.tags}"
  
  gatewayIpConfigurations = [
    {
      name     = "internalNetwork"
      subnetId = "${data.azurerm_subnet.app_gateway_subnet.id}"
    }
  ]

  sslCertificates = [
    {
      name     = "${var.certificate_name}"
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
      hostName                = "${var.public_hostname}"
    },
    {
      name                    = "${var.product}-https-listener"
      FrontendIPConfiguration = "appGatewayFrontendIP"
      FrontendPort            = "frontendPort443"
      Protocol                = "Https"
      SslCertificate          = "${var.certificate_name}"
      hostName                = "${var.public_hostname}"
    },
   ]

   backendAddressPools = [
    {
      name = "${local.backend_name}"
      backendAddresses = [
        {
          ipAddress = "${local.backend_hostname}"
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
      PickHostNameFromBackendAddress = "True"
    },
    {
      name                           = "backend-443-nocookies"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "True"

    }
   ]

   requestRoutingRules = [
    {
      name                = "${var.product}-http"
      RuleType            = "Basic"
      httpListener        = "${var.product}-http-listener"
      backendAddressPool  = "${local.backend_name}"
      backendHttpSettings = "backend-80-nocookies"
    },
    {
      name                = "${var.product}-https"
      RuleType            = "Basic"
      httpListener        = "${var.product}-https-listener"
      backendAddressPool  = "${local.backend_name}"
      backendHttpSettings = "backend-443-nocookies"
    }
   ]

  probes = [
    {
      name                                = "http-probe"
      protocol                            = "Http"
      path                                = "${var.health_check}"
      interval                            = "${var.health_check_interval}"
      timeout                             = 30
      unhealthyThreshold                  = "${var.unhealthy_threshold}"
      pickHostNameFromBackendHttpSettings = "false"
      backendHttpSettings                 = "backend-80-nocookies"
      host                                = "${local.backend_hostname}"
      healthyStatusCodes                  = "200-399"
    },
    {
      name                                = "https-probe"
      protocol                            = "Https"
      path                                = "${var.health_check}"
      interval                            = "${var.health_check_interval}"
      timeout                             = 30
      unhealthyThreshold                  = "${var.unhealthy_threshold}"
      pickHostNameFromBackendHttpSettings = "false"
      backendHttpSettings                 = "backend-443-nocookies"
      host                                = "${local.backend_hostname}"
      healthyStatusCodes                  = "200-399"
    },
  ]
}
```

## Using authentication certificates
When deploying the application gateway to an environment (App Service Environment) which has a self-signed certificate associated to its internal load balancer (ILB), it will be necessary to whitelist this certificate in order to achieve end-to-end SSL encryption.

The example above would have to be modified with the following properties.

```
use_authentication_cert = true  // This property has to be set to true

backendHttpSettingsCollection = [
    {
      name                           = "backend-80-nocookies"
      port                           = 80
      Protocol                       = "Http"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "http-probe"
      PickHostNameFromBackendAddress = "True"
      HostName                       = ""
    },
    {
      name                           = "backend-443-nocookies"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = "ilbCert" // <<<--- The name of the certificate to use, this is default name. 
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "True"
    },
  ]
```

## Configuring the backends
The Application Service Environment (ASE) uses the hostname from the request to determine which application will receive the request. For this reason, is necessary that the correct hostname to be forwarded from the Application Gateway (WAF) to the ILB.

There are 3 possible configurations that fulfill this requirements.

### Pick hostname from backend address
This is the option followed in the main example. The idea behind it lies on using the the FQDN internal domain name of the frontend or service as the backend address, and then use that same FQDN as the hostname for the forwarded request by setting the property `PickHostNameFromBackendAddress` to `True`.

Is worth mentioning that with this approach the FE service would not need the public domain name listed in the `Custom Domains` section.

### Force/Override Hostname
For this option the backend address could either be the FQDN of the service or the Application Service Environment ILB IP address. The property `PickHostNameFromBackendAddress` would be set to `False` and a new property called "HostName" will need to be added.

```
 backendAddressPools = [
    {
      name = "${local.backend_name}"
      backendAddresses = [
        {
          ipAddress = "${var.ilbIPAddress}"  // or it could also be the service hostname, as per above "${local.backend_hostname}"
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
      HostName                       = "${local.backend_hostname}" // This is where hostname s being set
    },
    {
      name                           = "backend-443-nocookies"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "False"
      HostName                       = "${local.backend_hostname}" This is where hostname s being set
    },
  ]
```

With this approach the FE service would not need the public domain name listed in the `Custom Domains` section.

### ILB IP
In case of choosing the ILB IP address as a backend address and not using the HostName property, it will be required that the frontend service has the public domain name added to the `Custom Domains` list.

```
 backendAddressPools = [
    {
      name = "${local.backend_name}"
      backendAddresses = [
        {
          ipAddress = "${var.ilbIPAddress}"
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
      HostName                       = ""
    },
    {
      name                           = "backend-443-nocookies"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "False"
      HostName                       = ""
    },
  ]
```
