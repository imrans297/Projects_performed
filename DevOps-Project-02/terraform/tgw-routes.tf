# Transit Gateway Routes - Created after VPCs and TGW are established

# Routes for Bastion VPC to App VPC
resource "aws_route" "bastion_private_to_app" {
  count = length(module.bastion_vpc.private_route_table_ids)

  route_table_id         = module.bastion_vpc.private_route_table_ids[count.index]
  destination_cidr_block = local.app_vpc.cidr_block
  transit_gateway_id     = module.transit_gateway.transit_gateway_id

  depends_on = [
    module.bastion_vpc,
    module.transit_gateway
  ]
}

resource "aws_route" "bastion_public_to_app" {
  route_table_id         = module.bastion_vpc.public_route_table_id
  destination_cidr_block = local.app_vpc.cidr_block
  transit_gateway_id     = module.transit_gateway.transit_gateway_id

  depends_on = [
    module.bastion_vpc,
    module.transit_gateway
  ]
}

# Routes for App VPC to Bastion VPC
resource "aws_route" "app_private_to_bastion" {
  count = length(module.app_vpc.private_route_table_ids)

  route_table_id         = module.app_vpc.private_route_table_ids[count.index]
  destination_cidr_block = local.bastion_vpc.cidr_block
  transit_gateway_id     = module.transit_gateway.transit_gateway_id

  depends_on = [
    module.app_vpc,
    module.transit_gateway
  ]
}

resource "aws_route" "app_public_to_bastion" {
  route_table_id         = module.app_vpc.public_route_table_id
  destination_cidr_block = local.bastion_vpc.cidr_block
  transit_gateway_id     = module.transit_gateway.transit_gateway_id

  depends_on = [
    module.app_vpc,
    module.transit_gateway
  ]
}