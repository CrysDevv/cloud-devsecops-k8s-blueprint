variable "bucket_name" {
  description = "Nombre del bucket (único globalmente en AWS real)."
  type        = string
}

variable "force_destroy" {
  description = "true permite destruir el bucket aunque tenga objetos (solo para entornos efímeros)."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN de clave KMS para SSE-KMS. null = SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Días tras los cuales expiran las versiones no vigentes de los objetos."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days debe ser >= 1."
  }
}
