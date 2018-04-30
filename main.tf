# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.product}-${var.env}"
  location = "${var.location}"
}

# The ARM template that creates a Application Gateway, Public IP Address and Traffic Manager Profile
data "template_file" "sitetemplate" {
  template = "${file("${path.module}/templates/waf.json")}"
}

# Create Application Gateway
resource "azurerm_template_deployment" "waf" {
  template_body           = "${data.template_file.sitetemplate.rendered}"
  name                    = "${var.product}-${var.env}"
  resource_group_name     = "${var.resourcegroupname}"
  deployment_mode         = "Incremental"
  parameters = {
    name                  = "${var.product}-${var.env}"
    location              = "${var.location}"
    virtualNetworkName    = "${var.vnetname}"
    subnetName            = "${var.subnetname}"
    backendaddress        = "${var.backendaddress}"
    team_name             = "${var.team_name}"
    team_contact          = "${var.team_contact}"
    env                   = "${var.env}"
    destroy_me            = "${var.destroy_me}"

  }
}
