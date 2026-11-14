variable "name" {
  description = "Prefijo de nombre de los recursos (ej. blueprint-orders-dev)."
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "Tiempo de invisibilidad de un mensaje tomado de la cola (debe ser mayor al tiempo máximo de procesamiento)."
  type        = number
  default     = 60

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds debe estar entre 0 y 43200."
  }
}

variable "message_retention_seconds" {
  description = "Retención de mensajes en la cola principal."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds debe estar entre 60 y 1209600."
  }
}

variable "dlq_message_retention_seconds" {
  description = "Retención de mensajes en la DLQ (por defecto el máximo: 14 días)."
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "dlq_message_retention_seconds debe estar entre 60 y 1209600."
  }
}

variable "max_receive_count" {
  description = "Intentos de recepción antes de mover el mensaje a la DLQ."
  type        = number
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count debe estar entre 1 y 1000."
  }
}

variable "sqs_kms_master_key_id" {
  description = "Clave KMS para SQS. null = cifrado administrado por SQS (SSE-SQS)."
  type        = string
  default     = null
}

variable "sns_kms_master_key_id" {
  description = "Clave KMS para el tópico SNS. null = sin cifrado en reposo (solo para LocalStack)."
  type        = string
  default     = "alias/aws/sns"
}

variable "restrict_dlq_sources" {
  description = "true = la DLQ solo acepta redrive desde la cola principal (RedriveAllowPolicy)."
  type        = bool
  default     = true
}
