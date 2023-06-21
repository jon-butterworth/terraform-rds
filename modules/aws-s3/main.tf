locals {
  enabled   = module.this.enabled
  partition = join("", data.aws_partition.current[*].partition)

  object_lock_enabled           = local.enabled && var.object_lock_configuration != null
  replication_enabled           = local.enabled && var.s3_replication_enabled
  versioning_enabled            = local.enabled && var.versioning_enabled
  transfer_acceleration_enabled = local.enabled && var.transfer_acceleration_enabled

  bucket_name = var.bucket_name != null && var.bucket_name != "" ? var.bucket_name : module.this.id
  bucket_arn  = "arn:${local.partition}:s3:::${join("", aws_s3_bucket.default[*].id)}"

  acl_grants = var.grants == null ? [] : flatten(
    [
      for g in var.grants : [
        for p in g.permissions : {
          id         = g.id
          type       = g.type
          permission = p
          uri        = g.uri
        }
      ]
  ])
}

data "aws_partition" "current" { count = local.enabled ? 1 : 0 }
data "aws_canonical_user_id" "default" { count = local.enabled ? 1 : 0 }

resource "aws_s3_bucket" "default" {
  count         = local.enabled ? 1 : 0
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  object_lock_enabled = local.object_lock_enabled

  tags = module.this.tags
}

resource "aws_s3_bucket_accelerate_configuration" "default" {
  count  = local.transfer_acceleration_enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)
  status = "Enabled"
}

resource "aws_s3_bucket_versioning" "default" {
  count  = local.enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  versioning_configuration {
    status = local.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_logging" "default" {
  count  = local.enabled && var.logging != null ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  target_bucket = var.logging["bucket_name"]
  target_prefix = var.logging["prefix"]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = local.enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  rule {
    bucket_key_enabled = var.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_master_key_arn
    }
  }
}

