# Define local variables
locals {
  wafName   = "${var.product}-${var.env}-multi"
  saAccount = "${var.product}${var.env}${random_id.randomKey.hex}"
  tags      = ""
}

# The location of the ARM Template to start the WAF build
data "template_file" "wafTemplate" {
  template = "${file("${path.module}/templates/appGatewayLoader.json")}"
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resourcegroupname}"
  location = "${var.location}"
}

# Create a random string to help with storage account creation
resource "random_id" "randomKey" {
  byte_length = 2
}

# Create the storage account
resource "azurerm_storage_account" "templateStore" {
  name                     = "${local.saAccount}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the storage account container
resource "azurerm_storage_container" "templates" {
  name                  = "templates"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${local.saAccount}"
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.templateStore"]
}

# Create the SAS key
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
  resource_group_name = "${azurerm_resource_group.rg.name}"
  deployment_mode     = "Incremental"

  parameters = {
    name     = "${local.wafName}"
    size     = "${var.size}"
    tier     = "${var.tier}"
    capacity = "${var.capacity}"

    # location           = "${var.location}"
    # virtualNetworkName = "${var.vnetname}"
    # subnetName         = "${var.subnetname}"

    # Force update of resource on each run
    timestamp = "${timestamp()}"
    # Base URL of the storage account
    baseUri = "${azurerm_storage_account.templateStore.primary_blob_endpoint}${azurerm_storage_container.templates.name}/"
    # The sas token created to access the files in the storage account
    sasToken = "${data.azurerm_storage_account_sas.templateStoreSas.sas}"
    # The front end ports to be created on the WAF
    frontEndPorts = "${base64encode(jsonencode(var.frontEndPorts))}"
    # The front end IP Addresses to be created
    frontendIPConfigurations = "${base64encode(jsonencode(var.frontendIPConfigurations))}"
    # The front HTTP listeners ports to be created on the WAF
    httpListeners = "${base64encode(jsonencode(var.httpListeners))}"
    # The SSL Certificates to be created on the WAF
    sslCertificates = "${base64encode(jsonencode(var.sslCertificates))}"
    # The backend address pools to be created on the WAF
    backendAddressPools = "${base64encode(jsonencode(var.backendAddressPools))}"
    # The http settings to be created on the WAF
    backendHttpSettingsCollection = "${base64encode(jsonencode(var.backendHttpSettingsCollection))}"
    # The request routing rules settings to be created on the WAF
    requestRoutingRules = "${base64encode(jsonencode(var.requestRoutingRules))}"
    # The internal network settings - vNet / Subnet etc
    gatewayIPConfigurations = "${base64encode(jsonencode(var.gatewayIpConfigurations))}"
    # The probe settings
    probes = "${base64encode(jsonencode(var.probes))}"
    # The request routing rules settings to be created on the WAF
    tags = "${local.tags}"

    #When private dns is in place, we should look at using the internal app fqdn over ilb ip
    # backendaddress = "${jsonencode(var.backendaddress)}"

    # appPrivateFqdn = "${var.appPrivateFqdn}"
    # probePath      = "${var.probePath}"
    # team_name      = "${var.team_name}"
    # team_contact   = "${var.team_contact}"
    # destroy_me     = "${var.destroy_me}"
    # certData       = "${chomp(file("base64"))}"
    # certPassword   = "${data.azurerm_key_vault_secret.certPassword.value}"
  }
}

# data "azurerm_key_vault_secret" "certPassword" {
#   name      = "certPassword"
#   vault_uri = "${var.vaultURI}" //"https://core-compute-sandbox.vault.azure.net/"
# }


# output "backendAddressPools" {
#   value = "${jsonencode(var.backendAddressPools)}"
# }


# output "frontEndPorts" {
#   value = "${jsonencode(var.frontEndPorts)}"
# }


# output "frontendIPConfigurations" {
#   value = "${jsonencode(var.frontendIPConfigurations)}"
# }


# output "httpListeners" {
#   value = "${jsonencode(var.httpListeners)}"
# }


# output "sslCertificates" {
#   value = "${jsonencode(var.sslCertificates)}"
# }


# output "backendHttpSettingsCollection" {
#   value = "${jsonencode(var.backendHttpSettingsCollection)}"
# }


# output "requestRoutingRules" {
#   value = "${jsonencode(var.requestRoutingRules)}"
# }


# output "sas_url_query_string" {
#   value = "${data.azurerm_storage_account_sas.templateStoreSas.sas}"
# }


# output "connectionString" {
#   value = "${azurerm_storage_account.templateStore.primary_blob_connection_string}"
# }


# output "templateURI" {
#   value = "${azurerm_storage_account.templateStore.primary_blob_endpoint}${azurerm_storage_container.templates.name}/"
# }

