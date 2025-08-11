# Production Environment Configuration
environment = "prod"
aws_region  = "us-east-1"

# Instance Configuration (larger for prod)
app_instance_type     = "t3.small"
bastion_instance_type = "t3.micro"

# Auto Scaling (production scale)
asg_min_size         = 2
asg_max_size         = 6
asg_desired_capacity = 3

# Production Features
enable_monitoring = true
backup_retention_days = 30