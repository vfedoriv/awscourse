resource "aws_db_instance" "vf-postgres-db-1" {
  identifier             = "vf-postgres-db-1"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.15"
  username               = "rootuser"
  password               = "rootuser"
  skip_final_snapshot    = true
  vpc_security_group_ids = [var.aws_postgres_sec_group_id]
  db_name                = "EduLohikaTrainingAwsRds"
  port                   = 5432
  db_subnet_group_name   = var.rds_subnet_group_name
}

output "postgres_address" {
  value = aws_db_instance.vf-postgres-db-1.address
}

output "postgres_port" {
  value = aws_db_instance.vf-postgres-db-1.port
}
