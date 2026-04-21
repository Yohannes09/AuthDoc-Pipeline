variable "env" { type = string }

variable "cluster_name" {}
variable "worker_subnet_ids" {}


variable "desired_size" { type = number }
variable "max_size" { type = number }
variable "min_size" { type = number }
variable "vpc_id" { type = string }
variable "cluster_sg_id" { type = string }
variable "ebs_key_deletion_window_days" { type = number }
variable "ebs_key_enable_key_rotation" { type = bool default = false }
variable "worker_volume_size_gb" { type = number default = 10 }






variable "worker_node_count" { type = number }
variable "control_plane_sg_id" { type = string }
variable "vpc_cidr" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "worker_node_subnet_ids" { type = list(string) }
variable "key_name"  { type = string }
