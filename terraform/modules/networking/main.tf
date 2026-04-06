resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = { Name = "${var.env}-vpc" }
}

resource "aws_subnet" "kong_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.kong_subnet_cidr
  availability_zone = var.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.env}-kong-subnet"}
}

resource "aws_subnet" "authmat_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.authmat_subnet_cidr
  availability_zone = var.az

  tags = { Name = "${var.env}-authmat-subnet" }
}

resource "aws_subnet" "dockeep_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.dockeep_subnet_cidr
  availability_zone = var.az

  tags = { Name = "${var.env}-dockeep-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.env}-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "${var.env}-public-rt" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.env}-private-rt" }
}

resource "aws_route_table_association" "kong-rta" {
  subnet_id = aws_subnet.kong_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "authmat-rta" {
  subnet_id = aws_subnet.authmat_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "dockeep-rta" {
  subnet_id = aws_subnet.dockeep_subnet.id
  route_table_id = aws_route_table.private_rt.id
}


# NOTE:
# Migrated from inline SG rules (i.e., ingress{}) to SG declarations
# because it only supports external/internet requests which wouldn't allow
# Kong to intercept requests and forward them to the services
resource "aws_security_group" "kong_sg" {
  name = "${var.env}-kong-sg"
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-kong-sg"}
}

resource "aws_security_group" "authmat_sg" {
  name = "${var.env}-authmat-sg"
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-authmat-sg"}
}

resource "aws_security_group" "dockeep_sg" {
  name = "${var.env}-dockeep-sg"
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-dockeep-sg"}
}

resource "aws_security_group_rule" "kong_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kong_sg.id
  description       = "Public HTTPS"
}

resource "aws_security_group_rule" "kong_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kong_sg.id
  description       = "Public HTTP"
}

resource "aws_security_group_rule" "kong_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_cidr]
  security_group_id = aws_security_group.kong_sg.id
  description       = "SSH"
}

resource "aws_security_group_rule" "kong_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kong_sg.id
}


resource "aws_security_group_rule" "authmat_ingress_from_kong" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kong_sg.id
  security_group_id        = aws_security_group.authmat_sg.id
  description              = "App port from Kong only"
}

resource "aws_security_group_rule" "authmat_ingress_ssh" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  cidr_blocks              = [var.ssh_allowed_cidr]
  security_group_id        = aws_security_group.authmat_sg.id
  description              = "SSH"
}

resource "aws_security_group_rule" "authmat_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.authmat_sg.id
}