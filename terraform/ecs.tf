resource "aws_ecs_task_definition" "zivvy_app" {
  family                   = "zivvy-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = <<DEFINITION
[
  {
    "image": "nginx:latest",
    "cpu": 1024,
    "memory": 2048,
    "name": "zivvy-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
          "options": {
              "awslogs-create-group": "true",
              "awslogs-group": "zivvy-logs",
              "awslogs-region": "ap-south-1",
              "awslogs-stream-prefix": "app-logs"
             }
         }
  }
]
DEFINITION

}


resource "aws_ecs_cluster" "main" {
  name = "zivvy-cluster"
}

resource "aws_ecs_service" "zivvy_app_service" {
  name                 = "zivvy-service"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.zivvy_app.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.ecs.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.zivvy.id
    container_name   = "zivvy-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.zivvy]
}


resource "aws_appautoscaling_target" "target_scaling" {
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.zivvy_app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "memory-scaling" {
  name               = "dev-to-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.target_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.target_scaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "cpu-scaling" {
  name               = "dev-to-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.target_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.target_scaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}
