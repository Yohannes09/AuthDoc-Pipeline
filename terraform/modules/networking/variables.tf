variable "vpc-cidr-block" {
  type = string
}

variable "authmat_subnet_cidr" {
  type = string
}

variable "dockeep_subnet_cidr" {
  type = string
}

variable "env" {
  type = string
}

variable "ssh_allowed_cidr" {
  type = string
}

variable "az" {
  type = string
  description = "Availability zone for subnets"
}