# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.product}-${var.env}"
  location = "${var.location}"
}

# The ARM template that creates a web app and app service plan
data "template_file" "sitetemplate" {
  template = "${file("${path.module}/templates/waf.json")}"
}

# Create Application Service site
resource "azurerm_template_deployment" "waf" {
  template_body       = "${data.template_file.sitetemplate.rendered}"
  name                = "${var.product}-${var.env}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  deployment_mode     = "Incremental"

  parameters = {
    name               = "${var.product}-${var.env}"
    location           = "${var.location}"
    virtualNetworkName = "${var.vnetname}"
    subnetName         = "${var.subnetname}"

    //When private dns is in place, we should look at using the internal app fqdn
    //over ilb ip
    backendaddress = "${var.backendaddress}"

    appPrivateFqdn = "${var.appPrivateFqdn}"
    probePath      = "${var.probePath}"
    team_name      = "${var.team_name}"
    team_contact   = "${var.team_contact}"
    destroy_me     = "${var.destroy_me}"
    certData       = "${chomp(file("base64"))}"
    certPassword   = "${data.azurerm_key_vault_secret.certPassword.value}"
  }
}

data "azurerm_key_vault_secret" "certPassword" {
  name      = "certPassword"
  vault_uri = "${var.vaultURI}" //"https://core-compute-sandbox.vault.azure.net/"
}
