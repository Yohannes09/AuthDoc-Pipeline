variable "env" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = set(string) }
variable "nginx_nodeport" { type = number }
variable "target_type" { type = string default = "instance"}
variable "worker_node_ids" { type = list(string) }