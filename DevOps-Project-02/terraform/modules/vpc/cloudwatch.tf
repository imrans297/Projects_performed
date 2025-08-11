# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.vpc_name}"
  retention_in_days = 7
  tags              = var.tags
  
  lifecycle {
    ignore_changes = [name]
  }
}

locals {
  flow_logs_log_group_arn = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}