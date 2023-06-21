module "s3_label" {
    source = "./modules/null-label"

    attributes = ["${var.env}","adept", "rds"]
    context = module.this.context
}

module "rds_s3" {
    source = "./modules/aws-s3"

    bucket_name = module.s3_label.id
    context = module.this.context
}