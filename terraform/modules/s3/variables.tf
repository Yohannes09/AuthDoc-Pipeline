variable "bucket_name" { type = string }
variable "persistent" { type = bool }
variable "versioning" { type = bool, default = true }
variable "lifecycle_enabled" { type = bool, default = true }
variable "lifecycle_days" { type = number, default = 365 }
variable "noncurrent_version_days" { type = number, default = 30 }
variable "tags" { type = map(string), default = {} }