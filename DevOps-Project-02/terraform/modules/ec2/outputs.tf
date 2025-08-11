output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.associate_public_ip ? aws_eip.main[0].public_ip : null
}