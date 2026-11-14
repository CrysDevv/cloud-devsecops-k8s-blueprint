output "secret_arn" {
  description = "ARN del secreto."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Nombre del secreto."
  value       = aws_secretsmanager_secret.this.name
}
