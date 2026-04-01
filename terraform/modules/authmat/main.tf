resource "aws_instance" "authmat_ec2" {
  ami = var.ubuntu
  instance_type = var.instance_type
  availability_zone = var.az
  key_name = ""

  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.env}-ec2"
  }
}