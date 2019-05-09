# Define local variables
locals {
  wafName   = "${var.wafName}-${var.env}${var.deployment_target}"
  saAccount = "templates${random_id.randomKey.hex}"

  defaultFrontEndPorts = [
    {
      name = "frontendPort80"
      port = 80
    },
    {
      name = "frontendPort443"
      port = 443
    },
  ]

  # Default backend certificates
  defaultAuthenticationCertificates = [
    {
      name = "ilbCert"
      data = "${element(concat(data.local_file.ilbCertFile.*.content, list("")), 0)}"
    },
  ]

  # Adding in default Backend HTTP Settings to go to the backed on http and https
  defaultBackendHttpSettingsCollection = [
    {
      name                           = "ilb-http"
      port                           = 80
      Protocol                       = "Http"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = ""
      probeEnabled                   = "True"
      probe                          = "default-http-probe"
      PickHostNameFromBackendAddress = "True"
    },
    {
      name                           = "ilb-https"
      port                           = 443
      Protocol                       = "Https"
      CookieBasedAffinity            = "Disabled"
      AuthenticationCertificates     = "ilbCert"
      probeEnabled                   = "True"
      probe                          = "default-https-probe"
      PickHostNameFromBackendAddress = "True"
    },
  ]

  defaultProbes = [
    {
      name               = "default-http-probe"
      protocol           = "Http"
      path               = "/health"
      interval           = 30
      timeout            = 30
      unhealthyThreshold = 3

      # Can be used if backed is resolvable in DNS
      pickHostNameFromBackendHttpSettings = "true"
      backendHttpSettings                 = "ilb-http"
      host = ""
    },
    {
      name               = "default-https-probe"
      protocol           = "Https"
      path               = "/health"
      interval           = 30
      timeout            = 30
      unhealthyThreshold = 3
      host               = ""

      # Can be used if backed is resolvable in DNS
      pickHostNameFromBackendHttpSettings = "true"
      backendHttpSettings                 = "ilb-https"
    },
  ]

  defaultFrontendIPConfigurations = [
    {
      name         = "appGatewayFrontendIP"
      publicIpName = "${local.wafName}-pip"
    },
  ]

  frontendIPConfigurations      = "${concat(local.defaultFrontendIPConfigurations, var.frontendIPConfigurations)}"
  frontEndPorts                 = "${concat(local.defaultFrontEndPorts, var.frontEndPorts)}"
  authenticationCertificates    = "${concat(local.defaultAuthenticationCertificates, var.authenticationCertificates)}"
  backendHttpSettingsCollection = "${var.backendHttpSettingsCollection}"
  probes                        = "${var.probes}"
}

# The location of the ARM Template to start the WAF build
data "template_file" "wafTemplate" {
  template = "${file("${path.module}/templates/appGatewayLoader.json")}"
}

########################################################################################################################
#
# This section is used to grab the certificate from the vault, format it and store it for the backend authentication 
#
########################################################################################################################

resource "null_resource" "ilbCert" {
  count = "${var.use_authentication_cert ? 1 : 0}"
  triggers {
    trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash -e ${path.module}/getCert.sh infra-vault-${var.subscription} core-compute-${var.env} ${path.module} ${var.subscription}"
  }
}

data "local_file" "ilbCertFile" {
  count = "${var.use_authentication_cert ? 1 : 0}"
  filename   = "${path.module}/core-compute-${var.env}.out.2"
  depends_on = ["null_resource.ilbCert"]
}

#
# Create a random string to help with storage account creation
#
resource "random_id" "randomKey" {
  byte_length = 2
}

#
# Create the storage account
#
resource "azurerm_storage_account" "templateStore" {
  name                     = "${local.saAccount}"
  resource_group_name      = "${var.resourcegroupname}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = "${var.common_tags}"
}

#
# Create the storage account container
#
resource "azurerm_storage_container" "templates" {
  name                  = "templates"
  resource_group_name   = "${var.resourcegroupname}"
  storage_account_name  = "${local.saAccount}"
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.templateStore"]
}

#
# Create the SAS key
#
data "azurerm_storage_account_sas" "templateStoreSas" {
  depends_on        = ["azurerm_storage_account.templateStore"]
  connection_string = "${azurerm_storage_account.templateStore.primary_connection_string}"
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  // TF doesn't currently have a way to compute custom formatted dates - so leaving this hard coded.
  start  = "2018-07-01"
  expiry = "2020-07-01"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

# Run bash script to upload the templates
resource "null_resource" "uploadTemplate" {
  depends_on = ["azurerm_storage_account.templateStore"]

  triggers {
    trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash -e ${path.module}/templateUpload.sh '${azurerm_storage_account.templateStore.primary_blob_connection_string}' ${path.module}/templates/ ${azurerm_storage_container.templates.name} ${var.subscription}"
  }
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "hmcts-${var.subscription}"
  resource_group_name = "oms-automation"
}

# Run the WAF Template
resource "azurerm_template_deployment" "waf" {
  depends_on          = ["data.azurerm_storage_account_sas.templateStoreSas"]
  template_body       = "${data.template_file.wafTemplate.rendered}"
  name                = "${local.wafName}-ag"
  resource_group_name = "${var.resourcegroupname}"
  deployment_mode     = "Incremental"

  parameters = {
    name     = "${local.wafName}"
    size     = "${var.size}"
    tier     = "${var.tier}"
    capacity = "${var.capacity}"
    location = "${var.location}"
    wafMode           = "Prevention"
    wafEnabled        = "${var.wafEnabled}"
    wafRuleSetType    = "${var.wafRuleSetType}"
    wafMaxRequestBodySize = "${var.wafMaxRequestBodySize}"
    wafFileUploadLimit = "${var.wafFileUploadLimit}"
    sslPolicy         = "${var.sslPolicy}"
    wafRuleSetVersion = "${var.wafRuleSetVersion}"
    baseUri = "${azurerm_storage_account.templateStore.primary_blob_endpoint}${azurerm_storage_container.templates.name}/"
    sasToken = "${data.azurerm_storage_account_sas.templateStoreSas.sas}"
    authenticationCertificates = "${base64encode(jsonencode(local.authenticationCertificates))}"
    frontEndPorts = "${base64encode(jsonencode(local.frontEndPorts))}"
    frontendIPConfigurations = "${base64encode(jsonencode(local.frontendIPConfigurations))}"
    httpListeners = "${base64encode(jsonencode(var.httpListeners))}"
    sslCertificates = "${base64encode(jsonencode(var.sslCertificates))}"
    backendAddressPools = "${base64encode(jsonencode(var.backendAddressPools))}"
    backendHttpSettingsCollection = "${base64encode(jsonencode(local.backendHttpSettingsCollection))}"
    requestRoutingRules = "${base64encode(jsonencode(var.requestRoutingRules))}"
    requestRoutingRulesPathBased = "${base64encode(jsonencode(var.requestRoutingRulesPathBased))}"
    urlPathMaps = "${base64encode(jsonencode(var.urlPathMaps))}"
    gatewayIPConfigurations = "${base64encode(jsonencode(var.gatewayIpConfigurations))}"
    probes                  = "${base64encode(jsonencode(local.probes))}"
    logAnalyticsWorkspaceId = "${data.azurerm_log_analytics_workspace.log_analytics.id}"
    tags = "${base64encode(jsonencode(var.common_tags))}"
  }
}
