output "id" {
  value       = local.security_group_id
}

output "arn" {
  value       = try(local.created_security_group.arn, null)
}

output "name" {
  value       = try(local.created_security_group.name, null)
}

output "rules_terraform_ids" {
  value       = values(aws_security_group_rule.keyed).*.id
}