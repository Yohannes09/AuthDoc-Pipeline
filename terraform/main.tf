resource "aws_vpc" "authdoc_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "authdoc_subnet" {
  vpc_id = aws_vpc.authdoc_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "authdoc_sg" {
  vpc_id = aws_vpc.authdoc_vpc.id

  ingress{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "authdoc_app" {
  ami = "ami-"
  instance_type = var.instance_type
  subnet_id = aws_subnet.authdoc_subnet.id
  vpc_security_group_ids = [aws_security_group.authdoc_sg.id]

  tags = {
    Name = "AuthDocApp"
  }
}