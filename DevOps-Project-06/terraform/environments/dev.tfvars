# Development Environment Configuration

# General Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "cicd-pipeline"
owner        = "DevOps-Team"

# Networking Configuration
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
enable_nat_gateway      = true
enable_flow_logs        = true
allowed_ssh_cidr        = "0.0.0.0/0"  # Restrict this to your IP range in production

# EC2 Configuration
key_pair_name = "cicd-pipeline-key"  # Make sure this key pair exists in your AWS account

# Instance Types (optimized for development)
ansible_controller_instance_type = "t2.micro"
jenkins_master_instance_type     = "t2.medium"
jenkins_agent_instance_type      = "t2.medium"
jenkins_agents_count             = 1

# EKS Configuration (for future use)
eks_cluster_version      = "1.28"
eks_node_instance_types  = ["t3.medium"]
eks_desired_nodes        = 2
eks_min_nodes           = 1
eks_max_nodes           = 4
eks_node_disk_size      = 50

# Monitoring Configuration
alert_email_addresses = ["imrandev0407@gmail.com"]
log_retention_days    = 14

# Common Tags
common_tags = {
  Application = "CI/CD Pipeline"
  Department  = "Engineering"
  CostCenter  = "DevOps"
  Environment = "Development"
  Project     = "Advanced CI/CD Pipeline"
  Owner       = "DevOps Team"
  Backup      = "Required"
  Monitoring  = "Enabled"
}