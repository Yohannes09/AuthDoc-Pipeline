variable "vpc_cidr_dev" {
  type = string
}

variable "authmat_subnet_cidr_dev" {
  type = string
}

variable "dockeep_subnet_cider_dev" {
  type = string
}

variable "ssh_allowed_cidr_dev" {
  type = string
  sensitive = true
}