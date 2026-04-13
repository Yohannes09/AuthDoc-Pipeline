variable "env" { type = string }
variable "vpc_id" { type = string }
variable "worker_node_sg_id" { type = string }
variable "operator_cidr" { type = string }

variable "control_plane_node_count" { type = string }
variable "ami_id"  { type = string }
variable "instance_type" { type = string}
variable "control_plane_subnet_ids" { type = list(string) }
variable "key_name" { type = string }