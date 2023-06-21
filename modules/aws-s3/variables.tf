variable "acl" {
  type        = string
  default     = "private"
}

variable "grants" {
  type = list(object({
    id          = string
    type        = string
    permissions = list(string)
    uri         = string
  }))
  default = []
}

variable "source_policy_documents" {
  type        = list(string)
  default     = []
}
locals {
  source_policy_documents = compact(concat([var.policy], var.source_policy_documents))
}

variable "force_destroy" {
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  type        = bool
  default     = true
}

variable "logging" {
  type = object({
    bucket_name = string
    prefix      = string
  })
  default     = null
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
}

variable "user_permissions_boundary_arn" {
  type        = string
  default     = null
}

variable "access_key_enabled" {
  type        = bool
  default     = true
}

variable "store_access_key_in_ssm" {
  type        = bool
  default     = false
}

variable "ssm_base_path" {
  type        = string
  default     = "/s3_user/"
}

variable "allowed_bucket_actions" {
  type        = list(string)
  default     = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:GetBucketLocation", "s3:AbortMultipartUpload"]
}

variable "allow_encrypted_uploads_only" {
  type        = bool
  default     = false
}

variable "allow_ssl_requests_only" {
  type        = bool
  default     = false
}

variable "lifecycle_configuration_rules" {
  type = list(object({
    enabled = bool
    id      = string
    abort_incomplete_multipart_upload_days = number
    filter_and = any
    expiration = any
    transition = list(any)

    noncurrent_version_expiration = any
    noncurrent_version_transition = list(any)
  }))
  default     = []
}

variable "cors_configuration" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default     = []
}

variable "block_public_acls" {
  type        = bool
  default     = true
}

variable "block_public_policy" {
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  default     = true
}

variable "s3_replication_enabled" {
  type        = bool
  default     = false
}

variable "s3_replica_bucket_arn" {
  type        = string
  default     = ""
}

variable "s3_replication_rules" {
  type        = list(any)
  default     = null
}
locals {
  s3_replication_rules = var.replication_rules == null ? var.s3_replication_rules : var.replication_rules
}

variable "s3_replication_source_roles" {
  type        = list(string)
  default     = []
}

variable "s3_replication_permissions_boundary_arn" {
  type        = string
  default     = null
}

variable "bucket_name" {
  type        = string
  default     = null
}

variable "object_lock_configuration" {
  type = object({
    mode  = string # Valid values are GOVERNANCE and COMPLIANCE.
    days  = number
    years = number
  })
  default     = null
}

variable "website_redirect_all_requests_to" {
  type = list(object({
    host_name = string
    protocol  = string
  }))
  default     = []

  validation {
    condition     = length(var.website_redirect_all_requests_to) < 2
    error_message = "Only 1 website_redirect_all_requests_to is allowed."
  }
}

variable "website_configuration" {
  type = list(object({
    index_document = string
    error_document = string
    routing_rules = list(object({
      condition = object({
        http_error_code_returned_equals = string
        key_prefix_equals               = string
      })
      redirect = object({
        host_name               = string
        http_redirect_code      = string
        protocol                = string
        replace_key_prefix_with = string
        replace_key_with        = string
      })
    }))
  }))
  default     = []

  validation {
    condition     = length(var.website_configuration) < 2
    error_message = "Only 1 website_configuration is allowed."
  }
}

variable "privileged_principal_arns" {
  #  type        = map(list(string))
  #  default     = {}
  type    = list(map(list(string)))
  default = []
}

variable "privileged_principal_actions" {
  type        = list(string)
  default     = []
}

variable "transfer_acceleration_enabled" {
  type        = bool
  default     = false
}

variable "s3_object_ownership" {
  type        = string
  default     = "ObjectWriter"
}

variable "bucket_key_enabled" {
  type        = bool
  default     = false
}