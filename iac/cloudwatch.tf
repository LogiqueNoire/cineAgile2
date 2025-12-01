# Para route 53
resource "aws_cloudwatch_log_group" "route53_logs" {
  name              = "/aws/route53/cineagile"
  retention_in_days = 365                            # AWS-338(Logs por 1 año)
  kms_key_id        = aws_kms_key.cloudwatch_key.arn #AWS_158 CIfrado kms
}

resource "aws_kms_key" "cloudwatch_key" {
  description = "KMS key for CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsUse"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },

      {
        Sid    = "AllowRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::797606048152:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role" "route53_logging_role" {
  name = "route53-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "route53_logging_policy" {
  name = "route53-logging-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.route53_logs.arn}:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.route53_logging_role.name
  policy_arn = aws_iam_policy.route53_logging_policy.arn
}

resource "aws_route53_query_log" "main" {
  zone_id                  = aws_route53_zone.main.zone_id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_logs.arn

  depends_on = [
    aws_cloudwatch_log_group.route53_logs,
    aws_iam_role_policy_attachment.attach_policy
  ]
}

# Para bucket frontend_bucket
# solucionado CKV_AWS_18:Ensure the S3 bucket has access logging enabled, Configuración de logging
# --- 1. Grupo de logs en CloudWatch ---
resource "aws_cloudwatch_log_group" "frontend_access_logs" {
  name              = "/aws/s3/cineagile-front/access"
  retention_in_days = 365                            # Aws-338 (logs por 1 año)
  kms_key_id        = aws_kms_key.cloudwatch_key.arn #AWS_158 CIfrado kms
}

# --- 2. Rol para que S3 publique logs en CloudWatch ---
resource "aws_iam_role" "s3_to_cloudwatch_role" {
  name = "s3-to-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# --- 3. Permisos del rol ---
resource "aws_iam_role_policy" "s3_to_cloudwatch_policy" {
  name = "s3-to-cloudwatch-policy"
  role = aws_iam_role.s3_to_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.frontend_access_logs.arn}:*"
    }]
  })
}

# --- 4. CloudTrail para capturar los accesos S3 ---
resource "aws_cloudtrail" "s3_access_trail" {
  #checkov:skip=CKV_AWS_252:Este CloudTrail solo captura eventos S3 y no requiere SNS
  name                          = "cineagile-front-trail"
  s3_bucket_name                = aws_s3_bucket.frontend_bucket.bucket
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.frontend_access_logs.arn
  cloud_watch_logs_role_arn     = aws_iam_role.s3_to_cloudwatch_role.arn
  include_global_service_events = false
  is_multi_region_trail         = true #CKV_AWS-67 (Ensure CloudTrail is enabled in all Regions)
  enable_logging                = true
  enable_log_file_validation    = true #CKV_AWS-36 (Ensure CloudTrail log file validation is enabled)
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::cineagile-front/"]
    }
  }
}

resource "aws_route53_health_check" "mi_servicio" {
  fqdn              = var.sub_dominio_api # api.cineagile.com
  type              = "HTTPS"
  resource_path     = "/api/venta/v1/health"
  request_interval  = 30 # cada 30 segundos
  failure_threshold = 3  # si falla 3 veces, se considera down
}

resource "aws_cloudwatch_dashboard" "dashboard_cliente" {
  dashboard_name = "DashboardCliente"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", aws_route53_health_check.mi_servicio.id]
          ],
          period = 30,
          stat   = "Minimum",
          title  = "Servicio Activo (Health Check)"
        }
      }
    ]
  })
}