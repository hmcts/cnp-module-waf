data "azurerm_public_ip" "waf_public_ip" {
  depends_on = ["azurerm_template_deployment.waf"]
  
  name                = "${local.wafName}-pip"
  resource_group_name = "${var.resourcegroupname}"
}

output "public_ip_fqdn" {
  value = "${data.azurerm_public_ip.waf_public_ip.fqdn}"
}
