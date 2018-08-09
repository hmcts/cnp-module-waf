# Define local variables
locals {
  wafName = "${var.wafName}-${var.env}"
  tags    = ""

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
      data = "${data.local_file.ilbCertFile.content}"
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
    },
    {
      name               = "default-https-probe"
      protocol           = "Https"
      path               = "/health"
      interval           = 30
      timeout            = 30
      unhealthyThreshold = 3

      # Can be used if backed is resolvable in DNS
      pickHostNameFromBackendHttpSettings = "true"
      backendHttpSettings                 = "ilb-https"
    },
  ]

  defaultFrontendIPConfigurations = [
    {
      name         = "appGatewayFrontendIP"
      publicIpName = "${var.wafName}-pip"
    },
  ]

  frontendIPConfigurations      = "${concat(local.defaultFrontendIPConfigurations, var.frontendIPConfigurations)}"
  frontEndPorts                 = "${concat(local.defaultFrontEndPorts, var.frontEndPorts)}"
  authenticationCertificates    = "${concat(local.defaultAuthenticationCertificates, var.authenticationCertificates)}"
  backendHttpSettingsCollection = "${concat(local.defaultBackendHttpSettingsCollection, var.backendHttpSettingsCollection)}"
  probes                        = "${concat(local.defaultProbes, var.probes)}"
}

# The location of the ARM Template to start the WAF build
data "template_file" "wafTemplate" {
  template = "${file("${path.module}/templates/appGatewayLoader.json")}"
}

# Create the resource group
# resource "azurerm_resource_group" "rg" {
#   name     = "${var.resourcegroupname}-${var.env}"
#   location = "${var.location}"
# }

########################################################################################################################
#
# This section is used to grab the certificate from the vault, format it and store it for the backend authentication 
#
########################################################################################################################

resource "null_resource" "ilbCert" {
  triggers {
    trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash -e ${path.module}/getCert.sh infra-vault-${var.subscription} core-compute-${var.env} ${path.module} ${var.subscription}"
  }
}

data "local_file" "ilbCertFile" {
  filename   = "${path.module}/core-compute-${var.env}.out.2"
  depends_on = ["null_resource.ilbCert"]
}

#
# Create the storage account
#
resource "azurerm_storage_account" "templateStore" {
  name                     = "${var.storageAccountName}"
  resource_group_name      = "${var.resourcegroupname}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#
# Create the storage account container
#
resource "azurerm_storage_container" "templates" {
  name                  = "templates"
  resource_group_name   = "${var.resourcegroupname}"
  storage_account_name  = "${var.storageAccountName}"
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

# Run the WAF Template
resource "azurerm_template_deployment" "waf" {
  depends_on          = ["data.azurerm_storage_account_sas.templateStoreSas"]
  template_body       = "${data.template_file.wafTemplate.rendered}"
  name                = "${local.wafName}"
  resource_group_name = "${var.resourcegroupname}"
  deployment_mode     = "Incremental"

  parameters = {
    name     = "${local.wafName}"
    size     = "${var.size}"
    tier     = "${var.tier}"
    capacity = "${var.capacity}"
    location = "${var.location}"

    # virtualNetworkName = "${var.vnetname}"
    # subnetName         = "${var.subnetname}"

    wafEnabled        = "${var.wafEnabled}"
    wafMode           = "${var.wafMode}"
    wafRuleSetType    = "${var.wafRuleSetType}"
    sslPolicy         = "${var.sslPolicy}"
    wafRuleSetVersion = "${var.wafRuleSetVersion}"
    # Force update of resource on each run
    timestamp = "${timestamp()}"
    # Base URL of the storage account
    baseUri = "${azurerm_storage_account.templateStore.primary_blob_endpoint}${azurerm_storage_container.templates.name}/"
    # The sas token created to access the files in the storage account
    sasToken = "${data.azurerm_storage_account_sas.templateStoreSas.sas}"
    # The front end ports to be created on the WAF
    authenticationCertificates = "${base64encode(jsonencode(local.authenticationCertificates))}"
    # The front end ports to be created on the WAF
    frontEndPorts = "${base64encode(jsonencode(local.frontEndPorts))}"
    # The front end IP Addresses to be created
    frontendIPConfigurations = "${base64encode(jsonencode(local.frontendIPConfigurations))}"
    # The front HTTP listeners ports to be created on the WAF
    httpListeners = "${base64encode(jsonencode(var.httpListeners))}"
    # The SSL Certificates to be created on the WAF
    sslCertificates = "${base64encode(jsonencode(var.sslCertificates))}"
    # The backend address pools to be created on the WAF
    backendAddressPools = "${base64encode(jsonencode(var.backendAddressPools))}"
    # The http settings to be created on the WAF
    backendHttpSettingsCollection = "${base64encode(jsonencode(local.backendHttpSettingsCollection))}"
    # The request routing rules settings to be created on the WAF
    requestRoutingRules = "${base64encode(jsonencode(var.requestRoutingRules))}"
    # The internal network settings - vNet / Subnet etc
    gatewayIPConfigurations = "${base64encode(jsonencode(var.gatewayIpConfigurations))}"
    # The probe settings
    probes = "${base64encode(jsonencode(local.probes))}"
    # The request routing rules settings to be created on the WAF
    tags = "${local.tags}"
  }
}