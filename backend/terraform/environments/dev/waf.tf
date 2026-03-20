# ============================
# WAF WebACL
# 우선순위: 0=Rate Limit → 1=Common → 2=BadInputs → 3=IpReputation
# ============================
resource "aws_wafv2_web_acl" "main" {
  name  = "youngbaby-waf-${var.stage}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate Limit: IP당 30 req/min 초과 시 차단
  rule {
    name     = "RateLimit30PerMin"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limit
        evaluation_window_sec = 60
        aggregate_key_type    = "IP"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "youngbaby-rate-${var.stage}"
    }
  }

  # OWASP Top 10 (SQLi, XSS 등)
  rule {
    name     = "CommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "youngbaby-common-${var.stage}"
    }
  }

  # Log4Shell 등 알려진 취약점
  rule {
    name     = "KnownBadInputs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "youngbaby-badinputs-${var.stage}"
    }
  }

  # 봇·악성 IP 차단
  rule {
    name     = "IpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "youngbaby-iprep-${var.stage}"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "youngbaby-waf-${var.stage}"
  }

  tags = { Name = "youngbaby-waf-${var.stage}" }
}

# API Gateway Stage와 WAF 연결
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
