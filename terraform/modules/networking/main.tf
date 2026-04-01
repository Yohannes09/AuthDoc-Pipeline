resource "aws_vpc" "authmat_dockeep_vpc" {
  cidr_block = var.vpc-cidr-block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_subnet" "authmat_subnet" {
  vpc_id = aws_vpc.authmat_dockeep_vpc.id
  cidr_block = var.authmat_subnet_cidr
  availability_zone = ""

  tags = {
    Name = "${var.env}-authmat-subnet"
  }
}
//TODO: figure out best way to add availability zone (i.e., hardcoded or var)
resource "aws_subnet" "dockeep_subnet" {
  vpc_id = aws_vpc.authmat_dockeep_vpc.id
  cidr_block = var.dockeep_subnet_cidr
  availability_zone = ""

  tags = {
    Name = "${var.env}-dockeep-subnet"
  }
}

resource "aws_internet_gateway" "authmat-dockeep-gw" {
  vpc_id = aws_vpc.authmat_dockeep_vpc.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "authmat_dockeep_rt" {
  vpc_id = aws_vpc.authmat_dockeep_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.authmat-dockeep-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.authmat-dockeep-gw.id
  }

  tags = {
    Name = "${var.env}-route-table"
  }
}

resource "aws_route_table_association" "authmat-rt-association" {
  subnet_id = aws_subnet.authmat_subnet.id
  route_table_id = aws_route_table.authmat_dockeep_rt.id
}

resource "aws_route_table_association" "dockeep-rt-association" {
  subnet_id = aws_subnet.dockeep_subnet.id
  route_table_id = aws_route_table.authmat_dockeep_rt.id
}

resource "aws_security_group" "authmat-dockeep-sg" {
  name = "prod_security_group"
  vpc_id = aws_vpc.authmat_dockeep_vpc.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH only for me"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-sg"
  }
}