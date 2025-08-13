# Outputs for Security Groups Module

output "common_sg_id" {
  description = "ID of the common security group"
  value       = aws_security_group.common.id
}

output "ansible_controller_sg_id" {
  description = "ID of the Ansible Controller security group"
  value       = aws_security_group.ansible_controller.id
}

output "jenkins_master_sg_id" {
  description = "ID of the Jenkins Master security group"
  value       = aws_security_group.jenkins_master.id
}

output "jenkins_agent_sg_id" {
  description = "ID of the Jenkins Agent security group"
  value       = aws_security_group.jenkins_agent.id
}

output "eks_additional_sg_id" {
  description = "ID of the EKS additional security group"
  value       = aws_security_group.eks_additional.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}