terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Credenciales ficticias SOLO si se apunta a LocalStack.
  # En AWS real (use_localstack = false) se usa la cadena estándar de credenciales
  # (variables de entorno, perfil, SSO o rol).
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []

    content {
      s3             = endpoints.value
      sqs            = endpoints.value
      sns            = endpoints.value
      secretsmanager = endpoints.value
      sts            = endpoints.value
    }
  }

  default_tags {
    tags = local.common_tags
  }
}
