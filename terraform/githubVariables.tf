
#Setup Github actions variables specifically required for deployments to ECS
data "github_repository" "repo" {
  full_name = "leander343/zivver-tech-assignment"
}


resource "github_actions_variable" "cluster_name" {
  repository    = data.github_repository.repo.name
  variable_name = "CLUSTER_NAME"
  value         = aws_ecs_cluster.main.name
}

resource "github_actions_variable" "repository_name" {
  repository    = data.github_repository.repo.name
  variable_name = "REPOSITORY_NAME"
  value         = aws_ecr_repository.zivvy.name
}

resource "github_actions_variable" "service_name" {
  repository    = data.github_repository.repo.name
  variable_name = "SERVICE_NAME"
  value         = aws_ecs_service.zivvy_app_service.name
}
