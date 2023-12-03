
# Load balancer to forward traffic to ECS
resource "aws_lb" "ecs" {
  name            = "zivvy-ecs-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "zivvy" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs.id
  target_type = "ip"
}

resource "aws_lb_listener" "zivvy" {
  load_balancer_arn = aws_lb.ecs.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.zivvy.id
    type             = "forward"
  }
}