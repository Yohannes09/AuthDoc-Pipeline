
resource "aws_security_group" "rds" {
  name = "${var.env}-rds-sg"
  vpc_id = var.vpc_id
  tags = { Name = "${var.env}-rds-sg"}
}

resource "aws_security_group_rule" "rds_ingress_from_nodes" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  security_group_id = aws_security_group.rds.id
  source_security_group_id = var.worker_node_sg_id
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
}


# TODO - subnet group must contain subnets in at least two AZs even when running a single AZ RDS
# Metadata that tells RDS which subnet it's allowed to be placed in
# AWS requires creating a subnet group first
resource "aws_db_subnet_group" "postgres" {
  name = "${var.env}-postgres-subnet-group"
  subnet_ids = var.data_subnet_ids
}



// TODO - not happy with this implementation
// Note - Idempotent and the credential will be saved to .tfstate
resource "random_password" "db_password" {
  length = 32
  special = true # allows special characters
  override_special = "!#$%&*()-_=+[]{}:?" # override default special characters
}

resource "aws_secretsmanager_secret" "db_password" {

}



resource "aws_db_instance" "postgres" {
  identifier = "${var.env}-postgres"
  engine = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class # db.t3.micro
  allocated_storage = var.db_allocated_storage
  storage_type = "gp3"
  storage_encrypted = true

  db_name = ""
  username = ""
  password = ""

  db_subnet_group_name = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az = var.availability_zone_count > 1 ? true : false
  publicly_accessible = false
  skip_final_snapshot = var.env == "prod" ? false : true
  deletion_protection = var.env == "prod" ? true : false
}