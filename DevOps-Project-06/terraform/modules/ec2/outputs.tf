# Outputs for EC2 Module

# Ansible Controller
output "ansible_controller_id" {
  description = "ID of the Ansible Controller instance"
  value       = aws_instance.ansible_controller.id
}

output "ansible_controller_public_ip" {
  description = "Public IP of the Ansible Controller"
  value       = aws_eip.ansible_controller.public_ip
}

output "ansible_controller_private_ip" {
  description = "Private IP of the Ansible Controller"
  value       = aws_instance.ansible_controller.private_ip
}

output "ansible_controller_public_dns" {
  description = "Public DNS of the Ansible Controller"
  value       = aws_eip.ansible_controller.public_dns
}

# Jenkins Master
output "jenkins_master_id" {
  description = "ID of the Jenkins Master instance"
  value       = aws_instance.jenkins_master.id
}

output "jenkins_master_public_ip" {
  description = "Public IP of the Jenkins Master"
  value       = aws_eip.jenkins_master.public_ip
}

output "jenkins_master_private_ip" {
  description = "Private IP of the Jenkins Master"
  value       = aws_instance.jenkins_master.private_ip
}

output "jenkins_master_public_dns" {
  description = "Public DNS of the Jenkins Master"
  value       = aws_eip.jenkins_master.public_dns
}

# Jenkins Agents
output "jenkins_agents_ids" {
  description = "IDs of the Jenkins Agent instances"
  value       = aws_instance.jenkins_agents[*].id
}

output "jenkins_agents_private_ips" {
  description = "Private IPs of the Jenkins Agent instances"
  value       = aws_instance.jenkins_agents[*].private_ip
}

output "jenkins_agents_private_dns" {
  description = "Private DNS names of the Jenkins Agent instances"
  value       = aws_instance.jenkins_agents[*].private_dns
}

# SSH Key Information
output "ansible_ssh_key_name" {
  description = "Name of the SSH key pair for Ansible"
  value       = aws_key_pair.ansible_ssh.key_name
}

output "ansible_private_key_ssm_parameter" {
  description = "SSM Parameter name containing the Ansible private key"
  value       = aws_ssm_parameter.ansible_private_key.name
}

# Connection Information
output "ssh_connections" {
  description = "SSH connection commands for instances"
  value = {
    ansible_controller = "ssh -i ~/.ssh/${aws_key_pair.ansible_ssh.key_name}.pem ubuntu@${aws_eip.ansible_controller.public_ip}"
    jenkins_master     = "ssh -i ~/.ssh/${aws_key_pair.ansible_ssh.key_name}.pem ubuntu@${aws_eip.jenkins_master.public_ip}"
  }
}

# Instance Summary
output "instances_summary" {
  description = "Summary of all created instances"
  value = {
    ansible_controller = {
      id         = aws_instance.ansible_controller.id
      public_ip  = aws_eip.ansible_controller.public_ip
      private_ip = aws_instance.ansible_controller.private_ip
      type       = aws_instance.ansible_controller.instance_type
    }
    jenkins_master = {
      id         = aws_instance.jenkins_master.id
      public_ip  = aws_eip.jenkins_master.public_ip
      private_ip = aws_instance.jenkins_master.private_ip
      type       = aws_instance.jenkins_master.instance_type
    }
    jenkins_agents = [
      for i, instance in aws_instance.jenkins_agents : {
        id         = instance.id
        private_ip = instance.private_ip
        type       = instance.instance_type
        name       = "${var.jenkins_agents_config.name_prefix}-${i + 1}"
      }
    ]
  }
}