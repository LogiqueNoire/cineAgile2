output "frontend_url" {
  description = "El URL del sitio web con HTTPS."
  value       = "https://${var.domain_name}"
}

output "s3_frontend_bucket_name" {
  description = "El nombre del bucket de S3 para el CI/CD del frontend (donde se suben los archivos)."
  value       = aws_s3_bucket.frontend_bucket.id
}

output "cloudfront_distribution_id" {
  description = "El ID de la distribución de CloudFront (necesario para la invalidación de caché)."
  value       = aws_cloudfront_distribution.s3_distribution.id
}