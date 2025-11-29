//Waf clasico provisional

#que paises limitaremos?
resource "aws_waf_geo_match_set" "geo_test" {
  name = "geo_test"

  geo_match_constraint {
    type = "COUNTRY"
    value = "PE"
  }

  geo_match_constraint {
    type = "COUNTRY"
    value = "US"
  }
}

resource "aws_wafregional_rule" "waf_allowed" { 
  name        = "waf_allowed"
  metric_name = "AllowedRequests" 

  predicate {
    data_id = aws_waf_geo_match_set.geo_test.id
    negated = false
    type = "GeoMatch"
  }
}


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
  metric_name = "BlockedSqlI" 

  predicate {
    data_id = aws_wafregional_sql_injection_match_set.sql.id
    negated = false
    type = "SqlInjectionMatch"
  }
}

#falta predicate
resource "aws_wafregional_rule" "waf_count" {   
  name        = "waf_count"
  metric_name = "CountRequests" 
}

resource "aws_wafregional_rule_group" "waf_group" {
  name        = "waf_group"
  metric_name = "metricas"

  activated_rule {
    action {
      type = "COUNT"
    }

    priority = 50
    rule_id  = aws_wafregional_rule.waf_count.id

  }

  activated_rule {
    action {
      type = "BLOCK"
    }

    priority = 30
    rule_id = aws_wafregional_rule.waf_block_sql.id
  }  

    activated_rule {
    action {
      type = "ALLOW"
    }

    priority = 40
    rule_id = aws_wafregional_rule.waf_allowed.id
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
  web_acl_id = aws_wafregional_web_acl.waf_acl.id
}

resource "aws_wafregional_web_acl_association" "wacl2" {
  resource_arn = aws_lb.alb_us_east_2.arn
  web_acl_id = aws_wafregional_web_acl.waf_acl.id
}
