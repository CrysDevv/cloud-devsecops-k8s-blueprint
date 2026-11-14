locals {
  name        = "${var.project}-${var.service_name}-${var.environment}"
  bucket_name = var.bucket_name_suffix == "" ? local.name : "${local.name}-${var.bucket_name_suffix}"
  secret_name = "${var.project}/${var.environment}/${var.service_name}/app"

  common_tags = merge(var.extra_tags, {
    Project     = var.project
    Service     = var.service_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Blueprint   = "cloud-devsecops-k8s-blueprint"
  })
}

module "messaging" {
  source = "./modules/messaging"

  name                          = local.name
  visibility_timeout_seconds    = var.sqs_visibility_timeout_seconds
  message_retention_seconds     = var.sqs_message_retention_seconds
  dlq_message_retention_seconds = var.sqs_dlq_message_retention_seconds
  max_receive_count             = var.sqs_max_receive_count
  sqs_kms_master_key_id         = var.sqs_kms_master_key_id
  sns_kms_master_key_id         = var.sns_kms_master_key_id
  restrict_dlq_sources          = var.restrict_dlq_sources
}

module "storage" {
  source = "./modules/storage"

  bucket_name                        = local.bucket_name
  force_destroy                      = var.s3_force_destroy
  kms_key_arn                        = var.s3_kms_key_arn
  noncurrent_version_expiration_days = var.s3_noncurrent_version_expiration_days
}

module "secrets" {
  source = "./modules/secrets"

  name                    = local.secret_name
  recovery_window_in_days = var.secret_recovery_window_in_days
  kms_key_id              = var.secrets_kms_key_id
  create_initial_version  = var.create_initial_secret_version
  initial_values          = var.initial_secret_values
}

# Política IAM de mínimo privilegio para el servicio (cálculo local, sin llamadas a la API).
# En EKS se asocia a un rol IRSA; el ARN del rol va en serviceAccount.annotations del chart.
data "aws_iam_policy_document" "service_access" {
  statement {
    sid = "ConsumeAndSendQueue"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
    ]
    resources = [module.messaging.queue_arn]
  }

  statement {
    sid       = "PublishTopic"
    actions   = ["sns:Publish"]
    resources = [module.messaging.topic_arn]
  }

  statement {
    sid       = "ObjectAccess"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.storage.bucket_arn}/*"]
  }

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.storage.bucket_arn]
  }

  statement {
    sid       = "ReadSecret"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [module.secrets.secret_arn]
  }
}
