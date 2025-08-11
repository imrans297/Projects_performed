resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  tags = var.tags
}