output "load_balancer_ip" {
  value = aws_lb.ecs.dns_name
}