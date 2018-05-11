variable "product" {
  type = "string"
}

variable "locations" {
  type    = "list"
  default = ["UK South", "UK West"]
}

variable "vnetname" {
  type = "list"
}

variable "subnetname" {
  type = "list"
}

variable "env" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "ilbUKS" {
  default = "0.0.0.0"
}

variable "ilbUKW" {
  default = "0.0.0.0"
}

variable "healthCheck" {
  default     = "/health"
  description = "endpoint for healthcheck"
}

variable "healthCheckInterval" {
  default     = "60"
  description = "interval between healthchecks in seconds"
}

variable "unhealthyThreshold" {
  default     = "3"
  description = "unhealthy threshold applied to healthprobe"
}

//TAG SPECIFIC VARIABLES
variable "team_name" {
  type        = "string"
  description = "The name of your team"
  default     = "CNP (Contino)"
}

variable "team_contact" {
  type        = "string"
  description = "The name of your Slack channel people can use to contact your team about your infrastructure"
  default     = "#Cloud-Native"
}

variable "destroy_me" {
  type        = "string"
  description = "Here be dragons! In the future if this is set to Yes then automation will delete this resource on a schedule. Please set to No unless you know what you are doing"
  default     = "No"
}
