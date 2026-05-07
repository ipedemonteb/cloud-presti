variable "project_name" {
  description = "Nombre del proyecto para usar como prefijo en los recursos"
  type        = string
  default     = "cloud-presti"
}

variable "frontend_callback_url" {
  description = "URL temporal de callback para el entorno de desarrollo"
  type        = string
  default     = "http://localhost:5173/"
}
