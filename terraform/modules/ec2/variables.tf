variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "ami"{
  type = string
}

variable "subnet_id"{
  type = string
}

variable "vpc_groups"{
  type = list(string)
}

variable "volume_type" {
  type = string
  default = "gp3"
}

variable "delete_on_termination" {
  type = bool
  default = true
}