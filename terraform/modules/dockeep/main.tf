resource "aws_instance" "dockeep_ec2" {
  ami = var.os_ami_id
  instance_type = var.instance_type
  availability_zone = var.az
  key_name = ""

  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = true

  tags = { Name = "${var.env}-dockeep-ec2" }
}

resource "aws_s3_bucket" "dockeep_bucket" {
  bucket = "${var.env}-dockeep-bucket"

  tags = { Name = "${var.env}-dockeep-bucket" }
}