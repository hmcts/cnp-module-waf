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
    name                = "${var.product}-${var.env}"
    virtualNetworkName  = "${var.vnetname}"
    subnetName          = "${var.subnetname}"
    backendAddressPools = "${jsonencode(var.backendaddresspools)}"
  }
}
