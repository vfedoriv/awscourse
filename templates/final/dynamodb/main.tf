resource "aws_dynamodb_table" "vf-dynamodb-table-1" {
  name           = "edu-lohika-training-aws-dynamodb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 2
  hash_key       = "UserName"

  attribute {
    name = "UserName"
    type = "S"
  }

  tags = {
    Name = "edu-lohika-training-aws-dynamodb"
  }
}

resource "aws_iam_role" "vf-dynamodb-role" {
  name               = "vf-dynamodb-role-name"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.vf-policy-dynamodb.arn]
}

resource "aws_iam_policy" "vf-policy-dynamodb" {
  name        = "vf-policy-dynamodb-name"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Id1",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "iam:GetRole",
          "iam:ListRoles"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}