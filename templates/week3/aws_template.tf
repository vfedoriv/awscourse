provider "aws" {
  shared_config_files = ["/Users/vfedoriv/.aws/config"]
  shared_credentials_files = ["/Users/vfedoriv/.aws/credentials"]
  profile = "capgemini"
  region = "us-west-2"
}

resource "aws_instance" "vf_ec2_instance" {
  ami = "ami-009c5f630e96948cb"
  instance_type = "t2.micro"
  key_name = "vf_cap1"
  vpc_security_group_ids = [aws_security_group.vf_sec_group.id]
  iam_instance_profile = aws_iam_instance_profile.vf_s3_profile.id
  user_data = <<EOF
#!/bin/bash
aws s3 cp s3://vf-s3-bucket-1/dir1/test1.txt /home/ec2-user/test5.txt
EOF
}

resource "aws_security_group" "vf_sec_group" {
  name        = "my_sec_group"
  description = "My sec group descr"
  #vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "vf_s3_role" {
  name                = "vf_s3_role_name"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.vf_policy_s3.arn]
}

resource "aws_iam_policy" "vf_policy_s3" {
  name        = "vf_policy_s3_name"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Id1",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::*/*",
          "arn:aws:s3:::my-bucket-name"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vf_policy_att" {
  role       = aws_iam_role.vf_s3_role.name
  policy_arn = aws_iam_policy.vf_policy_s3.arn
}

resource "aws_iam_instance_profile" "vf_s3_profile" {
  name = "vf_s3_profile_name"
  role = aws_iam_role.vf_s3_role.name
}

/*
resource "aws_s3_bucket" "vf_s3_bucket" {
  bucket = "vf-s3-bucket-1"
}

resource "aws_s3_bucket_public_access_block" "vf_bucket_access" {
  bucket = aws_s3_bucket.vf_s3_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}
*/