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
  resource_group_name = "${var.resourcegroupname}"
  deployment_mode     = "Incremental"

  parameters = {
    name                   = "${var.product}-${var.env}"
    location               = "${var.location}"
    virtualNetworkName     = "${var.vnetname}"
    subnetName             = "${var.subnetname}"
    backend_port           = "${var.backend_port}"
    backend_protocol       = "${var.backend_protocol}"
    backendaddress         = "${var.backendaddress}"
    certificatePfxBase64   = "${var.certificatePfxBase64}"
    certificatePrefixName  = "${var.certificatePrefixName}"
    certificatePfxPassword = "${var.certificatePfxPassword}"
  }
}
