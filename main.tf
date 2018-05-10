# Public ip for assigning to app gateway - Only created if var.is_frontend is set to true
resource "azurerm_public_ip" "appGwPIP" {
  count                        = 2
  name                         = "appGW-${element(var.locations, count.index)}"
  location                     = "${element(var.locations, count.index)}"
  resource_group_name          = "${var.resourcegroupname}"
  public_ip_address_allocation = "dynamic"
}

# Application gateway with WAF - Only created if var.is_frontend is set to true
resource "azurerm_application_gateway" "waf" {
  count               = 2
  name                = "${var.product}-${var.env}-${element(var.locations, count.index)}"
  resource_group_name = "${var.resourcegroupname}"
  location            = "${replace(${element(var.locations, count.index)},"uk ","")}"

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = "${var.subnetname}"
  }

  frontend_port {
    name = "http80"
    port = 80
  }

  frontend_port {
    name = "http443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGW-IP"
    public_ip_address_id = "${element(azurerm_public_ip.appGwPIP.*.id, count.index)}"
  }

  backend_address_pool {
    name            = "backendPool"
    ip_address_list = ["${var.ilbIp}"]
  }

  backend_http_settings {
    name                  = "backendSettingsHTTP"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "http"
  }

  backend_http_settings {
    name                  = "backendSettingsHTTPS"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 1
    probe_name            = "https"
  }

  http_listener {
    name                           = "httplstn"
    frontend_ip_configuration_name = "appGW-IP"
    frontend_port_name             = "http80"
    protocol                       = "Http"
  }

  # http_listener {
  #   name                           = "httpslstn"
  #   frontend_ip_configuration_name = "appGW-IP"
  #   frontend_port_name             = "http443"
  #   protocol                       = "Https"
  #   ssl_certificate_name           = "${var.env}"
  # }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "httplstn"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "backendSettingsHTTP"
  }
  waf_configuration {
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
    enabled          = "true"
  }
  probe {
    name                = "http"
    protocol            = "http"
    path                = "${var.healthCheck}"
    host                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
    interval            = "${var.healthCheckInterval}"
    unhealthy_threshold = "${var.unhealthyThreshold}"
    timeout             = "60"
  }
  probe {
    name                = "https"
    protocol            = "https"
    path                = "${var.healthCheck}"
    host                = "${var.product}-${var.env}.service.core-compute-${var.env}.internal"
    interval            = "${var.healthCheckInterval}"
    unhealthy_threshold = "${var.unhealthyThreshold}"
    timeout             = "60"
  }
}
