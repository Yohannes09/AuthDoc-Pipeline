resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = { Name = "${var.env}-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-igw" }
}




resource "aws_subnet" "public_subnet" {
  count = var.availability_zone_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.env}-public-subnet-${var.availability_zones[count.index]}"}
}

resource "aws_eip" "public_nat_eip" {
  count = var.availability_zone_count
  domain = "vpc"
  tags = { Name = "${var.env}-public-nat-eip-${var.availability_zones[count.index]}"}
}

resource "aws_nat_gateway" "public_nat" {
  count = var.availability_zone_count
  subnet_id = aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.public_nat_eip[count.index].id
  tags = { Name = "${var.env}-public-nat-${var.availability_zones[count.index]}"}
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${var.env}-public-rt-${var.availability_zones[count.index]}" }
}

resource "aws_route_table_association" "public_rt_association" {
  count = var.availability_zone_count
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}




resource "aws_subnet" "node_subnet" {
  count = var.availability_zone_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.node_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.env}-private-subnet-${var.availability_zones[count.index]}"}
}

resource "aws_route_table" "node_rt" {
  count = var.availability_zone_count
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_nat[count.index].id
  }
  tags = { Name = "${var.env}-node-rt-${var.availability_zones[count.index]}"}
}

resource "aws_route_table_association" "node_rt_association" {
  count = var.availability_zone_count
  route_table_id = aws_route_table.node_rt[count.index].id
  subnet_id = aws_subnet.node_subnet[count.index].id
}




resource "aws_subnet" "control_plane_subnet" {
  count = var.availability_zone_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.control_plane_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.env}-control-plane-subnet-${var.availability_zones[count.index]}"}
}

resource "aws_route_table" "control_plane_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-control-plane-rt-${var.availability_zones[count.index]}"}
}

resource "aws_route_table_association" "control_plane_rt_association" {
  count = var.availability_zone_count
  route_table_id = aws_route_table.control_plane_rt[count.index].id
  subnet_id = aws_subnet.control_plane_subnet[count.index].id
}




resource "aws_subnet" "data_subnet" {
  count = var.availability_zone_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.env}-data-subnet-${var.availability_zones[count.index]}"}
}

resource "aws_route_table" "data_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.env}-data-subnet-rt-${var.availability_zones[count.index]}"}
}


resource "aws_route_table_association" "data_rt_association" {
  count = var.availability_zone_count
  route_table_id = aws_route_table.data_rt.id
  subnet_id = aws_subnet.data_subnet[count.index].id
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