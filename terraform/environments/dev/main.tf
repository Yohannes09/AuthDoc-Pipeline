data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available_az"{ state = "available" }


module "kms" {
  source = "../../modules/kms"
  env = var.env
}

module "networking" {
  source = "../../modules/networking"

  availability_zone_count = 0
  availability_zones = []
  control_plane_subnet_cidrs = []
  data_subnet_cidrs = []
  env                     = ""
  node_subnet_cidrs = []
  public_subnet_cidrs = []
  vpc_cidr                = ""
}