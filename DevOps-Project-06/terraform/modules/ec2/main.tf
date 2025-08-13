# Generate SSH key pair for Ansible communication
resource "tls_private_key" "ansible_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "ansible_ssh" {
  key_name   = "${var.ansible_controller_config.name}-ansible-key"
  public_key = tls_private_key.ansible_ssh.public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.ansible_controller_config.name}-ansible-key"
    Purpose = "Ansible SSH Communication"
  })
}

# Store private key in SSM for secure access
resource "aws_ssm_parameter" "ansible_private_key" {
  name  = "/${var.ansible_controller_config.name}/ssh/private-key"
  type  = "SecureString"
  value = tls_private_key.ansible_ssh.private_key_pem

  tags = merge(var.tags, {
    Name = "${var.ansible_controller_config.name}-private-key"
    Purpose = "Ansible SSH Private Key"
  })
}

# Ansible Controller Instance
resource "aws_instance" "ansible_controller" {
  ami                    = var.ami_id
  instance_type          = var.ansible_controller_config.instance_type
  key_name               = var.ansible_controller_config.key_name
  subnet_id              = var.ansible_controller_config.subnet_id
  vpc_security_group_ids = var.ansible_controller_config.security_group_ids
  iam_instance_profile   = var.ansible_controller_config.iam_instance_profile

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/ansible_controller_simple.sh", {
    hostname = var.ansible_controller_config.name
    ansible_private_key = tls_private_key.ansible_ssh.private_key_pem
    jenkins_master_ip = aws_eip.jenkins_master.public_ip
    jenkins_agent_ips = jsonencode(aws_instance.jenkins_agents[*].private_ip)
    jenkins_agent_count = var.jenkins_agents_config.count
  }))

  tags = merge(var.tags, {
    Name = var.ansible_controller_config.name
    Type = "Ansible Controller"
    Role = "Configuration Management"
  })

  depends_on = [aws_ssm_parameter.ansible_private_key]

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Ansible Controller
resource "aws_eip" "ansible_controller" {
  instance = aws_instance.ansible_controller.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.ansible_controller_config.name}-eip"
  })

  depends_on = [aws_instance.ansible_controller]
}

# Terraform provisioner to fix Ansible inventory and run playbooks
resource "null_resource" "ansible_setup" {
  depends_on = [
    aws_eip.ansible_controller,
    aws_eip.jenkins_master,
    aws_instance.jenkins_agents
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/imranshaikh/MY_keys/mydev_key.pem")
    host        = aws_eip.ansible_controller.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/user_data/inventory_updater.sh"
    destination = "/home/ubuntu/inventory_updater.sh"
  }

  provisioner "file" {
    source      = "${path.module}/user_data/cron_inventory_update.sh"
    destination = "/home/ubuntu/cron_inventory_update.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "# Wait for Ansible controller to be ready",
      "sleep 120",
      "# Make scripts executable",
      "chmod +x /home/ubuntu/inventory_updater.sh",
      "chmod +x /home/ubuntu/cron_inventory_update.sh",
      "# Create initial inventory with current instances",
      "sudo tee /etc/ansible/hosts << 'INVENTORY_EOF'",
      "[jenkins_master]",
      "jenkins-master ansible_host=${aws_eip.jenkins_master.public_ip} ansible_user=ubuntu",
      "[jenkins_agents]",
      join("\n", [for idx, ip in aws_instance.jenkins_agents[*].private_ip : "jenkins-agent-${idx + 1} ansible_host=${ip} ansible_user=ubuntu"]),
      "[all:vars]",
      "ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible_key.pem",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'",
      "INVENTORY_EOF",
      "# Set up cron job for automatic inventory updates",
      "/home/ubuntu/cron_inventory_update.sh",
      "# Test connectivity",
      "ansible all -m ping --timeout=30 || echo 'Testing connectivity...'",
      "# Wait for nodes to be ready",
      "sleep 60",
      "# Test again and update inventory dynamically",
      "/home/ubuntu/inventory_updater.sh full || echo 'Dynamic inventory update attempted'",
      "echo 'Ansible configuration completed with dynamic inventory management'"
    ]
  }

  # Trigger re-run when IPs change
  triggers = {
    jenkins_master_ip = aws_eip.jenkins_master.public_ip
    jenkins_agent_ips = join(",", aws_instance.jenkins_agents[*].private_ip)
  }
}

