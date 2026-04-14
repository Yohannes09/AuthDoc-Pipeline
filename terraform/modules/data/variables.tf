variable "env" { type = string }
variable "vpc_id" { type = string }
variable "worker_node_sg_id" { type = string }
variable "data_subnet_ids" { type = list(string) }

variable "db_instance_class" { type = string }
variable "db_allocated_storage" { type = string }
variable "availability_zone_count" { type = string }