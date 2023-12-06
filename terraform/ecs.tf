# Data source to pull in the latest image
data "aws_ecr_repository" "zivvy_image" {
  name = aws_ecr_repository.zivvy.name
}

# Local variable to insert a dummy nginx image if there are no images in ECR 
locals {
  image_name = length(data.aws_ecr_repository.zivvy_image.most_recent_image_tags) != 0 ? "${data.aws_ecr_repository.zivvy_image.repository_url}:${data.aws_ecr_repository.zivvy_image.most_recent_image_tags[0]}" : "nginx:latest"
}


# Task definition with a basic nginx image in place which will be replaced in a subsequent ECS deploy runs 
# or once image is available during a Terraform run
resource "aws_ecs_task_definition" "zivvy_app" {
  family                   = "zivvy-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.zivvy_task_role.arn
  container_definitions    = <<DEFINITION
[
  {
    "image": ${jsonencode(local.image_name)},
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

#Create ECS cluster 

resource "aws_ecs_cluster" "main" {
  name = "zivvy-cluster"
}

# Create ECS service to run with task definition 
resource "aws_ecs_service" "zivvy_app_service" {
  name                 = "zivvy-service"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.zivvy_app.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true

  # Config to keep old container running before newly deployed container is up
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

# Auto scaling policies depending on CPU and Memory usage 

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
