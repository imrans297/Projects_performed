# Production Environment Configuration

# General Configuration
aws_region   = "us-east-1"
environment  = "prod"
project_name = "cicd-pipeline"
owner        = "DevOps-Team"

# Networking Configuration
vpc_cidr                = "10.1.0.0/16"
public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs    = ["10.1.10.0/24", "10.1.20.0/24"]
enable_nat_gateway      = true
enable_flow_logs        = true
allowed_ssh_cidr        = "10.0.0.0/8"  # Restrict to internal networks only

# EC2 Configuration
key_pair_name = "cicd-pipeline-prod-key"

# Instance Types (optimized for production)
ansible_controller_instance_type = "t3.large"
jenkins_master_instance_type     = "t3.xlarge"
jenkins_agent_instance_type      = "t3.large"
jenkins_agents_count             = 3

# EKS Configuration
eks_cluster_version      = "1.28"
eks_node_instance_types  = ["t3.large", "t3.xlarge"]
eks_desired_nodes        = 3
eks_min_nodes           = 2
eks_max_nodes           = 6
eks_node_disk_size      = 100

# Monitoring Configuration
alert_email_addresses = ["devops-alerts@company.com", "sre-team@company.com", "oncall@company.com"]
log_retention_days    = 30

# Common Tags
common_tags = {
  Application = "CI/CD Pipeline"
  Department  = "Engineering"
  CostCenter  = "DevOps"
  Environment = "Production"
  Project     = "Advanced CI/CD Pipeline"
  Owner       = "DevOps Team"
  Backup      = "Critical"
  Monitoring  = "Enhanced"
  Compliance  = "Required"
}