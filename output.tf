output "appGwUksIP" {
  value = "${azurerm_public_ip.appGwPIP-uks.ip_address}"
}

output "appGwUkwIP" {
  value = "${azurerm_public_ip.appGwPIP-ukw.*.ip_address}"
}
