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
  tags = { Name = "${var.env}-public-rt" }
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
