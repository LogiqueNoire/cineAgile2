variable "region" {
  type        = string
  description = "Region of AWS"
}

variable "region_secondary" {
  type        = string
  description = "Region of AWS"
}

variable "bucket_nombre" {
  type        = string
  description = "Region of AWS"
}

variable "dominio_nombre" {
  description = "El nombre de tu dominio principal (ej. midominio.com)."
  type        = string
}

variable "sub_dominio_www" {
  type = string
}

variable "sub_dominio_api" {
  type = string
}
