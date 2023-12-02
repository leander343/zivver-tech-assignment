output "load_balancer_ip" {
  value = aws_lb.ecs.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.zivvy_app_service.name
}