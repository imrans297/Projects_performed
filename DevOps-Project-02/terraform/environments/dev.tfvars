# Development Environment Configuration
environment = "dev"
aws_region  = "us-east-1"

# Instance Configuration (smaller for dev)
app_instance_type     = "t3.micro"
bastion_instance_type = "t3.micro"

# Auto Scaling (minimal for dev)
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# Cost Optimization
enable_monitoring = false
backup_retention_days = 3