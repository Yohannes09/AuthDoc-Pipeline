variable "vpc_cidr" { type = string }

variable "kong_subnet_cidr" { type = string }
variable "authmat_subnet_cidr" { type = string }
variable "dockeep_subnet_cidr" { type = string }

variable "ssh_allowed_cidr_dev" {
  type = string
  sensitive = true
}

variable "instance_type" { type = string }

variable "env" {
  type = string
  default = "dev"
}
