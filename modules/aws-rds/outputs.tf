output "instance_id" {
  value       = join("", aws_db_instance.default.*.id)
}

output "instance_arn" {
  value       = join("", aws_db_instance.default.*.arn)
}

output "instance_address" {
  value       = join("", aws_db_instance.default.*.address)
}

output "instance_endpoint" {
  value       = join("", aws_db_instance.default.*.endpoint)
}

output "subnet_group_id" {
  value       = join("", aws_db_subnet_group.default.*.id)
}

output "security_group_id" {
  value       = join("", aws_security_group.default.*.id)
}

output "parameter_group_id" {
  value       = join("", aws_db_parameter_group.default.*.id)
}

output "option_group_id" {
  value       = join("", aws_db_option_group.default.*.id)
}

output "hostname" {
  value       = module.dns_host_name.hostname
}

output "resource_id" {
  value       = join("", aws_db_instance.default.*.resource_id)
}

output "db_name" {
  value       = join("", aws_db_instance.default.db_name)
}

output "address" {
  value       = join("", aws_db_instance.default.address)
}

output "username" {
  value       = join("", aws_db_instance.default.username)
}