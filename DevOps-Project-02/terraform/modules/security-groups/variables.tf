variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "bastion_vpc_id" {
  description = "ID of the bastion VPC"
  type        = string
}

variable "app_vpc_id" {
  description = "ID of the application VPC"
  type        = string
}

variable "bastion_vpc_cidr" {
  description = "CIDR block of the bastion VPC"
  type        = string
}

variable "app_vpc_cidr" {
  description = "CIDR block of the application VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}