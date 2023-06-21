locals {
  enabled = module.this.enabled
  inline  = var.inline_rules_enabled

  allow_all_egress = local.enabled && var.allowed_all_egress

  create_security_group = local.enabled && length(var.target_security_group_id) == 0
  sg_create_before_destroy = var.create_before_destroy
  preserve_security_group_id = var.preserve_security_group_id || length(var.target_security_group_id) > 0


  created_security_group = local.create_security_group ? (
    local.sg_create_before_destroy ? aws_security_group.cbd[0] : aws_security_group.default[0]
  ) : null
  
  target_security_group_id = try(var.target_security_group_id[0], "")

  security_group_id = local.enabled ? (
    local.create_security_group ? local.created_security_group : coalesce(local.target_security_group_id, "target_security_group empty")
  ) : null

  rule_create_before_destroy = local.sg_create_before_destroy && !local.preserve_security_group_id
  cbd_security_group_id      = local.create_security_group ? one(aws_security_group.cbd[*].id) : local.target_security_group_id

  rule_change_forces_new_security_group = local.enabled && local.rule_create_before_destroy
  }

resource "random_id" "rule_change_forces_new_security_group" {
  count       = local.rule_change_forces_new_security_group ? 1 : 0
  byte_length = 3
  keepers     = {
    rules     = jsonencode(local.keyed_resource_rules)
  }
}

resource "aws_security_group" "default" {
  count = local.create_security_group && local.create_before_destroy == false ? 1 : 0
  name  = concat(var.security_group_name, [module.this.id])[0]
  lifecycle {
    create_before_destroy = true
  }
  description = var.security_group_description
  vpc_id = var.vpc_id
  tags = merge(module.this.tags, try(length(var.security_group_name[0]), 0) > 0 ? {Name = var.security_group_name[0]} : {})

  revoke_rules_on_delete = var.revoke_rules_on_delete

  dynamic "ingress" {
    for_each = local.all_ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      description      = ingress.value.description
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self

    }
  }

  dynamic "egress" {
    for_each = local.all_egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      description      = egress.value.description
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }
 
  timeouts {
    create = var.security_group_create_timeout
    delete = var.security_group_delete_timeout
  }
}

locals {
  sg_name_prefix_base   = concat(var.security_group_name, ["${module.this.id}${module.this.delimiter}"])[0]
  sg_name_prefix_forced = "${local.sg_name_prefix_base}${module.this.delimiter}${join("", random_id.rule_change_forces_new_security_group[*].b64_url)}${module.this.delimiter}"
  sg_name_prefix        = local.rule_change_forces_new_security_group ? local.sg_name_prefix_forced : local.sg_name_prefix_base
}

resource "aws_security_group" "cbd" {
  count = local.create_security_group && local.sg_create_before_destroy == true ? 1 : 0

  name_prefix = local.sg_name_prefix
  lifecycle {
    create_before_destroy = true
  }

  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, try(length(var.security_group_name[0]), 0) > 0 ? { Name = var.security_group_name[0] } : {})

  revoke_rules_on_delete = var.revoke_rules_on_delete

  dynamic "ingress" {
    for_each = local.all_ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      description      = ingress.value.description
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = local.all_egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      description      = egress.value.description
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }

  timeouts {
    create = var.security_group_create_timeout
    delete = var.security_group_delete_timeout
  }
}
resource "aws_security_group_rule" "keyed" {
  for_each = local.rule_create_before_destroy ? local.keyed_resource_rules : {}

  lifecycle {
    create_before_destroy = true
  }
  security_group_id = local.cbd_security_group_id

  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) == 0 ? null : each.value.cidr_blocks
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) == 0 ? null : each.value.ipv6_cidr_blocks
  prefix_list_ids          = length(each.value.prefix_list_ids) == 0 ? [] : each.value.prefix_list_ids
  self                     = each.value.self
  source_security_group_id = each.value.source_security_group_id
}

resource "aws_security_group_rule" "dbc" {
  for_each = local.rule_create_before_destroy ? {} : local.keyed_resource_rules

  lifecycle {
    create_before_destroy = false
  }

  security_group_id = local.security_group_id

  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) == 0 ? null : each.value.cidr_blocks
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) == 0 ? null : each.value.ipv6_cidr_blocks
  prefix_list_ids          = length(each.value.prefix_list_ids) == 0 ? [] : each.value.prefix_list_ids
  self                     = each.value.self
  source_security_group_id = each.value.source_security_group_id

}

resource "null_resource" "sync_rules_and_sg_lifecycles" {
  count = local.enabled && local.rule_create_before_destroy ? 1 : 0
  triggers = {
    sg_ids = one(aws_security_group.cbd[*].id)
  }

  depends_on = [aws_security_group_rule.keyed]

  lifecycle {
    create_before_destroy = true
  }
}