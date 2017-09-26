provider "azurerm" {}

variable "location" {
  default = "UK South"
}

variable "product" {
  default = "inspect"
}

variable "random_name" {}

variable "branch_name" {}

variable "env" {
  default = "int"
}

variable "vnetname" {
  type    = "string"
  default = "/subscriptions/bf308a5c-0624-4334-8ff8-8dca9fd43783/resourceGroups/sandbox-core-infra-dev/providers/Microsoft.Network/virtualNetworks/sandbox-core-infra-vnet-dev"
}

variable "subnetname" {
  type    = "string"
  default = "sandbox-core-infra-subnet-0-dev"
}

variable "backendaddress" {
  type    = "string"
  default = "51.140.71.70"
}

data "terraform_remote_state" "core_sandbox_infrastructure" {
  backend = "azure"

  config {
    resource_group_name  = "contino-moj-tf-state"
    storage_account_name = "continomojtfstate"
    container_name       = "contino-moj-tfstate-container"
    key                  = "sandbox-core-infra/dev/terraform.tfstate"
  }
}

module "waf" {
  source         = "../../../../../"
  product        = "${var.random_name}"
  location       = "${var.location}"
  env            = "${var.env}"
  vnetname       = "${data.terraform_remote_state.core_sandbox_infrastructure.vnet_id}"
  subnetname     = "${data.terraform_remote_state.core_sandbox_infrastructure.subnet_names[0]}"
  backendaddress = "${var.backendaddress}"
}

output "random_name" {
  value = "${var.random_name}"
}
