# Outputs for IAM Module

# Ansible Controller
output "ansible_controller_role_arn" {
  description = "ARN of the Ansible Controller IAM role"
  value       = aws_iam_role.ansible_controller.arn
}

output "ansible_controller_instance_profile_name" {
  description = "Name of the Ansible Controller instance profile"
  value       = aws_iam_instance_profile.ansible_controller.name
}

# Jenkins Master
output "jenkins_master_role_arn" {
  description = "ARN of the Jenkins Master IAM role"
  value       = aws_iam_role.jenkins_master.arn
}

output "jenkins_master_instance_profile_name" {
  description = "Name of the Jenkins Master instance profile"
  value       = aws_iam_instance_profile.jenkins_master.name
}

# Jenkins Agent
output "jenkins_agent_role_arn" {
  description = "ARN of the Jenkins Agent IAM role"
  value       = aws_iam_role.jenkins_agent.arn
}

output "jenkins_agent_instance_profile_name" {
  description = "Name of the Jenkins Agent instance profile"
  value       = aws_iam_instance_profile.jenkins_agent.name
}

# EKS Cluster
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

# EKS Node Group
output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}