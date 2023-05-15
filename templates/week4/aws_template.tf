provider "aws" {
  shared_config_files      = ["/Users/vfedoriv/.aws/config"]
  shared_credentials_files = ["/Users/vfedoriv/.aws/credentials"]
  profile                  = "capgemini"
  region                   = "us-west-2"
}

resource "aws_instance" "vf_ec2_instance" {
  ami                    = "ami-009c5f630e96948cb"
  instance_type          = "t2.micro"
  key_name               = "vf_cap1"
  vpc_security_group_ids = [aws_security_group.vf_ec2_group.id]
  iam_instance_profile   = aws_iam_instance_profile.vf_ec2_profile.id
  associate_public_ip_address = true
  user_data              = <<EOF
#!/bin/bash
aws s3 cp s3://vf-s3-bucket-1/scripts/rds-script.sql /home/ec2-user/rds-script.sql
aws s3 cp s3://vf-s3-bucket-1/scripts/dynamodb-script.sh /home/ec2-user/dynamodb-script.sh
chmod 777 /home/ec2-user/dynamodb-script.sh
chmod 777 /home/ec2-user/rds-script.sql
sudo dnf install postgresql15 -y
EOF
}

resource "aws_iam_role" "vf_ec2_role" {
  name               = "vf_ec2_role_name"
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
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ])
  role       = aws_iam_role.vf_ec2_role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "vf_ec2_profile" {
  name = "vf_ec2_profile_name"
  role = aws_iam_role.vf_ec2_role.name
}

resource "aws_security_group" "vf_ec2_group" {
  name        = "my_ec2_sec_group"
  description = "My ec2 sec group"
  # vpc_id      = aws_vpc.vf-vpc-1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "vf_postgres_group" {
  name        = "my_postgres_sec_group"
  description = "My postgres sec group"
  # vpc_id      = aws_vpc.vf-vpc-1.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ec2-to-postgres-egress" {
  type = "egress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  security_group_id = "${aws_security_group.vf_ec2_group.id}"
  source_security_group_id = "${aws_security_group.vf_postgres_group.id}"
}

resource "aws_security_group_rule" "postgres-from-ec2-ingress" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  security_group_id = "${aws_security_group.vf_postgres_group.id}"
  source_security_group_id = "${aws_security_group.vf_ec2_group.id}"
}

resource "aws_db_instance" "vf-postgres-db-1" {
  identifier          = "vf-postgres-db-1"
  instance_class      = "db.t3.micro"
  allocated_storage   = 5
  engine              = "postgres"
  engine_version      = "14.1"
  username            = "postgres"
  password            = "postgres"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.vf_postgres_group.id]
}

output "postgres_endpoint" {
  value = aws_db_instance.vf-postgres-db-1.endpoint
}

output "postgres_port" {
  value = aws_db_instance.vf-postgres-db-1.port
}

resource "aws_dynamodb_table" "vf-dynamodb-table-1" {
  name           = "Music"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 2
  hash_key       = "Artist"
  range_key      = "SongTitle"

  attribute {
    name = "Artist"
    type = "S"
  }

  attribute {
    name = "SongTitle"
    type = "S"
  }

  tags = {
    Name = "vf-dynamodb-table-1"
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
