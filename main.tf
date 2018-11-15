# Create a resource group
# resource "azurerm_resource_group" "rg" {
#   name     = "${var.product}-${var.env}"
#   location = "${var.location}"

#   tags = "${merge(var.common_tags,
#     map("lastUpdated", "${timestamp()}")
#   )}"
# }

# The ARM template that creates a web app and app service plan
data "template_file" "sitetemplate" {
  template = "${file("${path.module}/templates/waf.json")}"
}

# Create Application Service site
resource "azurerm_template_deployment" "waf" {
  template_body       = "${data.template_file.sitetemplate.rendered}"
  name                = "${var.product}-${var.env}"
  resource_group_name = "${var.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    name               = "${var.product}-${var.env}"
    location           = "${var.location}"
    virtualNetworkName = "${var.vnet_name}"
    subnetID           = "${var.subnet_id}"
    backendaddress     = "${var.backend_address}"
    teamName           = "${lookup(var.common_tags, "Team Name")}"
  }
}
