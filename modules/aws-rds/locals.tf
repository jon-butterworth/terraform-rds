locals {
  computed_major_engine_versions = var.engine == "postgres" ? join(".", slice(split(".", var.engine_version), 0, 1)) : join(".", slice(".", var.engine_version), 0, 2)
  major_engine_version           = var.major_engine_version == "" ? local.computed_major_engine_versions : var.major_engine_version

  subnet_ids_provided            = var.subnet_ids != null && length(var.subnet_ids) > 0
  db_subnet_group_name_provided  = var.db_subnet_group_name != null && var.db_subnet_group_name != ""
  is_replica                     = try(length(var.replicate_source_db), 0) > 0

  db_subnet_group_name = local.db_subnet_group_name_provided ? var.db_subnet_group_name : (
    local.is_replica ? null : (
        local.subnet_ids_provided ? join("", aws_db_subnet_group.default.*.name) : null)
  )

  availability_zones = var.multi_az ? null : var.availability_zone
}
