# ECR repository to host images. 

resource "aws_ecr_repository" "zivvy" {
  name                 = "zivvy-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

# Policy to only store last 5 images, value can be increased if necessary. 
resource "aws_ecr_lifecycle_policy" "lifecyle" {
  repository = aws_ecr_repository.zivvy.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 5 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}