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

resource "aws_s3_bucket" "waf_logs_s3" {
  bucket        = "waf-logs-s3-agiles-25"
  force_destroy = true
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
        aws_s3_bucket.waf_logs_s3.arn,
        "${aws_s3_bucket.waf_logs_s3.arn}/*"
      ]
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "waf_acl" {
  name        = "waf_logs_stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.waf_logs_s3.arn
    compression_format = "GZIP"
    buffering_size     = 5
    buffering_interval = 300
  }
}
