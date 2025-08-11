variable "tgw_name" {
  description = "Name of the Transit Gateway"
  type        = string
}

variable "vpc_attachments" {
  description = "List of VPC attachments"
  type = list(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}