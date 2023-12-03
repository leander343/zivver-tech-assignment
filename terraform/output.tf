
#Output load balancer url to access container
output "load_balancer_url" {
  value = aws_lb.ecs.dns_name
}