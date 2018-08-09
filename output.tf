# output "waf_name" {
#   value = "${azurerm_template_deployment.waf.name}"
# }

# output "appGwIP" {
#   value = "${azurerm_template_deployment.waf.outputs["appGwIP"]}"
# }

#   "outputs": {
#     "appGwIP": {
#       "type": "string",
#       "value":
#         "[reference(parameters('appGatewaySettings').frontendIPConfigurations[0].PublicIPName).publicIPAddress]"
#     }
#   }