provider "aws" {
  shared_config_files      = ["/Users/vfedoriv/.aws/config"]
  shared_credentials_files = ["/Users/vfedoriv/.aws/credentials"]
  profile                  = "capgemini"
  region                   = "us-west-2"
}

resource "aws_instance" "vf2-ec2-public-instance" {
  ami                         = "ami-009c5f630e96948cb"
  instance_type               = "t2.micro"
  key_name                    = "vf_cap1"
  vpc_security_group_ids      = [aws_security_group.vf2-public-security-group.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vf2-public-subnet-1.id
  tags                        = {
    Name = "vf2-ec2-public-instance"
  }
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo “HTTP Server from public subnet” > index.html
EOF
}

resource "aws_instance" "vf2-ec2-private-instance" {
  ami                         = "ami-009c5f630e96948cb"
  instance_type               = "t2.micro"
  key_name                    = "vf_cap1"
  vpc_security_group_ids      = [aws_security_group.vf2-private-security-group.id]
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.vf2-private-subnet-1.id
  tags                        = {
    Name = "vf2-ec2-private-instance"
  }
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo “HTTP Server from private subnet” > index.html
EOF
}

resource "aws_instance" "vf2-ec2-nat-instance" {
  ami                         = "ami-0ef52523812cba99c"
  instance_type               = "t2.micro"
  key_name                    = "vf_cap1"
  vpc_security_group_ids      = [aws_security_group.vf2-public-security-group.id]
  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id                   = aws_subnet.vf2-public-subnet-1.id
  tags                        = {
    Name = "vf2-ec2-nat-instance"
  }
}


resource "aws_security_group" "vf2-public-security-group" {
  name        = "vf2-public-security-group"
  description = "vf2-public-security-group"
  vpc_id      = aws_vpc.vf2-vpc-1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "vf2-private-security-group" {
  name        = "vf2-private-security-group"
  description = "vf2-private-security-group"
  vpc_id      = aws_vpc.vf2-vpc-1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_vpc" "vf2-vpc-1" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    "Name" = "vf2-vpc-1"
  }
}

resource "aws_subnet" "vf2-public-subnet-1" {
  vpc_id                  = aws_vpc.vf2-vpc-1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags                    = {
    "Name" = "vf2-public-subnet-1"
  }
}

resource "aws_subnet" "vf2-private-subnet-1" {
  vpc_id                  = aws_vpc.vf2-vpc-1.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
  tags                    = {
    "Name" = "vf2-private-subnet-1"
  }
}

resource "aws_internet_gateway" "vf2-gateway" {
  vpc_id = aws_vpc.vf2-vpc-1.id
  tags   = {
    "Name" = "vf2-gateway"
  }
}

resource "aws_route_table" "vf2-public-route-table" {
  vpc_id = aws_vpc.vf2-vpc-1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vf2-gateway.id
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = aws_subnet.vf2-public-subnet-1.id
  route_table_id = aws_route_table.vf2-public-route-table.id
}

resource "aws_route_table" "vf2-nat-route-table" {
  vpc_id = aws_vpc.vf2-vpc-1.id
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.vf2-ec2-nat-instance.id
  }
}

resource "aws_route_table_association" "private_route_assoc" {
  subnet_id      = aws_subnet.vf2-private-subnet-1.id
  route_table_id = aws_route_table.vf2-nat-route-table.id
}

resource "aws_alb_target_group" "vf2-target-group" {
  name     = "vf2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vf2-vpc-1.id

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "5"
    interval            = "20"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/index.html"
  }
}

resource "aws_alb" "vf2-load-balancer" {
  name               = "vf2-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    aws_security_group.vf2-public-security-group.id, aws_security_group.vf2-private-security-group.id
  ]
  subnets = [aws_subnet.vf2-public-subnet-1.id, aws_subnet.vf2-private-subnet-1.id]
}


resource "aws_alb_target_group_attachment" "tg_att_1" {
  target_group_arn = aws_alb_target_group.vf2-target-group.arn
  target_id        = aws_instance.vf2-ec2-private-instance.id
}

resource "aws_alb_target_group_attachment" "tg_att_2" {
  target_group_arn = aws_alb_target_group.vf2-target-group.arn
  target_id        = aws_instance.vf2-ec2-public-instance.id
}

resource "aws_alb_listener" "vf2-alb-listener" {
  default_action {
    target_group_arn = aws_alb_target_group.vf2-target-group.arn
    type             = "forward"
  }
  load_balancer_arn = aws_alb.vf2-load-balancer.arn
  port              = 80
  protocol          = "HTTP"
}



