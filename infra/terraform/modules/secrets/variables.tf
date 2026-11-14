variable "name" {
  description = "Nombre del secreto (admite barras, ej. blueprint/dev/orders/app)."
  type        = string
}

variable "recovery_window_in_days" {
  description = "Ventana de recuperación al eliminar. 0 = borrado inmediato (solo entornos efímeros); AWS real: 7 a 30."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days debe ser 0 o estar entre 7 y 30."
  }
}

variable "kms_key_id" {
  description = "Clave KMS del secreto. null = clave administrada aws/secretsmanager."
  type        = string
  default     = null
}

variable "create_initial_version" {
  description = "true crea una versión inicial con initial_values. Los valores quedan en el state: usa un backend remoto cifrado."
  type        = bool
  default     = false
}

variable "initial_values" {
  description = "Mapa de valores iniciales (se almacena como JSON). Solo se usa si create_initial_version = true."
  type        = map(string)
  default     = {}
  sensitive   = true
}
