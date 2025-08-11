output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "app_sg_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "nlb_sg_id" {
  description = "ID of the NLB security group"
  value       = aws_security_group.nlb.id
}