output "queue_url" {
  description = "URL de la cola principal."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN de la cola principal."
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN de la dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "topic_arn" {
  description = "ARN del tópico SNS."
  value       = aws_sns_topic.main.arn
}
