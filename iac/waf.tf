# WAF GEO 
resource "aws_waf_geo_match_set" "geo_allow" {
  name = "geo_allow"
# WAF GEO 
resource "aws_waf_geo_match_set" "geo_allow" {
  name = "geo_allow"

  geo_match_constraint {
    type  = "Country"
    value = "PE"
  }
}

resource "aws_wafregional_rule" "waf_allow_country" {
  name        = "waf_allow_country"
  metric_name = "allow_country"
resource "aws_wafregional_rule" "waf_allow_country" {
  name        = "waf_allow_country"
  metric_name = "allow_country"

  predicate {
    data_id = aws_waf_geo_match_set.geo_allow.id
    data_id = aws_waf_geo_match_set.geo_allow.id
    negated = false
    type    = "GeoMatch"
  }
}

#SQL Injection
resource "aws_wafregional_sql_injection_match_set" "sql" {
  name = "sql_injection"

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }
}

resource "aws_wafregional_rule" "waf_block_sql" {
  name        = "waf_block_sql"
  metric_name = "BlockedSql"

  predicate {
    data_id = aws_wafregional_sql_injection_match_set.sql.id
    negated = false
    type    = "SqlInjectionMatch"
  }
}

resource "aws_wafregional_rule_group" "waf_group" {
  name        = "waf_group"
  metric_name = "metricas"

  activated_rule {
    action {
      type = "BLOCK"
    }
    priority = 10
    rule_id  = aws_wafregional_rule.waf_block_sql.id
  }

  activated_rule {
    action {
      type = "ALLOW"
    }
    priority = 5
    rule_id  = aws_wafregional_rule.waf_allow_country.id
    priority = 5
    rule_id  = aws_wafregional_rule.waf_allow_country.id
  }
}


resource "aws_wafregional_web_acl" "waf_acl" {
  name        = "waf_acl"
  metric_name = "wafacl"

  logging_configuration {
    log_destination = aws_kinesis_firehose_delivery_stream.waf_acl.arn
  }

  logging_configuration {
    log_destination = aws_kinesis_firehose_delivery_stream.waf_acl.arn
  }

  default_action {
    type = "BLOCK"
  }

  rule {
    priority = 1
    rule_id  = aws_wafregional_rule_group.waf_group.id
    type     = "GROUP"

    override_action {
      type = "NONE"
    }
  }
}


resource "aws_wafregional_web_acl_association" "wacl1" {
  resource_arn = aws_lb.alb_us_east_1.arn
  web_acl_id   = aws_wafregional_web_acl.waf_acl.id
}

resource "aws_wafregional_web_acl_association" "wacl2" {
  resource_arn = aws_lb.alb_us_east_2.arn
  web_acl_id   = aws_wafregional_web_acl.waf_acl.id
}


resource "aws_s3_bucket" "waf_logs" {
  bucket = "${var.bucket_nombre}-waf-logs"
  force_destroy = true
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_waf_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action = "sts:AssumeRole"
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
        aws_s3_bucket.waf_logs.arn,
        "${aws_s3_bucket.waf_logs.arn}/*"
      ]
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "waf_acl" {
  name        = "waf_logs_stream"
  destination = "extended_s3"

#checkov:skip=CKV_AWS_241: NO valido para esta version ahora se usa extend_s3
 extended_s3_configuration {
  role_arn           = aws_iam_role.firehose_role.arn
  bucket_arn         = aws_s3_bucket.waf_logs.arn
  compression_format = "GZIP"
  buffering_size = 5
  buffering_interval = 300
 } 
}


