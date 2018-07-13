# moj-module-waf
A module that lets you create an Application Gatewatway with WAF.

## Usage

To use this module you require a cert for the https listener. You must provide the cert represented in base64 with a file named base64 in the root of your project. The cert MUST be password protected and the password must exist in the vault provided to the module under a secret keyed certPassword. 

To produce base64 representation on your cert, do:
  base64 -i cert.pfx -o base64

module "appGw" {
  source            = "git::git@github.com:contino/moj-module-waf"
  product           = "${var.product}"
  location          = "${var.location}"
  env               = "${var.env}"
  vnetname          = "${module.vnet.vnet_id}"
  subnetname        = ["${var.subnet}"]
  backendaddress    = "${var.ilbip}"
  resourcegroupname = "${var.resource_group_name}"
  appPrivateFqdn    = "${var.fqdn}"
  base64Cert        = "${chomp(file("base64"))}"
  vaultURI          = "${var.vaultURI}"
}