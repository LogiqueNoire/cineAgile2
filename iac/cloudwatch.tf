# Para route 53
resource "aws_cloudwatch_log_group" "route53_logs" {
  name              = "/aws/route53/cineagile"
  retention_in_days = 30
}

resource "aws_iam_role" "route53_logging_role" {
  name = "route53-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "route53_logging_policy" {
  name   = "route53-logging-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = [
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
  retention_in_days = 90
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
  name                          = "cineagile-front-trail"
  s3_bucket_name                = aws_s3_bucket.frontend_bucket.bucket
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.frontend_access_logs.arn
  cloud_watch_logs_role_arn     = aws_iam_role.s3_to_cloudwatch_role.arn
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::cineagile-front/"]
    }
  }
}