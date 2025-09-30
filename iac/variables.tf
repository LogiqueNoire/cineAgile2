variable "region" {
    type = string
    description = "Region of AWS"
}

variable "domain_name" {
  description = "El nombre de tu dominio principal (ej. midominio.com)."
  type        = string
}

variable "route53_zone_id" {
  description = "El ID de la Hosted Zone de Route 53 para tu dominio."
  type        = string
}