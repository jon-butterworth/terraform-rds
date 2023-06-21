output "bucket_domain_name" {
  value       = local.enabled ? join("", aws_s3_bucket.default[*].bucket_domain_name) : ""
}

output "bucket_regional_domain_name" {
  value       = local.enabled ? join("", aws_s3_bucket.default[*].bucket_regional_domain_name) : ""
}

output "bucket_website_domain" {
  value       = join("", aws_s3_bucket_website_configuration.default[*].website_domain, aws_s3_bucket_website_configuration.redirect[*].website_domain)
}

output "bucket_website_endpoint" {
  value       = join("", aws_s3_bucket_website_configuration.default[*].website_endpoint, aws_s3_bucket_website_configuration.redirect[*].website_endpoint)
}

output "bucket_id" {
  value       = local.enabled ? join("", aws_s3_bucket.default[*].id) : ""
}

output "bucket_arn" {
  value       = local.enabled ? join("", aws_s3_bucket.default[*].arn) : ""
}

output "bucket_region" {
  value       = local.enabled ? join("", aws_s3_bucket.default[*].region) : ""
}

output "enabled" {
  value       = local.enabled
}

output "user_enabled" {
  value       = var.user_enabled
}

output "user_name" {
  value       = module.s3_user.user_name
}

output "user_arn" {
  value       = module.s3_user.user_arn
}

output "user_unique_id" {
  value       = module.s3_user.user_unique_id
}

output "replication_role_arn" {
  value       = local.enabled && local.replication_enabled ? join("", aws_iam_role.replication[*].arn) : ""
}

output "access_key_id" {
  sensitive   = true
  value       = module.s3_user.access_key_id
}

output "secret_access_key" {
  sensitive   = true
  value       = module.s3_user.secret_access_key
}

output "access_key_id_ssm_path" {
  value       = module.s3_user.access_key_id_ssm_path
}

output "secret_access_key_ssm_path" {
  value       = module.s3_user.secret_access_key_ssm_path
}