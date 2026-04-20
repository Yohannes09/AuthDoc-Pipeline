variable "env" { type = string }
variable "kms_deletion_window_days" { type = number }
variable "log_retention_days" { type = number }
variable "vpc_id" { type = string }
variable "operator_cidrs" { type = list(string) }

variable "kubernetes_version" { type = string }
variable "control_plane_subnet_ids" { type = list(string) }
variable "enable_public_endpoint" { type = bool default = false}
variable "public_endpoint_cidrs" {
  type = list(string)
  default = []

  validation {
    condition = !(var.enable_public_endpoint) || (
            length(var.public_endpoint_cidrs) > 0 &&
            !contains(var.public_endpoint_cidrs, "0.0.0.0/0")
    )
    error_message = "public_endpoint_cidrs must be set to specific CIDRs"
  }
}