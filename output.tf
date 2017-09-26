output "webapp_name" {
  value = "${azurerm_template_deployment.waf.name}"
}
