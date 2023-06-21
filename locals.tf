locals {
    config = merge([
      for file in fileset(path.cwd, "config/*.yaml") : {
          for k, v in yamldecode(file(file)) : k => v
      }
    ]...)
    environment = local.config["cloud"]["environment"]
    dmbo        = local.config["dmbo"]
    global      = local.config["global"]

    aws_account = local.environment["${var.env}"]["aws_account"]
    vpc_id      = local.environment["${var.env}"]["vpc_id"]

} 