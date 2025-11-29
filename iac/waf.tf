# WAF GEO PAISES PERMITIDOS
resource "aws_waf_geo_match_set" "geo_test" {
  name = "geo_test"

  geo_match_constraint {
    type  = "Country"
    value = "PE"
  }

  geo_match_constraint {
    type  = "Country"
    value = "US"
  }
}

resource "aws_wafregional_rule" "waf_allowed" {
  name        = "waf_allowed"
  metric_name = "AllowedRequests"

  predicate {
    data_id = aws_waf_geo_match_set.geo_test.id
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
    priority = 20
    rule_id  = aws_wafregional_rule.waf_allowed.id
  }
}


resource "aws_wafregional_web_acl" "waf_acl" {
  name        = "waf_acl"
  metric_name = "wafacl"

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