resource "aws_s3_bucket_website_configuration" "default" {
  count  = local.enabled && (try(length(var.website_configuration), 0) > 0) ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  dynamic "index_document" {
    for_each = try(length(var.website_configuration[0].index_document), 0) > 0 ? [true] : []
    content {
      suffix = var.website_configuration[0].index_document
    }
  }

  dynamic "error_document" {
    for_each = try(length(var.website_configuration[0].error_document), 0) > 0 ? [true] : []
    content {
      key = var.website_configuration[0].error_document
    }
  }

  dynamic "routing_rule" {
    for_each = try(length(var.website_configuration[0].routing_rules), 0) > 0 ? var.website_configuration[0].routing_rules : []
    content {
      dynamic "condition" {
        for_each = try(length(routing_rule.value.condition.http_error_code_returned_equals), 0) + try(length(routing_rule.value.condition.key_prefix_equals), 0) > 0 ? [true] : []
        content {
          http_error_code_returned_equals = routing_rule.value.condition.http_error_code_returned_equals
          key_prefix_equals               = routing_rule.value.condition.key_prefix_equals
        }
      }

      redirect {
        host_name               = routing_rule.value.redirect.host_name
        http_redirect_code      = routing_rule.value.redirect.http_redirect_code
        protocol                = routing_rule.value.redirect.protocol
        replace_key_prefix_with = routing_rule.value.redirect.replace_key_prefix_with
        replace_key_with        = routing_rule.value.redirect.replace_key_with
      }
    }
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  count  = local.enabled && (try(length(var.website_redirect_all_requests_to), 0) > 0) ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  redirect_all_requests_to {
    host_name = var.website_redirect_all_requests_to[0].host_name
    protocol  = var.website_redirect_all_requests_to[0].protocol
  }
}


resource "aws_s3_bucket_cors_configuration" "default" {
  count = local.enabled && try(length(var.cors_configuration), 0) > 0 ? 1 : 0

  bucket = join("", aws_s3_bucket.default[*].id)

  dynamic "cors_rule" {
    for_each = var.cors_configuration

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_acl" "default" {
  count  = local.enabled && var.s3_object_ownership != "BucketOwnerEnforced" ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  acl = try(length(local.acl_grants), 0) == 0 ? var.acl : null

  dynamic "access_control_policy" {
    for_each = try(length(local.acl_grants), 0) == 0 || try(length(var.acl), 0) > 0 ? [] : [1]

    content {
      dynamic "grant" {
        for_each = local.acl_grants

        content {
          grantee {
            id   = grant.value.id
            type = grant.value.type
            uri  = grant.value.uri
          }
          permission = grant.value.permission
        }
      }

      owner {
        id = join("", data.aws_canonical_user_id.default[*].id)
      }
    }
  }
  depends_on = [aws_s3_bucket_ownership_controls.default]
}

resource "aws_s3_bucket_replication_configuration" "default" {
  count = local.replication_enabled ? 1 : 0

  bucket = join("", aws_s3_bucket.default[*].id)
  role   = aws_iam_role.replication[0].arn

  dynamic "rule" {
    for_each = local.s3_replication_rules == null ? [] : local.s3_replication_rules

    content {
      id       = rule.value.id
      priority = try(rule.value.priority, 0)
      status = try(rule.value.status, null)

      delete_marker_replication {
        status = try(rule.value.delete_marker_replication_status, "Disabled")
      }

      destination {
        bucket        = try(length(rule.value.destination_bucket), 0) > 0 ? rule.value.destination_bucket : var.s3_replica_bucket_arn
        storage_class = try(rule.value.destination.storage_class, "STANDARD")

        dynamic "encryption_configuration" {
          for_each = try(rule.value.destination.replica_kms_key_id, null) != null ? [1] : []

          content {
            replica_kms_key_id = try(rule.value.destination.replica_kms_key_id, null)
          }
        }

        account = try(rule.value.destination.account_id, null)

        dynamic "metrics" {
          for_each = try(rule.value.destination.metrics.status, "") == "Enabled" ? [1] : []

          content {
            status = "Enabled"
            event_threshold {
              minutes = 15
            }
          }
        }

        dynamic "replication_time" {
          for_each = try(rule.value.destination.metrics.status, "") == "Enabled" ? [1] : []

          content {
            status = "Enabled"
            time {
              minutes = 15
            }
          }
        }

        dynamic "access_control_translation" {
          for_each = try(rule.value.destination.access_control_translation.owner, null) == null ? [] : [rule.value.destination.access_control_translation.owner]

          content {
            owner = access_control_translation.value
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = try(rule.value.source_selection_criteria.sse_kms_encrypted_objects.enabled, null) == null ? [] : [rule.value.source_selection_criteria.sse_kms_encrypted_objects.enabled]

        content {
          sse_kms_encrypted_objects {
            status = source_selection_criteria.value
          }
        }
      }

      dynamic "filter" {
        for_each = try(rule.value.filter, null) == null ? [{ prefix = null, tags = {} }] : [rule.value.filter]

        content {
          prefix = try(filter.value.prefix, try(rule.value.prefix, null))
          dynamic "tag" {
            for_each = try(filter.value.tags, {})

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.default
  ]
}

resource "aws_s3_bucket_object_lock_configuration" "default" {
  count = local.object_lock_enabled ? 1 : 0

  bucket = join("", aws_s3_bucket.default[*].id)

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode  = var.object_lock_configuration.mode
      days  = var.object_lock_configuration.days
      years = var.object_lock_configuration.years
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  count = local.enabled ? 1 : 0

  dynamic "statement" {
    for_each = var.allow_encrypted_uploads_only ? [1] : []

    content {
      sid       = "DenyIncorrectEncryptionHeader"
      effect    = "Deny"
      actions   = ["s3:PutObject"]
      resources = ["${local.bucket_arn}/*"]

      principals {
        identifiers = ["*"]
        type        = "*"
      }

      condition {
        test     = "StringNotEquals"
        values   = [var.sse_algorithm]
        variable = "s3:x-amz-server-side-encryption"
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_encrypted_uploads_only ? [1] : []

    content {
      sid       = "DenyUnEncryptedObjectUploads"
      effect    = "Deny"
      actions   = ["s3:PutObject"]
      resources = ["${local.bucket_arn}/*"]

      principals {
        identifiers = ["*"]
        type        = "*"
      }

      condition {
        test     = "Null"
        values   = ["true"]
        variable = "s3:x-amz-server-side-encryption"
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_ssl_requests_only ? [1] : []

    content {
      sid       = "ForceSSLOnlyAccess"
      effect    = "Deny"
      actions   = ["s3:*"]
      resources = [local.bucket_arn, "${local.bucket_arn}/*"]

      principals {
        identifiers = ["*"]
        type        = "*"
      }

      condition {
        test     = "Bool"
        values   = ["false"]
        variable = "aws:SecureTransport"
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_replication_source_roles) > 0 ? [1] : []

    content {
      sid = "CrossAccountReplicationObjects"
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ]
      resources = ["${local.bucket_arn}/*"]
      principals {
        type        = "AWS"
        identifiers = var.s3_replication_source_roles
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_replication_source_roles) > 0 ? [1] : []

    content {
      sid       = "CrossAccountReplicationBucket"
      actions   = ["s3:List*", "s3:GetBucketVersioning", "s3:PutBucketVersioning"]
      resources = [local.bucket_arn]
      principals {
        type        = "AWS"
        identifiers = var.s3_replication_source_roles
      }
    }
  }

  dynamic "statement" {
    for_each = var.privileged_principal_arns

    content {
      sid     = "AllowPrivilegedPrincipal[${statement.key}]" # add indices to Sid
      actions = var.privileged_principal_actions
      resources = distinct(flatten([
        "arn:${local.partition}:s3:::${join("", aws_s3_bucket.default[*].id)}",
        formatlist("arn:${local.partition}:s3:::${join("", aws_s3_bucket.default[*].id)}/%s*", values(statement.value)[0]),
      ]))
      principals {
        type        = "AWS"
        identifiers = [keys(statement.value)[0]]
      }
    }
  }
}

data "aws_iam_policy_document" "aggregated_policy" {
  count = local.enabled ? 1 : 0

  source_policy_documents   = data.aws_iam_policy_document.bucket_policy[*].json
  override_policy_documents = local.source_policy_documents
}

resource "aws_s3_bucket_policy" "default" {
  count      = local.enabled && (var.allow_ssl_requests_only || var.allow_encrypted_uploads_only || length(var.s3_replication_source_roles) > 0 || length(var.privileged_principal_arns) > 0 || length(var.source_policy_documents) > 0) ? 1 : 0
  bucket     = join("", aws_s3_bucket.default[*].id)
  policy     = join("", data.aws_iam_policy_document.aggregated_policy[*].json)
  depends_on = [aws_s3_bucket_public_access_block.default]
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = module.this.enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_ownership_controls" "default" {
  count  = local.enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default[*].id)

  rule {
    object_ownership = var.s3_object_ownership
  }
  depends_on = [time_sleep.wait_for_aws_s3_bucket_settings]
}

resource "time_sleep" "wait_for_aws_s3_bucket_settings" {
  count            = local.enabled ? 1 : 0
  depends_on       = [aws_s3_bucket_public_access_block.default, aws_s3_bucket_policy.default]
  create_duration  = "30s"
  destroy_duration = "30s"
}