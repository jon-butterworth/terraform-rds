
resource "random_password" "dmba-pwd" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "vault_generic_secret" "dmba-secret" {
  path = "kv/${module.this.namespace}/${module.this.tenant}-dmba"

  data_json = jsonencode({
    database = module.dmbr.db_name
    host     = module.dmbr.address
    password = random_password.dmbr-pwd.result
    username = module.dmbr.username
  })
}

module "dmba-kms" {
  source = "./modules/aws-kms"
  policy = data.aws_iam_policy_document.rds.json
}

module "dmba" {
  source = "./modules/aws-rds"

  identifier           = local.dmbr["identifier"]
  database_name        = local.dmbr["name"]
  database_user        = local.dmbr["user"]
  kms_key_arn          = module.dmba-kms.key_arn
  database_password    = random_password.dmbr-pwd.result
  database_port        = local.global["db_port"]
  multi_az             = local.global["multi_az"]
  storage_type         = local.global["storage_type"]
  allocated_storage    = local.global["allocated_storage"]
  storage_encrypted    = local.global["storage_encrypted"]
  engine               = local.global["engine"]
  engine_version       = local.global["engine_version"]
  instance_class       = local.global["instance_class"]
  db_parameter_group   = local.global["parameter_group"]
  publicly_accessible  = false
  vpc_id               = local.vpc_id
  subnet_ids           = local.global["subnet_ids"]
  security_group_ids   = [module.vpc.vpc_default_security_group_id]
  apply_immediately    = local.global["apply_immediately"]
  availability_zone    = local.global["availability_zones"]

  db_parameter = local.dmbr["parameters"]
  context = module.this.context
}

module "dmbr-sg" {
  source = "./modules/aws-security-group"

  allow_all_egress = true
  rules = [
    {
      key         = null
      type        = "ingress"
      from_port   = local.global["db_port"]
      to_port     = local.global["db_port"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] // This won't do.. we need to bring the VPC's CIDR in.
      description = "Allow ${local.global["db_port"]} for dmbr"
    },
  ]
}