# ECS executionpolicy with added permission to create logs 
resource "aws_iam_policy" "ecs_policy" {
  name = "zivvy-ecs-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}


# Create IAM role and attach policy, to be used as execution role for ECS

resource "aws_iam_role" "zivvy_task_role" {
  name = "zivvy-webapp-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


# Create association of policy with role
resource "aws_iam_role_policy_attachment" "zivy-webapp-role-policy-attachment" {
  role       = aws_iam_role.zivvy_task_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}


