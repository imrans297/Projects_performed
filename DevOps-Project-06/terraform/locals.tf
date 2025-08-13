# Local values for CI/CD Pipeline Infrastructure

locals {
  # Common naming convention
  name_prefix = "${var.environment}-${var.project_name}"
  
  # Availability zones (limit to 2 for cost optimization)
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Common tags merged with environment-specific tags
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Imran"
    Owner       = var.owner
  })
  
  # Security group rules
  common_ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.allowed_ssh_cidr]
      description = "SSH access"
    }
    
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    }
    
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  }
  
  # Jenkins specific ports
  jenkins_ports = {
    web_ui = {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Jenkins Web UI"
    }
    
    agent_communication = {
      from_port   = 50000
      to_port     = 50000
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "Jenkins Agent Communication"
    }
  }
  
  # Application specific ports
  app_ports = {
    sonarqube = {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "SonarQube"
    }
    
    artifactory = {
      from_port   = 8081
      to_port     = 8082
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "JFrog Artifactory"
    }
    
    prometheus = {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "Prometheus"
    }
    
    grafana = {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "Grafana"
    }
  }
}