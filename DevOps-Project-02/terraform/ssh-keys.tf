# Generate SSH key pair for bastion-to-private communication
resource "tls_private_key" "bastion_key" {
  algorithm = "ED25519"
}

# Save keys locally
resource "local_file" "private_key" {
  content         = tls_private_key.bastion_key.private_key_openssh
  filename        = "${path.root}/bastion_key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = tls_private_key.bastion_key.public_key_openssh
  filename = "${path.root}/bastion_key.pub"
}

# Setup SSH keys on bastion host
resource "null_resource" "setup_bastion_ssh" {
  depends_on = [module.bastion, local_file.private_key]

  provisioner "local-exec" {
    command = <<-EOT
      # Copy bastion private key
      scp -i "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" -o StrictHostKeyChecking=no \
        "${path.root}/bastion_key" ubuntu@${module.bastion.elastic_ip}:~/.ssh/bastion_key
      
      # Copy bastion public key
      scp -i "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" -o StrictHostKeyChecking=no \
        "${path.root}/bastion_key.pub" ubuntu@${module.bastion.elastic_ip}:~/.ssh/bastion_key.pub
      
      # Copy original key for jump host access
      scp -i "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" -o StrictHostKeyChecking=no \
        "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" ubuntu@${module.bastion.elastic_ip}:~/.ssh/
      
      # Set proper permissions
      ssh -i "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" -o StrictHostKeyChecking=no \
        ubuntu@${module.bastion.elastic_ip} \
        "chmod 600 ~/.ssh/bastion_key ~/.ssh/bastion_key.pub ~/.ssh/${var.key_pair_name}.pem && chown ubuntu:ubuntu ~/.ssh/*"
    EOT
  }
}

# Add SSH keys to existing private instances
resource "null_resource" "setup_private_ssh" {
  depends_on = [null_resource.setup_bastion_ssh, module.asg]

  triggers = {
    bastion_ip = module.bastion.elastic_ip
    asg_name = "${local.name_prefix}-asg"
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Get private instance IPs
      PRIVATE_IPS=$(aws ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=${local.name_prefix}-asg" \
                  "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' \
        --output text)
      
      # Add bastion public key to each private instance
      for IP in $PRIVATE_IPS; do
        echo "Adding SSH key to $IP..."
        ssh -i "/home/imranshaikh/MY_keys/${var.key_pair_name}.pem" -o StrictHostKeyChecking=no \
          -J ubuntu@${module.bastion.elastic_ip} ubuntu@$IP \
          "echo '$(cat ${path.root}/bastion_key.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" || true
      done
    EOT
  }
}