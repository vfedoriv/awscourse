resource "aws_launch_template" "vf-launch-template-1" {
  name_prefix            = "vf-ec2-public-"
  image_id               = "ami-009c5f630e96948cb"
  instance_type          = "t2.micro"
  key_name               = "vf_cap1"
  vpc_security_group_ids = [var.aws_public_sec_group_id]
  user_data              = base64encode(templatefile("${path.module}/public_user_data.sh", {
    key_id = var.aws_access_key_id, key_secret = var.aws_secret_access_key
  }))
}

resource "aws_autoscaling_group" "vf-asg-1" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [var.aws_public_subnet_1_id, var.aws_public_subnet_2_id]

  launch_template {
    id      = aws_launch_template.vf-launch-template-1.id
    version = "$Latest"
  }
}

resource "aws_instance" "vf2-ec2-private-instance" {
  ami                         = "ami-009c5f630e96948cb"
  instance_type               = "t2.micro"
  key_name                    = "vf_cap1"
  vpc_security_group_ids      = [var.aws_private_sec_group_id]
  associate_public_ip_address = false
  subnet_id                   = var.aws_private_subnet_1_id
  iam_instance_profile        = aws_iam_instance_profile.vf_ec2_profile.id
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }
  tags = {
    Name = "vf2-ec2-private-instance"
  }
  user_data_replace_on_change = true
  user_data_base64 = base64encode(templatefile("${path.module}/private_user_data.sh", {
    key_id = var.aws_access_key_id, key_secret = var.aws_secret_access_key, rds_address = var.rds_address
  }))
}

resource "aws_instance" "vf2-ec2-nat-instance" {
  ami                         = "ami-0ef52523812cba99c"
  instance_type               = "t2.micro"
  key_name                    = "vf_cap1"
  vpc_security_group_ids      = [var.aws_public_sec_group_id]
  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id                   = var.aws_public_subnet_1_id
  tags                        = {
    Name = "vf2-ec2-nat-instance"
  }
}

resource "aws_route_table" "vf2-nat-route-table" {
  vpc_id = var.aws_vpc_1_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.vf2-ec2-nat-instance.primary_network_interface_id
  }
}

resource "aws_route_table_association" "private_route_assoc" {
  subnet_id      = var.aws_private_subnet_1_id
  route_table_id = aws_route_table.vf2-nat-route-table.id
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
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ])
  role       = aws_iam_role.vf_ec2_role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "vf_ec2_profile" {
  name = "vf_ec2_profile_name"
  role = aws_iam_role.vf_ec2_role.name
}

output "aws_asg_id" {
  value = aws_autoscaling_group.vf-asg-1.id
}

output "aws_ec2_private_instance_1_id" {
  value = aws_instance.vf2-ec2-private-instance.id
}

output "aws_ec2_nat_instance_1_id" {
  value = aws_instance.vf2-ec2-nat-instance.id
}