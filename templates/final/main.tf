provider "aws" {
  shared_config_files      = ["/Users/vfedoriv/.aws/config"]
  shared_credentials_files = ["/Users/vfedoriv/.aws/credentials"]
  profile                  = "capgemini"
  region                   = "us-west-2"
}


module "ec2-instances" {
  source = "./ec2"

  aws_vpc_1_id             = aws_vpc.vf2-vpc-1.id
  aws_public_sec_group_id  = aws_security_group.vf2-public-security-group.id
  aws_private_sec_group_id = aws_security_group.vf2-private-security-group.id
  aws_public_subnet_1_id   = aws_subnet.vf2-public-subnet-1.id
  aws_public_subnet_2_id   = aws_subnet.vf2-public-subnet-2.id
  aws_private_subnet_1_id  = aws_subnet.vf2-private-subnet-1.id
  rds_address              = module.postgres.postgres_address
  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
}

module "alb" {
  source = "./alb"

  aws_vpc_1_id            = aws_vpc.vf2-vpc-1.id
  aws_public_sec_group_id = aws_security_group.vf2-public-security-group.id
  aws_public_subnet_1_id  = aws_subnet.vf2-public-subnet-1.id
  aws_public_subnet_2_id  = aws_subnet.vf2-public-subnet-2.id
  aws_asg_id              = module.ec2-instances.aws_asg_id
}

module "dynamodb" {
  source = "./dynamodb"
}

module "postgres" {
  source                    = "./rds"
  aws_postgres_sec_group_id = aws_security_group.vf_postgres_group.id
  rds_subnet_group_name     = aws_db_subnet_group.rds_subnet_group.name
}

module "s3" {
  source = "./s3"
}

module "sqs" {
  source = "./sqs"
}

module "sns" {
  source  = "./sns"
  sqs_arn = module.sqs.sqs_arn
}

resource "aws_vpc" "vf2-vpc-1" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    "Name" = "vf2-vpc-1"
  }
  enable_dns_support   = true
  enable_dns_hostnames = true
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

resource "aws_subnet" "vf2-public-subnet-2" {
  vpc_id                  = aws_vpc.vf2-vpc-1.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags                    = {
    "Name" = "vf2-public-subnet-2"
  }
}

resource "aws_subnet" "vf2-private-subnet-1" {
  vpc_id                  = aws_vpc.vf2-vpc-1.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = false
  tags                    = {
    "Name" = "vf2-private-subnet-1"
  }
}

resource "aws_subnet" "vf2-private-subnet-2" {
  vpc_id                  = aws_vpc.vf2-vpc-1.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-west-2d"
  map_public_ip_on_launch = false
  tags                    = {
    "Name" = "vf2-private-subnet-2"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rdsmain-private"
  description = "Private subnets for RDS instance"
  subnet_ids  = [aws_subnet.vf2-private-subnet-1.id, aws_subnet.vf2-private-subnet-2.id]
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
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
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
  vpc_id      = aws_vpc.vf2-vpc-1.id

  #  ingress {
  #    from_port   = 0
  #    to_port     = 0
  #    protocol    = "-1"
  #    cidr_blocks = ["10.0.0.0/16"]
  #  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ec2-to-postgres-egress" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vf2-private-security-group.id
  source_security_group_id = aws_security_group.vf_postgres_group.id
}

resource "aws_security_group_rule" "postgres-from-ec2-ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vf_postgres_group.id
  source_security_group_id = aws_security_group.vf2-private-security-group.id
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

resource "aws_route_table_association" "public_route_assoc_1" {
  subnet_id      = aws_subnet.vf2-public-subnet-1.id
  route_table_id = aws_route_table.vf2-public-route-table.id
}

resource "aws_route_table_association" "public_route_assoc_2" {
  subnet_id      = aws_subnet.vf2-public-subnet-2.id
  route_table_id = aws_route_table.vf2-public-route-table.id
}
