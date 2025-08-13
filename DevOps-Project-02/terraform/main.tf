# Bastion VPC
module "bastion_vpc" {
  source = "./modules/vpc"

  vpc_cidr             = local.bastion_vpc.cidr_block
  vpc_name             = "${local.name_prefix}-bastion-vpc"
  availability_zones   = local.azs
  public_subnet_cidrs  = local.bastion_vpc.public_subnet_cidrs
  private_subnet_cidrs = local.bastion_vpc.private_subnet_cidrs
  enable_nat_gateway   = true
  enable_flow_logs     = var.enable_flow_logs

  tags = local.common_tags
}

# Application VPC
module "app_vpc" {
  source = "./modules/vpc"

  vpc_cidr             = local.app_vpc.cidr_block
  vpc_name             = "${local.name_prefix}-app-vpc"
  availability_zones   = local.azs
  public_subnet_cidrs  = local.app_vpc.public_subnet_cidrs
  private_subnet_cidrs = local.app_vpc.private_subnet_cidrs
  enable_nat_gateway   = true
  enable_flow_logs     = var.enable_flow_logs

  tags = local.common_tags
}

# Transit Gateway
module "transit_gateway" {
  source = "./modules/transit-gateway"

  tgw_name = "${var.project_name}-tgw"
  vpc_attachments = [
    {
      vpc_id     = module.bastion_vpc.vpc_id
      subnet_ids = module.bastion_vpc.private_subnet_ids
    },
    {
      vpc_id     = module.app_vpc.vpc_id
      subnet_ids = module.app_vpc.private_subnet_ids
    }
  ]

  tags = var.common_tags
}

# S3 Bucket for application configuration
module "s3_bucket" {
  source = "./modules/s3"

  bucket_name = "${var.project_name}-app-config-${random_id.bucket_suffix.hex}"

  tags = var.common_tags
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"

  project_name     = var.project_name
  bastion_vpc_id   = module.bastion_vpc.vpc_id
  app_vpc_id       = module.app_vpc.vpc_id
  bastion_vpc_cidr = local.bastion_vpc.cidr_block
  app_vpc_cidr     = local.app_vpc.cidr_block

  tags = local.common_tags
}

# IAM Roles
module "iam" {
  source = "./modules/iam"

  project_name  = var.project_name
  s3_bucket_arn = module.s3_bucket.bucket_arn

  tags = local.common_tags
}

# Bastion Host
module "bastion" {
  source = "./modules/ec2"

  instance_name        = "${var.project_name}-bastion"
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  subnet_id            = module.bastion_vpc.public_subnet_ids[0]
  security_group_ids   = [module.security_groups.bastion_sg_id]
  key_name             = var.key_pair_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
  associate_public_ip  = true

  tags = var.common_tags
}

# Auto Scaling Group
module "asg" {
  source = "./modules/autoscaling"

  name_prefix          = local.name_prefix
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = "t2.micro"
  key_name             = var.key_pair_name
  security_group_ids   = [module.security_groups.app_sg_id]
  subnet_ids           = module.app_vpc.private_subnet_ids
  vpc_id               = module.app_vpc.vpc_id
  iam_instance_profile = module.iam.ec2_instance_profile_name
  s3_bucket_name       = module.s3_bucket.bucket_name
  ssh_public_key       = tls_private_key.bastion_key.public_key_openssh

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  tags = var.common_tags
}

# Network Load Balancer
module "nlb" {
  source = "./modules/load-balancer"

  name               = "${var.project_name}-nlb"
  load_balancer_type = "network"
  subnet_ids         = module.app_vpc.public_subnet_ids
  target_group_arn   = module.asg.target_group_arn

  tags = var.common_tags
}

# Random ID for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Upload web application files to S3
module "s3_upload" {
  source = "./modules/s3-upload"

  bucket_name = module.s3_bucket.bucket_name
  tags        = local.common_tags

  depends_on = [module.s3_bucket]
}