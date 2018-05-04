variable "product" {
  type = "string"
}

variable "location" {
  type    = "string"
  default = "UK South"
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

variable "backendaddress" {
  type = "string"
}

variable "resourcegroupname" {
  type = "string"
}

variable "team_name" {
  type        = "string"
  default     = "Not Supplied"
  description = "(256 Char Max Length) The name of the team who owns this infrastructure"
}

variable "team_contact" {
  type        = "string"
  default     = "Not Defined"
  description = "Contact Information of Product Owner"
}

variable "destroy_me" {
  type        = "string"
  default     = "No"
  description = "Choose either Yes or No. This is planned to auto-cleanup resources but currently just sets a tag."
}
