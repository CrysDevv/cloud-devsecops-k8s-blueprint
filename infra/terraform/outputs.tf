output "queue_url" {
  description = "URL de la cola SQS principal."
  value       = module.messaging.queue_url
}

output "queue_arn" {
  description = "ARN de la cola SQS principal."
  value       = module.messaging.queue_arn
}

output "dlq_url" {
  description = "URL de la dead-letter queue."
  value       = module.messaging.dlq_url
}

output "dlq_arn" {
  description = "ARN de la dead-letter queue."
  value       = module.messaging.dlq_arn
}

output "topic_arn" {
  description = "ARN del tópico SNS."
  value       = module.messaging.topic_arn
}

output "bucket_name" {
  description = "Nombre del bucket S3."
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  description = "ARN del bucket S3."
  value       = module.storage.bucket_arn
}

output "secret_arn" {
  description = "ARN del secreto en Secrets Manager."
  value       = module.secrets.secret_arn
}

output "secret_name" {
  description = "Nombre del secreto en Secrets Manager."
  value       = module.secrets.secret_name
}

output "service_iam_policy_json" {
  description = "Política IAM de mínimo privilegio para el servicio (adjuntar al rol IRSA)."
  value       = data.aws_iam_policy_document.service_access.json
}

output "app_environment" {
  description = "Variables de entorno listas para el chart de Helm (values: env)."
  value = {
    AWS_REGION    = var.aws_region
    SQS_QUEUE_URL = module.messaging.queue_url
    SQS_DLQ_URL   = module.messaging.dlq_url
    SNS_TOPIC_ARN = module.messaging.topic_arn
    S3_BUCKET     = module.storage.bucket_name
    SECRET_ID     = module.secrets.secret_name
  }
}
