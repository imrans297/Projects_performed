# Security Groups Module for CI/CD Pipeline Infrastructure

# Common Security Group (for all instances)
resource "aws_security_group" "common" {
  name_prefix = "${var.name_prefix}-common-sg"
  vpc_id      = var.vpc_id
  description = "Common security group for all instances"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Internal VPC communication
  ingress {
    description = "Internal VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-common-sg"
  })
}

# Ansible Controller Security Group
resource "aws_security_group" "ansible_controller" {
  name_prefix = "${var.name_prefix}-ansible-controller-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Ansible Controller"

  # HTTP access for web interfaces
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ansible specific ports (if needed)
  ingress {
    description = "Ansible Communication"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ansible-controller-sg"
  })
}

# Jenkins Master Security Group
resource "aws_security_group" "jenkins_master" {
  name_prefix = "${var.name_prefix}-jenkins-master-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Jenkins Master"

  # Jenkins Web UI
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins Agent Communication
  ingress {
    description = "Jenkins Agent Communication"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTP/HTTPS for webhooks and integrations
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jenkins-master-sg"
  })
}

# Jenkins Agent Security Group
resource "aws_security_group" "jenkins_agent" {
  name_prefix = "${var.name_prefix}-jenkins-agent-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Jenkins Agents"

  # Communication with Jenkins Master
  ingress {
    description     = "Jenkins Master Communication"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  # Docker daemon (if running Docker)
  ingress {
    description = "Docker Daemon"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SonarQube Scanner communication
  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jenkins-agent-sg"
  })
}

# EKS Additional Security Group
resource "aws_security_group" "eks_additional" {
  name_prefix = "${var.name_prefix}-eks-additional-sg"
  vpc_id      = var.vpc_id
  description = "Additional security group for EKS cluster"

  # Allow communication between nodes
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow communication from Jenkins agents for deployments
  ingress {
    description     = "Jenkins Agent to EKS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_agent.id]
  }

  # Kubernetes API server
  ingress {
    description = "Kubernetes API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort services range
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-additional-sg"
  })
}

# Application Load Balancer Security Group (for future use)
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

# Database Security Group (for future use)
resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-database-sg"
  vpc_id      = var.vpc_id
  description = "Security group for databases"

  # MySQL/Aurora
  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_agent.id, aws_security_group.jenkins_master.id]
  }

  # PostgreSQL
  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_agent.id, aws_security_group.jenkins_master.id]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-sg"
  })
}