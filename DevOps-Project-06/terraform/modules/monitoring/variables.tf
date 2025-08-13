# Variables for Monitoring Module

variable "name_prefix" {
  description = "Name prefix for monitoring resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alert_email_addresses" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "jenkins_master_instance_id" {
  description = "Jenkins Master instance ID"
  type        = string
}

variable "jenkins_agent_instance_ids" {
  description = "List of Jenkins Agent instance IDs"
  type        = list(string)
}

variable "ansible_controller_instance_id" {
  description = "Ansible Controller instance ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}