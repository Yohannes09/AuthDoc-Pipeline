variable "env" { type = string}

variable "vpc_cidr" { type = string }
variable "availability_zone_count"{ type = number }
variable "availability_zones" { type = list(number) }

variable "public_subnet_cidrs" { type = list(string) }
variable "node_subnet_cidrs" { type = list(string) }
variable "control_plane_subnet_cidrs" { type = list(string) }
variable "data_subnet_cidrs" { type = list(string) }