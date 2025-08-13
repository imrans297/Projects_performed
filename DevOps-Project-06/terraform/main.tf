# Main Terraform configuration for CI/CD Pipeline Infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  vpc_name             = "${local.name_prefix}-vpc"
  availability_zones   = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  enable_flow_logs     = var.enable_flow_logs
  
  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  allowed_ssh_cidr = var.allowed_ssh_cidr
  name_prefix      = local.name_prefix
  
  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  name_prefix = local.name_prefix
  
  tags = local.common_tags
}

# S3 Module for artifacts and state
module "s3" {
  source = "./modules/s3"
  
  name_prefix = local.name_prefix
  
  tags = local.common_tags
}

# EC2 Instances Module
module "ec2_instances" {
  source = "./modules/ec2"
  
  # Ansible Controller
  ansible_controller_config = {
    instance_type = var.ansible_controller_instance_type
    subnet_id     = module.vpc.public_subnet_ids[0]
    security_group_ids = [
      module.security_groups.ansible_controller_sg_id,
      module.security_groups.common_sg_id
    ]
    iam_instance_profile = module.iam.ansible_controller_instance_profile_name
    key_name            = var.key_pair_name
    name               = "${local.name_prefix}-ansible-controller"
  }
  
  # Jenkins Master
  jenkins_master_config = {
    instance_type = var.jenkins_master_instance_type
    subnet_id     = length(module.vpc.public_subnet_ids) > 1 ? module.vpc.public_subnet_ids[1] : module.vpc.public_subnet_ids[0]
    security_group_ids = [
      module.security_groups.jenkins_master_sg_id,
      module.security_groups.common_sg_id
    ]
    iam_instance_profile = module.iam.jenkins_master_instance_profile_name
    key_name            = var.key_pair_name
    name               = "${local.name_prefix}-jenkins-master"
  }
  
  # Jenkins Agents
  jenkins_agents_config = {
    count         = var.jenkins_agents_count
    instance_type = var.jenkins_agent_instance_type
    subnet_ids    = module.vpc.private_subnet_ids
    security_group_ids = [
      module.security_groups.jenkins_agent_sg_id,
      module.security_groups.common_sg_id
    ]
    iam_instance_profile = module.iam.jenkins_agent_instance_profile_name
    key_name            = var.key_pair_name
    name_prefix         = "${local.name_prefix}-jenkins-agent"
  }
  
  ami_id = data.aws_ami.ubuntu.id
  tags   = local.common_tags
}

# EKS Module (commented out until EKS module is created)
# module "eks" {
#   source = "./modules/eks"
#   
#   cluster_name    = "${local.name_prefix}-eks-cluster"
#   cluster_version = var.eks_cluster_version
#   
#   vpc_id                    = module.vpc.vpc_id
#   subnet_ids               = module.vpc.private_subnet_ids
#   control_plane_subnet_ids = module.vpc.public_subnet_ids
#   
#   # Node groups configuration
#   node_groups = {
#     main = {
#       instance_types = var.eks_node_instance_types
#       scaling_config = {
#         desired_size = var.eks_desired_nodes
#         max_size     = var.eks_max_nodes
#         min_size     = var.eks_min_nodes
#       }
#       disk_size = var.eks_node_disk_size
#     }
#   }
#   
#   # Additional security group for EKS
#   additional_security_group_ids = [module.security_groups.eks_additional_sg_id]
#   
#   tags = local.common_tags
# }

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  name_prefix                      = local.name_prefix
  aws_region                       = var.aws_region
  alert_email_addresses            = var.alert_email_addresses
  log_retention_days               = var.log_retention_days
  jenkins_master_instance_id       = module.ec2_instances.jenkins_master_id
  jenkins_agent_instance_ids       = module.ec2_instances.jenkins_agents_ids
  ansible_controller_instance_id   = module.ec2_instances.ansible_controller_id
  
  tags = local.common_tags
  
  depends_on = [module.ec2_instances]
}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# AMI Data Source
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}