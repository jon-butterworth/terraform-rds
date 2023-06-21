locals {
  rules = merge({ _list_ = var.rules }, var.rules_map)

  norm_rules = local.enabled && local.rules != null ? concat(concat([[]], [for k, rules in local.rules : [for i, rule in rules : {
    key         = coalesce(lookup(rule, "key", null), "${k}[${i}]")
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = lookup(rule, "description", local.default_rule_description)

    cidr_blocks      = try(length(rule.cidr_blocks), 0) > 0 ? rule.cidr_blocks : []
    ipv6_cidr_blocks = try(length(rule.ipv6_cidr_blocks), 0) > 0 ? rule.ipv6_cidr_blocks : []
    prefix_list_ids  = try(length(rule.prefix_list_ids), 0) > 0 ? rule.prefix_list_ids : []

    source_security_group_id = lookup(rule, "source_security_group_id", null)
    security_groups          = []

    self = lookup(rule, "self", null) == true ? true : null
  }]])...) : []

  norm_matrix = local.enabled && var.rule_matrix != null ? concat(concat([[]], [for i, subject in var.rule_matrix : [for j, rule in subject.rules : {
    key         = "${coalesce(lookup(subject, "key", null), "_m[${i}]")}#${coalesce(lookup(rule, "key", null), "[${j}]")}"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = lookup(rule, "description", local.default_rule_description)

    cidr_blocks      = lookup(subject, "cidr_blocks", [])
    ipv6_cidr_blocks = lookup(subject, "ipv6_cidr_blocks", [])
    prefix_list_ids  = lookup(subject, "prefix_list_ids", [])

    source_security_group_id = null
    security_groups          = lookup(subject, "source_security_group_ids", [])

    self = lookup(rule, "self", null) == true ? true : null
  }]])...) : []

  allow_egress_rule = {
    key                      = "_allow_all_egress_"
    type                     = "egress"
    from_port                = 0
    to_port                  = 0 
    protocol                 = "-1"
    description              = "Allow all egress"
    cidr_blocks              = ["0.0.0.0/0"]
    ipv6_cidr_blocks         = ["::/0"]
    prefix_list_ids          = []
    self                     = null
    security_groups          = []
    source_security_group_id = null
  }

  extra_rules = local.allow_all_egress ? [local.allow_egress_rule] : []

  all_inline_rules = concat(local.norm_rules, local.norm_matrix, local.extra_rules)

  all_ingress_rules = local.inline ? [for r in local.all_inline_rules : r if r.type == "ingress"] : []
  all_egress_rules  = local.inline ? [for r in local.all_inline_rules : r if r.type == "egress"] : []

  self_rules = local.inline ? [] : [for rule in local.norm_matrix : {
    key         = "${rule.key}#self"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = true

    security_groups          = []
    source_security_group_id = null

  } if rule.self == true]

  other_rules = local.inline ? [] : [for rule in local.norm_matrix : {
    key         = "${rule.key}#cidr"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = rule.cidr_blocks
    ipv6_cidr_blocks = rule.ipv6_cidr_blocks
    prefix_list_ids  = rule.prefix_list_ids
    self             = null

    security_groups          = []
    source_security_group_id = null
  } if length(rule.cidr_blocks) + length(rule.ipv6_cidr_blocks) + length(rule.prefix_list_ids) > 0]

  sg_rules_lists = local.inline ? [] : [for rule in local.all_inline_rules : {
    key         = "${rule.key}#sg"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = null
    security_groups  = rule.security_groups
  } if length(rule.security_groups) > 0]

  sg_exploded_rules = flatten([for rule in local.sg_rules_lists : [for i, sg in rule.security_groups : {
    key         = "${rule.key}#${i}"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = null

    security_groups          = []
    source_security_group_id = sg
  }]])

  all_resource_rules   = concat(local.norm_rules, local.self_rules, local.sg_exploded_rules, local.other_rules, local.extra_rules)
  keyed_resource_rules = { for r in local.all_resource_rules : r.key => r }
}