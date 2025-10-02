################################################################################
# WAF
################################################################################

resource "aws_wafv2_web_acl" "this" {
  # WAFs for the CDN must be deployed in the N. Virginia region
  region = "us-east-1"

  name        = "spa-client-cloudfront-waf"
  description = "WAF instance with standard rules to be used with CloudFront CDN."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "spa_client_cloudfront_waf"
  }

  # WAF Rules AWS managed
  rule {
    name     = "aws-core"
    priority = 50

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-common"
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
  }

  # Rate limiting WAF rule
  rule {
    name     = "rate-limit-all"
    priority = 100

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000 # per 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-all"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "aws-anonymous-ip"
    priority = 200

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"

        rule_action_override {
          name = "HostingProviderIPList"
          action_to_use {
            block {}
          }
        }

        rule_action_override {
          name = "AnonymousIPList"
          action_to_use {
            block {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-anonymous-ip"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-ip-reputation"
    priority = 250

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-known-bad-inputs"
    priority = 300

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-known-bad-inputs"
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
  }

  rule {
    name     = "aws-sql-injection"
    priority = 350

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-sql-injection"
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }
  }

  rule {
    name     = "aws-linux"
    priority = 400

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-linux"
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesLinuxRuleSet"
      }
    }
  }

  rule {
    name     = "aws-posix"
    priority = 450

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-posix"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_ip_set" "ip_allow_ipv4" {
  region = "us-east-1"

  name               = "ip-allow-ipv4"
  description        = "A set of allowed IPv4s addresses"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  # Add bad actor IPv4 addresses as required below.
  addresses = var.ip_allow_ipv4
}

resource "aws_wafv2_ip_set" "ip_allow_ipv6" {
  region = "us-east-1"

  name               = "ip-allow-ipv6"
  description        = "A set of allowed IPv6s addresses"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"

  # Add bad actor IPv4 addresses as required below.
  addresses = var.ip_allow_ipv6
}

################################################################################
# WAF - Logs
################################################################################

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  region = "us-east-1"

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  region = "us-east-1"

  # NOTE: WAF log group names must be prefixed with "aws-waf-logs-*"
  # https://docs.aws.amazon.com/waf/latest/developerguide/logging-cw-logs.html#logging-cw-logs-naming
  name              = "aws-waf-logs-cdn/${var.environment}/"
  retention_in_days = 30
}
