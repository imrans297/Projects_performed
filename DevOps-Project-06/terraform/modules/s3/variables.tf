# Variables for S3 Module

variable "name_prefix" {
  description = "Name prefix for S3 resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}