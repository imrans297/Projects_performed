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
    CostCenter  = var.cost_center
    CreatedBy   = data.aws_caller_identity.current.user_id
    Region      = data.aws_region.current.name
  })

  # Network configuration
  bastion_vpc = {
    cidr_block           = var.bastion_vpc_cidr
    public_subnet_cidrs  = var.bastion_public_subnet_cidrs
    private_subnet_cidrs = var.bastion_private_subnet_cidrs
  }

  app_vpc = {
    cidr_block           = var.app_vpc_cidr
    public_subnet_cidrs  = var.app_public_subnet_cidrs
    private_subnet_cidrs = var.app_private_subnet_cidrs
  }

  # Auto Scaling configuration
  asg_config = {
    min_size         = var.asg_min_size
    max_size         = var.asg_max_size
    desired_capacity = var.asg_desired_capacity
    instance_type    = var.app_instance_type
  }
}