variable "product" {
  type = "string"
}

variable "locations" {
  type    = "list"
  default = ["UK South", "UK West"]
}

variable "vnetname" {
  type = "string"
}

variable "subnetname" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "ilbIp" {
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
