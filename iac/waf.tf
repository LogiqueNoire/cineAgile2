//Falta definir los predicate en las métricas
resource "aws_wafregional_rule" "waf_allowed" { //permitir solo trafico por hacer
  name        = "waf_allowed"
  metric_name = "AllowedRequests" 
}

resource "aws_wafregional_rule" "waf_blocked" { //sql injection por hacer
  name        = "waf_blocked"
  metric_name = "BlockedRequests" 
}

resource "aws_wafregional_rule" "waf_count" {   // Contar tráfico con un header sospechoso por hacer
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
    rule_id = aws_wafregional_rule.waf_blocked.id
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
  metric_name = "example"

  default_action {
    type = "ALLOW"
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

//Falta crear el web acl
resource "aws_wafregional_web_acl_association" "foo" {
  resource_arn = aws_lb.lb_good_1.arn
  web_acl_id = aws_wafregional_web_acl.foo.id
}
