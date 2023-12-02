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


resource "aws_iam_role_policy_attachment" "zivy-webapp-role-policy-attachment" {
  role       = aws_iam_role.zivvy_task_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

