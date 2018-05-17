output "appGwIPs" {
  value = "${azurerm_public_ip.appGwPIP-ukw.*.ip_address},${azurerm_public_ip.appGwPIP-uks.ip_address}"
}
