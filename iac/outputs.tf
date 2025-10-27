output "route53_zone_id" {
  description = "ID de la zona hospedada en Route 53"
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Nombre del dominio en Route 53"
  value       = aws_route53_zone.main.name
}

output "route53_name_servers" {
  description = "Servidores de nombre asignados por AWS"
  value       = aws_route53_zone.main.name_servers
}

output "s3_frontend_bucket_name" {
  description = "El nombre del bucket de S3 para el CI/CD del frontend (donde se suben los archivos)."
  value       = aws_s3_bucket.frontend_bucket.id
}

output "cloudfront_distribution_id" {
  description = "El ID de la distribución de CloudFront (necesario para la invalidación de caché)."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_domain_name" {
  description = "Dominio público de la distribución CloudFront."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
