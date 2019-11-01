# cnp-module-waf

A module that lets you create an Application Gatewatway with WAF.

## Usage

To use this module you require a cert for the https listener. The cert (`certificate_name`) must be uploaded to a key vault. Once the cert exists in the vault, you will need to use a terraform data resource to read it and pass into the app gateway module for example:

```terraform
locals {
  backend_name = "${var.product}-${var.component}-${var.env}"
  backend_hostname = "${local.backend_name}.service.${var.env}.platform.hmcts.net"
}

data "azurerm_subnet" "app_gateway_subnet" {
  name                 = "core-infra-subnet-appGw-${var.env}"
  virtual_network_name = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
}

data "azurerm_key_vault_secret" "cert" {
  name      = "my-public-facing-domain-cert-name-stored-in-vault"
  vault_uri = "https://my-cert-vault.vault.azure.net/" // This value should be REPLACED with a valid URL
}

module "waf" {
  source             = "git@github.com:hmcts/cnp-module-waf?ref=v1.0.0"
  env                = "${var.env}"
  subscription       = "${var.subscription}"
  location           = "${var.location}"
  wafName            = "${var.product}"
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
      name     = "public-hostname-cert" // IT COULD BE ANYTHING
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
      SslCertificate          = "public-hostname-cert" // THIS SHOULD MATCH THE NAME SPECIFIED ABOVE IN SSL CERTIFICATES LIST
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
      
      # For more information on using AuthenticationCertificates to enable
      # e2e encryption with ASE, please see the "Using authentication certificates"
      # section below, this is needed if your hostname for your app ends in .internal.
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
      
      # For more information on using AuthenticationCertificates to enable
      # e2e encryption with ASE, please see the "Using authentication certificates"
      # section below, this is needed if your hostname for your app ends in .internal
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
  
  exclusions = [
    {
      "matchVariable" = "RequestArgNames",
      "selectorMatchOperator" = "StartsWith",
      "selector" = "password"
    }
  ]
  ...
```

## Using authentication certificates

When deploying the application gateway to an environment (App Service Environment) which has a self-signed certificate associated to its internal load balancer (ILB), it will be necessary to whitelist this certificate in order to achieve end-to-end SSL encryption.

The example above would have to be modified with the following properties.

```terraform
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
      AuthenticationCertificates     = "ilbCert" // <<<--- The name of the certificate to use, if ilbCert then it will be automatically found for you. 
      probeEnabled                   = "True"
      probe                          = "https-probe"
      PickHostNameFromBackendAddress = "True"
    },
  ]
```

## Using Path Based Routing Rules

In Azure Application Gateway, it's possible to apply request routing based on
the routes. For example, for diverting requests for a specific path (e.g.
/uploads) to another backend pool the following changes need to be done to the
configuration above.

This configuration diverts those requests made to `/uploads` to another backed
(i.e. palo-alto) while the others are sent to the default backend address pool.

The `PathBased` routing requires sections identified with
`requestRoutingRulesPathBased` and `urlPathMaps` and these sections are
optional in case only `Basic` routing is used. It is possible to mix the Basic
rule setting and PathBasedRouting as in the following sample.

```terraform
  requestRoutingRules = [
   {
      name                = "http-www"
      ruleType            = "Basic"
      httpListener        = "${var.product}-http-listener-www"
      backendAddressPool  = "${var.product}-${var.env}-backend-pool"
      backendHttpSettings = "backend-80-nocookies-www"
    },
    {
      name                = "https-www"
      ruleType            = "Basic"
      httpListener        = "${var.product}-https-listener-www"
      backendAddressPool  = "${var.product}-${var.env}-backend-pool"
      backendHttpSettings = "backend-443-nocookies-www"
  ]

  requestRoutingRulesPathBased = [
    {
      name                = "http-gateway"
      ruleType            = "PathBasedRouting"
      httpListener        = "${var.product}-http-listener-gateway"
      urlPathMap          = "http-url-path-map-gateway"
    },
    {
      name                = "https-gateway"
      ruleType            = "PathBasedRouting"
      httpListener        = "${var.product}-https-listener-gateway"
      urlPathMap          = "https-url-path-map-gateway"
    }
  ]

  urlPathMaps = [
    {
      name                       = "http-url-path-map-gateway"
      defaultBackendAddressPool  = "${var.product}-${var.env}-backend-pool"
      defaultBackendHttpSettings = "backend-80-nocookies-gateway"
      pathRules                  = [
        {
          name                = "http-url-path-map-gateway-rule-palo-alto"
          paths               = ["/uploads"]
          backendAddressPool  = "${var.product}-${var.env}-palo-alto"
          backendHttpSettings = "backend-80-nocookies-gateway"
        }
      ]
    },
    {
      name                       = "https-url-path-map-gateway"
      defaultBackendAddressPool  = "${var.product}-${var.env}-backend-pool"
      defaultBackendHttpSettings = "backend-80-nocookies-gateway"
      pathRules                  = [
        {
          name                = "https-url-path-map-gateway-rule-palo-alto"
          paths               = ["/uploads"]
          backendAddressPool  = "${var.product}-${var.env}-palo-alto"
          backendHttpSettings = "backend-80-nocookies-gateway"
        }
      ]
    }
  ]
```

See `ccd-shared-infrastructure` project for a fully working sample of the `PathBasedRouting`

## Configuring the backends

The Application Service Environment (ASE) uses the hostname from the request to determine which application will receive the request. For this reason, is necessary that the correct hostname to be forwarded from the Application Gateway (WAF) to the ILB.

There are 3 possible configurations that fulfill this requirements.

### Pick hostname from backend address

This is the option followed in the main example. The idea behind it lies on using the the FQDN internal domain name of the frontend or service as the backend address, and then use that same FQDN as the hostname for the forwarded request by setting the property `PickHostNameFromBackendAddress` to `True`.

Is worth mentioning that with this approach the FE service would not need the public domain name listed in the `Custom Domains` section.

### Force/Override Hostname

For this option the backend address could either be the FQDN of the service or the Application Service Environment ILB IP address. The property `PickHostNameFromBackendAddress` would be set to `False` and a new property called "HostName" will need to be added.

```terraform
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
      HostName                       = "${local.backend_hostname}" // This is where the hostname is being set
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

```terraform
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

### Deployment target

`deployment_target` parameter, type = String, Required = No, Default value = "", Description = Name of the Deployment Target. If `deployment_target` is empty it works in legacy mode


## Using Application Gateway Firewall Exclusions

Exclusions default to none. The current configuration for exclusions supports one match variable and operator option and multiple selectors.

```terraform
module "waf" {
  ...
  exclusions = [
    {
      "matchVariable" = "RequestArgNames",
      "selectorMatchOperator" = "StartsWith",
      "selector" = "password"
    }
  ]
  ...
}
```

**Exclusion Match Variable**

Options: 
- `RequestArgNames`
- `RequestHeaderNames`
- `RequestCookieNames`

Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.matchVariable.

**Exclusion Operator**

Options: 
- `Equals`
- `StartsWith`
- `EndsWith`
- `Contains`
- `EqualsAny`

Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.selectorMatchOperator.

**Exclusion Selector**

Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.selector.

> Reference: 
> * https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-waf-configuration
> * https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/applicationgateways#applicationgatewaywebapplicationfirewallconfiguration-object
> * https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/applicationgateways#ApplicationGatewayFirewallExclusion