data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "networking" {
  source = "../../modules/networking"

  env                 = "dev"
  authmat_subnet_cidr = var.authmat_subnet_cidr_dev
  dockeep_subnet_cidr = var.dockeep_subnet_cider_dev
  vpc-cidr-block    = var.vpc_cidr_dev
  ssh_allowed_cidr = var.ssh_allowed_cidr_dev
}

// TODO
module "authmat" {
  source = "../../modules/authmat"

  env           = "dev"
  az            = module.networking.authmat_subnet_id
  instance_type = ""
  sg_id         = module.networking.sg_id
  subnet_id     = module.networking.authmat_subnet_id
  ubuntu        = data.aws_ami.ubuntu.id
}

module "dockeep" {
  source = "../../modules/dockeep"
}