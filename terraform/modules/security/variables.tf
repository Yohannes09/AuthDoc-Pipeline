variable "name" { type = string }
variable "vpc_id" { type = string }
variable "app_port" { type = number, default = 8080 }
variable "ssh_allowed_cidrs" { type = list(string), default = ["0.0.0.0/0"] }
variable "dockeep_bucket_arn" { type = string }
variable "tags" { type = map(string), default = {} }