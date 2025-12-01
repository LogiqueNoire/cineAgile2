// 0. Zona route 53
resource "aws_route53_zone" "main" {
  name = var.dominio_nombre
}
# (DNSSEC) signing is enabled for Amazon Route 53 public hosted 
resource "aws_route53_hosted_zone_dnssec" "main_dnssec" {
  hosted_zone_id = aws_route53_zone.main.id
}

# Certificado SSL para CloudFront
resource "aws_acm_certificate" "cineagile_cert" {
  provider          = aws.use1
  domain_name       = var.dominio_nombre
  validation_method = "DNS"

  subject_alternative_names = [var.sub_dominio_www]

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
  name    = var.dominio_nombre
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
  name    = var.sub_dominio_www
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}

// 1. S3 Bucket para el Contenido Estático


resource "aws_s3_bucket" "frontend_bucket" {

  # checkov:skip=CKV2_AWS_62:Bucket se usa solo para el hosting est
  # checkov:skip=CKV2_AWS_18:Ensure the S3 bucket has access logging enabled se usará cloud watch
  # checkov:skip=CKV_AWS_21: Solo hay hosting estático no es necesario el versioning.
  # checkov:skip=CKV2_AWS_61: No deseo eliminar el s3 despues de cierto tiempo.
  bucket = var.bucket_nombre

}


#solucionado CKV_AWS_145 Ensure that S3 buckets are encrypted with KMS by default
/*
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
*/

#checkov CKV_AWS_18: Ensure that s3 bucket has access loggin enable
resource "aws_s3_bucket_logging" "logueo" {
  bucket = aws_s3_bucket.frontend_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

#Bucekt de los logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_nombre}-logs"
}

// Lyfeclicng bucket de los logs
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = "logs/" #
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 #CKV_AWS_300 Ensure S3 lifecycle configuration sets period for aborting failed uploads
    }

    expiration {
      days = 30
    }
  }
}
// S3 Bucket does not have public access blocks
resource "aws_s3_bucket_public_access_block" "bucket_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

#AWS S3 Object Versioning is disabled
resource "aws_s3_bucket_versioning" "versioning_block" {
  bucket = aws_s3_bucket.log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# checkov:skip=CKV2_AWS_62:  via sns(tal vez opcioonal)
#S3 buckets do not have event notifications enabled , 
/*resource "aws_sns_topic" "log_bucket_notifications" {
  name = "${var.bucket_nombre}-logs-notifications"
}

resource "aws_s3_bucket_notification" "log_bucket_notification" {
  bucket = aws_s3_bucket.log_bucket.id

  topic {
    topic_arn     = aws_sns_topic.log_bucket_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }
} */


#"Dueño" del bucket
resource "aws_s3_bucket_ownership_controls" "log_bucket_controls" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#acl logs
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_controls]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
      }
    ]
  })
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
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true #AWS-55 (S3 tenga activado ignorepublic acls)
  restrict_public_buckets = true
}

// --- 2. Origin Access Control (OAC) para CloudFront ---

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "frontend-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
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

  depends_on = [aws_cloudfront_origin_access_control.oac]
}

resource "aws_kms_key" "s3_key" {
  description = "KMS key for S3 bucket encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontUse"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::797606048152:distribution/E2DMEHPEKTRNX9"
          }
        }
      },
      {
        Sid       = "AllowRootAccountFullAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::797606048152:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

// --- 4. CloudFront Distribution (CDN) ---
# checkov:skip=CKV_AWS_310:"No necesitamos origin failover por ahora"
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  depends_on = [aws_acm_certificate_validation.cineagile_cert_validation]

  aliases = [
    var.dominio_nombre,
    var.sub_dominio_www
  ]

  # --- ORIGIN 1: S3 ---
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "s3-frontend-origin" //debe ser una cadena
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  origin {
    origin_id   = "api-origin"
    domain_name = var.sub_dominio_api
    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Comportamiento por defecto: sirve S3
  default_cache_behavior {
    target_origin_id       = "s3-frontend-origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    # solucionado CKV2_AWS_32 AWS CloudFront distribution does not have a strict security headers policy attached
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Comportamiento para API (rutas que van a ALB)  
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "all"
      }
    }
  }

  # solucionado CKV_AWS_374 Ensure AWS CloudFront web distribution has geo restriction enabled
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PE"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cineagile_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "cineagile-security-headers"
  comment = "Cabeceras CORS y seguridad para CloudFront"

  cors_config {
    access_control_allow_credentials = true

    access_control_allow_headers {
      items = ["Content-Type", "Authorization"]
    }

    access_control_allow_methods {
      items = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }

    access_control_allow_origins {
      items = ["https://cineagile.com", "https://www.cineagile.com"]
    }

    origin_override = true
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    xss_protection {
      override   = true
      protection = true
      mode_block = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }
    /*
    content_security_policy {
      content_security_policy = "default-src 'self';"
      override                = true
    }
    */
  }
}
