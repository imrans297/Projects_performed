# Outputs for CI/CD Pipeline Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# EC2 Instance Outputs
output "ansible_controller_public_ip" {
  description = "Public IP of Ansible Controller"
  value       = module.ec2_instances.ansible_controller_public_ip
}

output "ansible_controller_private_ip" {
  description = "Private IP of Ansible Controller"
  value       = module.ec2_instances.ansible_controller_private_ip
}

output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins Master"
  value       = module.ec2_instances.jenkins_master_public_ip
}

output "jenkins_master_private_ip" {
  description = "Private IP of Jenkins Master"
  value       = module.ec2_instances.jenkins_master_private_ip
}

output "jenkins_agents_private_ips" {
  description = "Private IPs of Jenkins Agents"
  value       = module.ec2_instances.jenkins_agents_private_ips
}

output "jenkins_master_url" {
  description = "Jenkins Master URL"
  value       = "http://${module.ec2_instances.jenkins_master_public_ip}:8080"
}

# EKS Outputs (commented out until EKS module is created)
# output "eks_cluster_id" {
#   description = "EKS cluster ID"
#   value       = module.eks.cluster_id
# }

# output "eks_cluster_arn" {
#   description = "EKS cluster ARN"
#   value       = module.eks.cluster_arn
# }

# output "eks_cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   value       = module.eks.cluster_endpoint
# }

# output "eks_cluster_version" {
#   description = "EKS cluster Kubernetes version"
#   value       = module.eks.cluster_version
# }

# output "eks_cluster_security_group_id" {
#   description = "Security group ID attached to the EKS cluster"
#   value       = module.eks.cluster_security_group_id
# }

# output "eks_node_groups" {
#   description = "EKS node groups"
#   value       = module.eks.node_groups
# }

# IAM Outputs
output "ansible_controller_role_arn" {
  description = "ARN of Ansible Controller IAM role"
  value       = module.iam.ansible_controller_role_arn
}

output "jenkins_master_role_arn" {
  description = "ARN of Jenkins Master IAM role"
  value       = module.iam.jenkins_master_role_arn
}

output "jenkins_agent_role_arn" {
  description = "ARN of Jenkins Agent IAM role"
  value       = module.iam.jenkins_agent_role_arn
}

# S3 Outputs
output "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = module.s3.artifacts_bucket_name
}

output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = module.s3.artifacts_bucket_arn
}

# Security Group Outputs
output "ansible_controller_sg_id" {
  description = "Security Group ID for Ansible Controller"
  value       = module.security_groups.ansible_controller_sg_id
}

output "jenkins_master_sg_id" {
  description = "Security Group ID for Jenkins Master"
  value       = module.security_groups.jenkins_master_sg_id
}

output "jenkins_agent_sg_id" {
  description = "Security Group ID for Jenkins Agents"
  value       = module.security_groups.jenkins_agent_sg_id
}

# Connection Information
output "ssh_connection_commands" {
  description = "SSH connection commands for instances"
  value = {
    ansible_controller = "ssh -i ${var.key_pair_name}.pem ubuntu@${module.ec2_instances.ansible_controller_public_ip}"
    jenkins_master     = "ssh -i ${var.key_pair_name}.pem ubuntu@${module.ec2_instances.jenkins_master_public_ip}"
  }
}

# output "kubectl_config_command" {
#   description = "Command to configure kubectl for EKS cluster"
#   value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
# }

# Monitoring Outputs
output "monitoring_dashboard_url" {
  description = "URL of the CloudWatch monitoring dashboard"
  value       = module.monitoring.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "log_groups" {
  description = "CloudWatch log groups for monitoring"
  value       = module.monitoring.log_groups
}

output "monitoring_alarms" {
  description = "CloudWatch alarms created for monitoring"
  value       = module.monitoring.alarms_created
}

# Resource Summary
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    vpc_id                    = module.vpc.vpc_id
    ansible_controller_ip     = module.ec2_instances.ansible_controller_public_ip
    jenkins_master_ip         = module.ec2_instances.jenkins_master_public_ip
    jenkins_agents_count      = var.jenkins_agents_count
    artifacts_bucket          = module.s3.artifacts_bucket_name
    monitoring_dashboard      = module.monitoring.cloudwatch_dashboard_url
    sns_alerts_topic          = module.monitoring.sns_topic_arn
    region                    = var.aws_region
    environment               = var.environment
  }
}