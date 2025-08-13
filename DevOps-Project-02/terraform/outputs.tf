output "bastion_vpc_id" {
  description = "ID of the bastion VPC"
  value       = module.bastion_vpc.vpc_id
}

output "app_vpc_id" {
  description = "ID of the application VPC"
  value       = module.app_vpc.vpc_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.elastic_ip
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.nlb.load_balancer_dns_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_bucket.bucket_name
}

output "uploaded_files_count" {
  description = "Number of web application files uploaded to S3"
  value       = module.s3_upload.upload_count
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.transit_gateway.transit_gateway_id
}

output "ssh_connection_commands" {
  description = "SSH connection commands for accessing instances"
  value = {
    bastion = "ssh -i /home/imranshaikh/MY_keys/${var.key_pair_name}.pem ubuntu@${module.bastion.elastic_ip}"
    private_via_bastion = "ssh -i ~/.ssh/bastion_key ubuntu@PRIVATE_IP"
    private_via_jump = "ssh -i /home/imranshaikh/MY_keys/${var.key_pair_name}.pem -J ubuntu@${module.bastion.elastic_ip} ubuntu@PRIVATE_IP"
  }
}