# Jenkins Master Instance (minimal setup - Jenkins installed via Ansible)
resource "aws_instance" "jenkins_master" {
  ami                    = var.ami_id
  instance_type          = var.jenkins_master_config.instance_type
  key_name               = aws_key_pair.ansible_ssh.key_name
  subnet_id              = var.jenkins_master_config.subnet_id
  vpc_security_group_ids = var.jenkins_master_config.security_group_ids
  iam_instance_profile   = var.jenkins_master_config.iam_instance_profile

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/jenkins_master_minimal.sh", {
    hostname = var.jenkins_master_config.name
    ansible_public_key = tls_private_key.ansible_ssh.public_key_openssh
  }))

  tags = merge(var.tags, {
    Name = var.jenkins_master_config.name
    Type = "Jenkins Master"
    Role = "CI/CD Controller"
  })

  depends_on = [aws_key_pair.ansible_ssh]

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Jenkins Master
resource "aws_eip" "jenkins_master" {
  instance = aws_instance.jenkins_master.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.jenkins_master_config.name}-eip"
  })

  depends_on = [aws_instance.jenkins_master]
}

# Jenkins Agent Instances (minimal setup - configured via Ansible)
resource "aws_instance" "jenkins_agents" {
  count = var.jenkins_agents_config.count

  ami                    = var.ami_id
  instance_type          = var.jenkins_agents_config.instance_type
  key_name               = aws_key_pair.ansible_ssh.key_name
  subnet_id              = var.jenkins_agents_config.subnet_ids[count.index % length(var.jenkins_agents_config.subnet_ids)]
  vpc_security_group_ids = var.jenkins_agents_config.security_group_ids
  iam_instance_profile   = var.jenkins_agents_config.iam_instance_profile

  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 40
    encrypted             = true
    delete_on_termination = true
  }

  # Additional EBS volume for Docker and build artifacts
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/jenkins_agent_minimal.sh", {
    hostname = "${var.jenkins_agents_config.name_prefix}-${count.index + 1}"
    agent_number = count.index + 1
    ansible_public_key = tls_private_key.ansible_ssh.public_key_openssh
  }))

  tags = merge(var.tags, {
    Name = "${var.jenkins_agents_config.name_prefix}-${count.index + 1}"
    Type = "Jenkins Agent"
    Role = "CI/CD Worker"
    AgentNumber = count.index + 1
  })

  depends_on = [aws_key_pair.ansible_ssh]

  lifecycle {
    create_before_destroy = true
  }
}



# Store Jenkins Master IP in SSM for agents to discover
resource "aws_ssm_parameter" "jenkins_master_ip" {
  name  = "/jenkins/master/private-ip"
  type  = "String"
  value = aws_instance.jenkins_master.private_ip

  tags = merge(var.tags, {
    Name = "jenkins-master-ip"
    Purpose = "Jenkins Master Discovery"
  })
}

# Store Jenkins Agent IPs in SSM for Ansible inventory
resource "aws_ssm_parameter" "jenkins_agents_ips" {
  name  = "/jenkins/agents/private-ips"
  type  = "StringList"
  value = join(",", aws_instance.jenkins_agents[*].private_ip)

  tags = merge(var.tags, {
    Name = "jenkins-agents-ips"
    Purpose = "Jenkins Agents Inventory"
  })
}

# Output for verification
resource "aws_ssm_parameter" "ansible_setup_status" {
  name  = "/ansible/setup/status"
  type  = "String"
  value = "Ansible configuration completed at ${timestamp()}"

  tags = merge(var.tags, {
    Name = "ansible-setup-status"
    Purpose = "Ansible Setup Verification"
  })

  depends_on = [null_resource.ansible_setup]
}