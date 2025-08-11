# Environment Configuration
environment = "dev"
aws_region  = "us-east-1"

# Project Configuration
project_name = "scalable-vpc-arch"
owner        = "DevOps-Team"
cost_center  = "Engineering"

# VPC CIDR Blocks
bastion_vpc_cidr = "192.168.0.0/16"
app_vpc_cidr     = "172.32.0.0/16"

# Subnet CIDR Blocks
bastion_public_subnet_cidrs  = ["192.168.1.0/24", "192.168.2.0/24"]
bastion_private_subnet_cidrs = ["192.168.10.0/24", "192.168.20.0/24"]
app_public_subnet_cidrs      = ["172.32.1.0/24", "172.32.2.0/24"]
app_private_subnet_cidrs     = ["172.32.10.0/24", "172.32.20.0/24"]

# EC2 Configuration
key_pair_name         = "mydev_key"
app_instance_type     = "t3.micro"
bastion_instance_type = "t3.micro"

# Auto Scaling Configuration
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

# Feature Flags
enable_monitoring = true
enable_flow_logs  = true

# Optional Configuration
domain_name           = ""
backup_retention_days = 7

# Additional Tags
common_tags = {
  Department  = "Engineering"
  Application = "WebApp"
}