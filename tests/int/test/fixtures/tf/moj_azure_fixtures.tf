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
  type = "string"
}

variable "subnetname" {
  type = "string"
}

variable "backendaddresspools" {
  type = "map"

  default = {
    IpAddress = "51.140.71.70"
  }
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
  source              = "../../../../../"
  product             = "${var.random_name}-waf"
  location            = "${var.location}"
  env                 = "${var.env}"
  vnetname            = "${data.terraform_remote_state.core_sandbox_infrastructure.vnetname}"
  subnetname          = "${data.terraform_remote_state.core_sandbox_infrastructure.subnet_names[0]}"
  backendaddresspools = "${var.backendaddresspools}"
}

output "random_name" {
  value = "${var.random_name}"
}
