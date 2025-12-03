resource "aws_wafv2_web_acl" "waf_acl" {
  name  = "waf_acl"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "waf_block_sql"
    priority = 10

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          query_string {}
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "BlockedSql"
    }
  }

  rule {
    name     = "allow-country"
    priority = 5

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["PE"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "allow_country"
    }
  }
  #CKV_AWS_192: AGregar regla para proteccion LOg4j2
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "KnownBadInputs"
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "wafacl"
  }

}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  resource_arn            = aws_wafv2_web_acl.waf_acl.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_acl.arn]
}

resource "aws_wafv2_web_acl_association" "wacl1" {
  resource_arn = aws_lb.alb_us_east_1.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}

resource "aws_wafv2_web_acl_association" "wacl2" {
  resource_arn = aws_lb.alb_us_east_2.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}

module "waf_logs" {
  source      = "./modules/bucket_logs_s3"
  bucket_name = "mis-logs-waf-25"
  tags = {
    Project = "cineagile"
  }
}


resource "aws_iam_role" "firehose_role" {
  name = "firehose_waf_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ]
      Resource = [
        module.waf_logs.bucket_arn,
        "${module.waf_logs.bucket_arn}/*"
      ]

    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "waf_acl" {
  name        = "waf_logs_stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = module.waf_logs.bucket_arn

    compression_format = "GZIP"
    buffering_size     = 5
    buffering_interval = 300
  }

  server_side_encryption {
    enabled  = true #aws_241
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = aws_kms_key.firehose_kms.arn
  }
}

//parece q es necesario otro para el cloudfront
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "waf-cloudfront"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "allow-pe"
    priority = 1
    action {
      allow {}
    }
    statement {
      geo_match_statement {
        country_codes = ["PE"]
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "geo_allow"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "common_rules"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "bad_inputs"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "bot_control"
    }
  }

  rule {
    name     = "rate-limit-requests"
    priority = 5
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "rate_limit"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "cloudfront_waf"
  }
}

resource "aws_wafv2_web_acl_association" "cloudfront_assoc" {
  resource_arn = aws_cloudfront_distribution.s3_distribution.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudfront_waf.arn
}

module "waf_logs_cf" {
  source      = "./modules/bucket_logs_s3"
  bucket_name = "waf-cloudfront-cl"
  tags = {
    Project = "cineagile"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "waf_cf_logs" {
  name        = "waf_cloudfront_logs_stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role_cf.arn
    bucket_arn = module.waf_logs_cf.bucket_arn

    compression_format = "GZIP"
    buffering_size     = 5
    buffering_interval = 300
  }

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = aws_kms_key.firehose_kms.arn
  }
}


resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_waf_logs" {
  resource_arn            = aws_wafv2_web_acl.cloudfront_waf.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_cf_logs.arn]
}

resource "aws_iam_role_policy" "firehose_policy_cf" {
  role = aws_iam_role.firehose_role_cf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ]
      Resource = [
        module.waf_logs_cf.bucket_arn,
        "${module.waf_logs_cf.bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_kms_key" "firehose_kms" {
  description             = "CMK para Firehose encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
