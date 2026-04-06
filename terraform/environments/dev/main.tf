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
  source              = "../../modules/networking"
  env                 = var.env
  az                  = data.aws_availability_zones.available_az.names[0]
  kong_subnet_cidr    = var.kong_subnet_cidr
  authmat_subnet_cidr = var.authmat_subnet_cidr
  dockeep_subnet_cidr = var.dockeep_subnet_cidr
  vpc_cidr            = var.vpc_cidr
  ssh_allowed_cidr    = var.ssh_allowed_cidr_dev
}

module "kong" {
  source               = "../../modules/kong"
  env                  = var.env
  instance_type        = var.instance_type
  os_ami_id            = data.aws_ami.ubuntu.id
  az                   = data.aws_availability_zones.available_az.names[0]
  sg_id                = module.networking.kong_sg_id
  subnet_id            = module.networking.kong_subnet_id
}

module "authmat" {
  source               = "../../modules/authmat"
  env                  = var.env
  instance_type        = var.instance_type
  os_ami_id            = data.aws_ami.ubuntu.id
  az                   = data.aws_availability_zones.available_az.names[0]
  sg_id                = module.networking.authmat_sg_id
  subnet_id            = module.networking.authmat_subnet_id
  iam_instance_profile = module.kms.kms_sign_instance_profile
}

module "dockeep" {
  source        = "../../modules/dockeep"
  env           = var.env
  instance_type = var.instance_type
  os_ami_id     = data.aws_ami.ubuntu.id
  az            = data.aws_availability_zones.available_az.names[0]
  sg_id         = module.networking.dockeep_sg_id
  subnet_id     = module.networking.dockeep_subnet_id
}