variable "dns_zone_id" {
  type        = string
  default     = ""
}

variable "host_name" {
  type        = string
  default     = "db"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
}

variable "associate_security_group_ids" {
  type        = list(string)
  default     = []
}

variable "database_name" {
  type        = string
  default     = null
}

variable "database_user" {
  type        = string
  default     = null
}

variable "database_password" {
  type        = string
  default     = null
}

variable "database_port" {
  type        = number
}

variable "deletion_protection" {
  type        = bool
  default     = false
}

variable "multi_az" {
  type        = bool
  default     = false
}

variable "storage_type" {
  type        = string
  default     = "standard"
}

variable "storage_encrypted" {
  type        = bool
  default     = true
}

variable "iops" {
  type        = number
  default     = 0
}

variable "storage_throughput" {
  type        = number
  default     = null
}

variable "allocated_storage" {
  type        = number
  default     = null
}

variable "max_allocated_storage" {
  type        = number
  default     = 0
}

variable "engine" {
  type        = string
  default     = null
}

variable "engine_version" {
  type        = string
}

variable "major_engine_version" {
  type        = string
  default     = ""
}

variable "charset_name" {
  type        = string
  default     = null
}

variable "license_model" {
  type        = string
  default     = ""
}

variable "instance_class" {
  type        = string
}

variable "db_parameter_group" {
  type        = string
  # "mysql5.6"
  # "postgres9.5"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
}

variable "availability_zone" {
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  type        = string
  default     = null
}

variable "vpc_id" {
  type        = string
}

variable "auto_minor_version_upgrade" {
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  type        = bool
  default     = false
}

variable "apply_immediately" {
  type        = bool
  default     = false
}

variable "maintenance_window" {
  type        = string
  default     = "Mon:03:00-Mon:04:00"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  type        = number
  default     = 0
}

variable "backup_window" {
  type        = string
  default     = "22:00-03:00"
}

variable "db_parameter" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
}

variable "db_options" {
  type = list(object({
    db_security_group_memberships  = list(string)
    option_name                    = string
    port                           = number
    version                        = string
    vpc_security_group_memberships = list(string)

    option_settings = list(object({
      name  = string
      value = string
    }))
  }))

  default     = []
}

variable "snapshot_identifier" {
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  type        = string
  default     = ""
}

variable "parameter_group_name" {
  type        = string
  default     = ""
}

variable "option_group_name" {
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  type        = string
  default     = ""
}

variable "performance_insights_enabled" {
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = []
}

variable "ca_cert_identifier" {
  type        = string
  default     = null
}

variable "monitoring_interval" {
  default     = "0"
}

variable "monitoring_role_arn" {
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  type        = bool
  default     = false
}

variable "replicate_source_db" {
  type        = string
  default     = null
}

variable "timezone" {
  type        = string
  default     = null
}

variable "timeouts" {
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "40m"
    update = "80m"
    delete = "60m"
  }
}

variable "identifier" {
  
}