################################################################################
# Route53
################################################################################

data "aws_route53_zone" "this" {
  name = var.registered_domain
}

resource "aws_route53_record" "client_ip4" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.registered_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "client_ip6" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.registered_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
