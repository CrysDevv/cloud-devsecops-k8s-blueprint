terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = "Secretos de aplicación ${var.name}"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "initial" {
  count = var.create_initial_version ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.initial_values)

  lifecycle {
    # La rotación posterior se hace fuera de Terraform.
    ignore_changes = [secret_string]

    precondition {
      condition     = length(var.initial_values) > 0
      error_message = "create_initial_version = true requiere initial_values no vacío."
    }
  }
}
