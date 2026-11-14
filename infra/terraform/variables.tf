# ---------------------------------------------------------------------------
# Destino: AWS real o LocalStack
# ---------------------------------------------------------------------------
variable "use_localstack" {
  description = "true = apunta a LocalStack con credenciales ficticias; false = AWS real."
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "URL base de LocalStack (solo se usa si use_localstack = true)."
  type        = string
  default     = "http://localhost:4566"
}

variable "aws_region" {
  description = "Región de AWS."
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# Identidad del servicio
# ---------------------------------------------------------------------------
variable "project" {
  description = "Prefijo de proyecto usado en los nombres de recursos."
  type        = string
  default     = "blueprint"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project))
    error_message = "project: 3 a 20 caracteres, minúsculas, números y guiones; debe empezar con letra."
  }
}

variable "service_name" {
  description = "Nombre del microservicio (ej. orders)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.service_name))
    error_message = "service_name: 3 a 24 caracteres, minúsculas, números y guiones; debe empezar con letra."
  }
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment debe ser dev, stg o prod."
  }
}

variable "extra_tags" {
  description = "Etiquetas adicionales aplicadas a todos los recursos."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Mensajería (SQS + DLQ + SNS)
# ---------------------------------------------------------------------------
variable "sqs_visibility_timeout_seconds" {
  description = "Visibility timeout de la cola principal."
  type        = number
  default     = 60
}

variable "sqs_message_retention_seconds" {
  description = "Retención de mensajes de la cola principal."
  type        = number
  default     = 345600
}

variable "sqs_dlq_message_retention_seconds" {
  description = "Retención de mensajes de la DLQ."
  type        = number
  default     = 1209600
}

variable "sqs_max_receive_count" {
  description = "Intentos antes de enviar el mensaje a la DLQ."
  type        = number
  default     = 5
}

variable "sqs_kms_master_key_id" {
  description = "Clave KMS para SQS. null = SSE-SQS (cifrado administrado)."
  type        = string
  default     = null
}

variable "sns_kms_master_key_id" {
  description = "Clave KMS para SNS. Por defecto la clave administrada de AWS; usa null solo en LocalStack."
  type        = string
  default     = "alias/aws/sns"
}

variable "restrict_dlq_sources" {
  description = "true = la DLQ solo acepta redrive desde la cola principal."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Almacenamiento (S3)
# ---------------------------------------------------------------------------
variable "bucket_name_suffix" {
  description = "Sufijo opcional (hasta 12 caracteres) para unicidad global del bucket en AWS real, ej. el ID de cuenta."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9-]{0,12}$", var.bucket_name_suffix))
    error_message = "bucket_name_suffix: hasta 12 caracteres en minúsculas, números o guiones."
  }
}

variable "s3_force_destroy" {
  description = "true permite destruir el bucket con objetos (solo entornos efímeros)."
  type        = bool
  default     = false
}

variable "s3_kms_key_arn" {
  description = "ARN de clave KMS para el bucket. null = SSE-S3."
  type        = string
  default     = null
}

variable "s3_noncurrent_version_expiration_days" {
  description = "Días de retención de versiones no vigentes."
  type        = number
  default     = 90
}

# ---------------------------------------------------------------------------
# Secrets Manager
# ---------------------------------------------------------------------------
variable "secret_recovery_window_in_days" {
  description = "Ventana de recuperación del secreto (0 solo en entornos efímeros; AWS real: 7 a 30)."
  type        = number
  default     = 7
}

variable "secrets_kms_key_id" {
  description = "Clave KMS del secreto. null = aws/secretsmanager."
  type        = string
  default     = null
}

variable "create_initial_secret_version" {
  description = "true crea una versión inicial del secreto con initial_secret_values (quedan en el state)."
  type        = bool
  default     = false
}

variable "initial_secret_values" {
  description = "Valores iniciales del secreto (mapa clave/valor)."
  type        = map(string)
  default     = {}
  sensitive   = true
}
