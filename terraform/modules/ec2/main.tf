resource "aws_instance" "this" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_groups

  root_block_device {
    volume_size = 8
    volume_type = var.volume_type
    delete_on_termination = var.delete_on_termination
  }

  tags = {
    Name = "authdoc-ec2"
  }
}