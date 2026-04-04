data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available_az"{
  state = "available"
}

module "networking" {
  source = "../../modules/networking"

  env                 = "dev"
  az                  = data.aws_availability_zones.available_az.names[0]
  authmat_subnet_cidr = var.authmat_subnet_cidr_dev
  dockeep_subnet_cidr = var.dockeep_subnet_cider_dev
  vpc-cidr-block      = var.vpc_cidr_dev
  ssh_allowed_cidr    = var.ssh_allowed_cidr_dev
}

module "kms" {
  source = "../../modules/kms"

  env = "dev"
}

module "authmat" {
  source = "../../modules/authmat"

  env           = "dev"
  instance_type = "t3.micro"
  az            = data.aws_availability_zones.available_az.names[0]
  sg_id         = module.networking.sg_id
  subnet_id     = module.networking.authmat_subnet_id
  ubuntu        = data.aws_ami.ubuntu.id
  iam_instance_profile = module.kms.kms_sign_instance_profile_arn
}

module "dockeep" {
  source = "../../modules/dockeep"

  env           = "dev"
  instance_type = "t3.micro"
  az            = data.aws_availability_zones.available_az.names[0]
  sg_id         = module.networking.sg_id
  subnet_id     = module.networking.authmat_subnet_id
  ubuntu        = data.aws_ami.ubuntu.id
}