resource "aws_alb_target_group" "vf2-target-group" {
  name     = "vf2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.aws_vpc_1_id

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "5"
    interval            = "20"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/actuator/health"
  }
}

resource "aws_alb" "vf2-load-balancer" {
  name               = "vf2-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    var.aws_public_sec_group_id
  ]
  subnets = [
    var.aws_public_subnet_1_id, var.aws_public_subnet_2_id
  ]
}

resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = var.aws_asg_id
  lb_target_group_arn    = aws_alb_target_group.vf2-target-group.arn
}

resource "aws_alb_listener" "vf2-alb-listener" {
  default_action {
    target_group_arn = aws_alb_target_group.vf2-target-group.arn
    type             = "forward"
  }
  load_balancer_arn = aws_alb.vf2-load-balancer.arn
  port              = 80
  protocol          = "HTTP"
}