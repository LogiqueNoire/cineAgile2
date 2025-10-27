// 0. Zona route 53
resource "aws_route53_zone" "main" {
  name = "cineagile.com"
}

# Certificado SSL para CloudFront
resource "aws_acm_certificate" "cineagile_cert" {
  provider          = aws.use1
  domain_name       = "cineagile.com"
  validation_method = "DNS"

  subject_alternative_names = ["www.cineagile.com"]

  lifecycle {
    create_before_destroy = true
  }
}

# Validación DNS automática usando Route 53
resource "aws_route53_record" "cineagile_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cineagile_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cineagile_cert_validation" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cineagile_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cineagile_cert_validation : record.fqdn]

  depends_on = [aws_route53_record.cineagile_cert_validation]
}


# Ruta raiz
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cineagile.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}

# Subdominio
resource "aws_route53_record" "www_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.cineagile.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}

// 1. S3 Bucket para el Contenido Estático

#checkov:skip=CKV2_AWS_62:Bucket se usa solo para el hosting est
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "cineagile-front"

}

# solucionado CKV_AWS_18:Ensure the S3 bucket has access logging enabled, Configuración de logging
resource "aws_s3_bucket" "frontend_logs" {
  bucket = "cineagile-front-logs"
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.frontend_bucket.id
  target_bucket = aws_s3_bucket.frontend_logs.id
  target_prefix = "log/"
}


#solucionado CKV_AWS_145 Ensure that S3 buckets are encrypted with KMS by default
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

// Bloquea el acceso público (se accederá con OAC)
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

// --- 2. Origin Access Control (OAC) para CloudFront ---

resource "aws_cloudfront_origin_access_control" "oac" {
  name                               = "frontend-oac"
  description                        = "OAC for S3 bucket"
  origin_access_control_origin_type  = "s3"
  signing_behavior                   = "always"
  signing_protocol                  = "sigv4"
}

// --- 3. Política para acceso seguro a S3 desde CloudFront ---

data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.s3_access_policy.json
}

// --- 4. CloudFront Distribution (CDN) ---

# checkov:skip=CKV2_AWS_42:No se está usando un dominio
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  depends_on = [aws_acm_certificate_validation.cineagile_cert_validation]

  aliases = [
    "cineagile.com",
    "www.cineagile.com"
  ]

  # --- ORIGIN 1: S3 ---
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.frontend_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Comportamiento por defecto: sirve S3
  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.frontend_bucket.id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Comportamiento para API (rutas que van a ALB)
  # ordered_cache_behavior {
  #   path_pattern           = "/api/*"
  #   target_origin_id       = "alb-backend"
  #   viewer_protocol_policy = "redirect-to-https"
  #   allowed_methods        = ["GET", "HEAD", "POST", "PUT", "DELETE"]
  #   cached_methods         = ["GET", "HEAD"]

  #   forwarded_values {
  #     query_string = true
  #     cookies {
  #       forward = "all"
  #     }
  #   }
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cineagile_cert.arn
    ssl_support_method        = "sni-only"
    minimum_protocol_version  = "TLSv1.2_2021"
  }

}

# #Health checks
# resource "aws_route53_health_check" "alb_east_1" {
#   fqdn              = aws_lb.alb_east_1.dns_name
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/health"
#   failure_threshold = 3
#   request_interval  = 30
# }

# resource "aws_route53_health_check" "alb_east_2" {
#   fqdn              = aws_lb.alb_east_2.dns_name
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/health"
#   failure_threshold = 3
#   request_interval  = 30
# }
