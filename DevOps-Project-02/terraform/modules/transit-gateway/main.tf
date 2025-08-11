resource "aws_ec2_transit_gateway" "main" {
  description                     = "Transit Gateway for ${var.tgw_name}"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(var.tags, {
    Name = var.tgw_name
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachments" {
  count = length(var.vpc_attachments)

  subnet_ids         = var.vpc_attachments[count.index].subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.vpc_attachments[count.index].vpc_id

  tags = merge(var.tags, {
    Name = "${var.tgw_name}-attachment-${count.index + 1}"
  })
}