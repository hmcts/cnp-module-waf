output "appGwUksID" {
  value = "${azurerm_application_gateway.wafuks.name}"
}

output "appGwUkwID" {
  value = "${azurerm_application_gateway.wafukw.name}"
}
