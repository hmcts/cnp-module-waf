# moj-module-waf
A module that lets you create an Application Gatewatway with WAF.

## Usage

To use this module you require a cert for the https listener. The cert must be uploaded to the infra vault for the subscription being deployed to (infra-vault-$subscription). Once the cert exists in the vault, we use a terraform data resource to read it and pass into the app gateway module for example:

``` 
data "azurerm_key_vault_secret" "cert" {
  name      = "S{var.certificateName}"
  vault_uri = "https://infra-vault-${var.subscription}.vault.azure.net/"
}

module "appGw" {
  source             = "git@github.com:hmcts/moj-module-waf?"
  env                = "${var.env}"
  subscription       = "${var.subscription}"
  location           = "${var.location}"
  wafName            = "${var.product}-shared-waf"
  resourcegroupname  = "${azurerm_resource_group.shared_resource_group.name}"
  team_name          = "${var.team_name}"
  team_contact       = "${var.team_contact}"
  destroy_me         = "${var.destroy_me}"
  ilbIp              = "${var.ilbIp}"
  }
```

 


