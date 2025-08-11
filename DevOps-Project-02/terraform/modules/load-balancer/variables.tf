variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "load_balancer_type" {
  description = "Type of load balancer"
  type        = string
  default     = "network"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}