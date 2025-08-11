variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format: us-east-1, eu-west-1, etc."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "scalable-vpc-arch"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps-Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "bastion_vpc_cidr" {
  description = "CIDR block for bastion VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "app_vpc_cidr" {
  description = "CIDR block for application VPC"
  type        = string
  default     = "172.32.0.0/16"
}

variable "bastion_public_subnet_cidrs" {
  description = "CIDR blocks for bastion public subnets"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "bastion_private_subnet_cidrs" {
  description = "CIDR blocks for bastion private subnets"
  type        = list(string)
  default     = ["192.168.10.0/24", "192.168.20.0/24"]
}

variable "app_public_subnet_cidrs" {
  description = "CIDR blocks for application public subnets"
  type        = list(string)
  default     = ["172.32.1.0/24", "172.32.2.0/24"]
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for application private subnets"
  type        = list(string)
  default     = ["172.32.10.0/24", "172.32.20.0/24"]
}



variable "key_pair_name" {
  description = "Name of the EC2 Key Pair"
  type        = string

  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name cannot be empty."
  }
}

variable "app_instance_type" {
  description = "Instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.asg_min_size >= 1
    error_message = "ASG minimum size must be at least 1."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.asg_max_size >= var.asg_min_size
    error_message = "ASG maximum size must be greater than or equal to minimum size."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.asg_desired_capacity >= var.asg_min_size && var.asg_desired_capacity <= var.asg_max_size
    error_message = "ASG desired capacity must be between min and max size."
  }
}

variable "domain_name" {
  description = "Domain name for Route53 record (optional)"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}