# output "waf_name" {
#   value = "${azurerm_template_deployment.waf.name}"
# }

output "appGwIP" {
  value = "${azurerm_template_deployment.waf.appGwIP}"
}
