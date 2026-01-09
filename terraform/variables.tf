# ==========================================
# VARIABLES GLOBALES
# ==========================================

variable "personal_prefix" {
  description = "Préfixe personnel pour éviter les conflits entre membres de l'équipe (ex: 'alice', 'bob', 'jd')"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.personal_prefix))
    error_message = "Le personal_prefix doit contenir uniquement des lettres minuscules, chiffres et tirets."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment doit être 'dev', 'staging' ou 'prod'."
  }
}
