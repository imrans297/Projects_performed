# Variables for EC2 Module

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "ansible_controller_config" {
  description = "Configuration for Ansible Controller instance"
  type = object({
    instance_type        = string
    subnet_id           = string
    security_group_ids  = list(string)
    iam_instance_profile = string
    key_name            = string
    name                = string
  })
}

variable "jenkins_master_config" {
  description = "Configuration for Jenkins Master instance"
  type = object({
    instance_type        = string
    subnet_id           = string
    security_group_ids  = list(string)
    iam_instance_profile = string
    key_name            = string
    name                = string
  })
}

variable "jenkins_agents_config" {
  description = "Configuration for Jenkins Agent instances"
  type = object({
    count               = number
    instance_type       = string
    subnet_ids          = list(string)
    security_group_ids  = list(string)
    iam_instance_profile = string
    key_name            = string
    name_prefix         = string
  })
}

variable "ansible_ssh_public_key" {
  description = "Public key for Ansible SSH communication (optional - will generate if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}