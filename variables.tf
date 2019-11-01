variable "subscription" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "size" {
  default = "WAF_Medium"
}

variable "tier" {
  default = "WAF"
}

variable "wafName" {}

variable "wafEnabled" {
  default = "true"
}

variable "wafRuleSetType" {
  default = "OWASP"
}

variable "wafRuleSetVersion" {
  default = "3.0"
}

variable "wafMaxRequestBodySize" {
  description = "Maximum request body size in kB for WAF"
  default     = "128"
}

variable "wafFileUploadLimit" {
  description = "Maximum file upload size in MB for WAF"
  default     = "100"
}

variable "sslPolicy" {
  default = "AppGwSslPolicy20170401S"
}

variable "capacity" {
  default = "2"
}

variable "authenticationCertificates" {
  type    = "list"
  default = []
}

variable "gatewayIpConfigurations" {
  type = "list"
}

variable "frontendIPConfigurations" {
  type    = "list"
  default = []
}

variable "frontEndPorts" {
  type    = "list"
  default = []
}

variable "sslCertificates" {
  type = "list"
}

variable "httpListeners" {
  type = "list"
}

variable "backendAddressPools" {
  type = "list"
}

variable "backendHttpSettingsCollection" {
  type    = "list"
  default = []
}

variable "requestRoutingRules" {
  type    = "list"
  default = []
}

variable "requestRoutingRulesPathBased" {
  type    = "list"
  default = []
}

variable "urlPathMaps" {
  type    = "list"
  default = []
}

variable "probes" {
  type    = "list"
  default = []
}

variable "use_authentication_cert" {
  default = false
}

variable "common_tags" {
  type = "map"
}

variable "deployment_target" {
  default = ""
}

variable "exclusions" {
  type = "list"
  default = []
  description = <<EOF
Example:
  [
    {
      "matchVariable": "RequestArgNames",
      "selectorMatchOperator": "Starts with",
      "selector": "example"
    }
  ]

matchVariable: Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.matchVariable.
Options: 
- RequestArgNames
- RequestHeaderNames
- RequestCookieNames

selectorMatchOperator: Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.selectorMatchOperator.
Options: 
- Equals
- Starts with
- Ends with
- Contains
- Equals any

selector: Also known as ApplicationGatewayWebApplicationFirewallConfiguration.exclusions.selector.
https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/applicationgateways#applicationgatewaywebapplicationfirewallconfiguration-object
EOF
}