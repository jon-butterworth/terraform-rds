variable "target_security_group_id" {
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.target_security_group_id) < 2
    error_message = "Only 1 security group can be targeted."
  }
}

variable "security_group_name" {
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.security_group_name) < 2
    error_message = "Only 1 security group name can be provided."
  }
}

variable "security_group_description" {
  type        = string
  default     = "Managed by Terraform"
}

variable "create_before_destroy" {
  type        = bool
  default     = true
}

variable "preserve_security_group_id" {
  type        = bool
  default     = false
}

variable "allow_all_egress" {
  type        = bool
  default     = true
}

variable "rules" {
  type        = list(any)
  default     = []
}

variable "rules_map" {
  type        = any
  default     = {}
}

variable "rule_matrix" {
  type        = any
  default     = []
}

variable "security_group_create_timeout" {
  type        = string
  default     = "10m"
}

variable "security_group_delete_timeout" {
  type        = string
  default     = "15m"
}

variable "revoke_rules_on_delete" {
  type        = bool
  default     = false
}

variable "vpc_id" {
  type        = string
}

variable "inline_rules_enabled" {
  type        = bool
  default     = false
}