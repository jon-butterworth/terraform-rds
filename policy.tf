
data "aws_iam_policy_document" "rds" {
    statement {
      sid    = "Enable IAM User Permissions"
      effect = "Allow"

    actions = [
        "kms:*",
    ]
    resources = [
        "*",
    ]
    principles {
        type = "AWS"
        identifiers = [
            "${local.global["build_worker_role"]}"
        ]
    }
  }
  statement {
    sid    = "Allow key use"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "${local.global["build_worker_role"]}"
      ]
    }
  }
  statement {
    sid    = "Allow Full RDS Access"
    effect = "Allow"
  }
  actions = [
    "rds:*",
  ]
  resources = [
    "arn:aws:rds:*:${local.aws_account}:db:${local.dmbo["identifier"]}"
  ]
  principles {
    type = "AWS"
    identifiers = [
      "${local.global["build_worker_role"]}"
    ]
  }
}
